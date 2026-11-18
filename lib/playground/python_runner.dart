import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// What a Python program did.
class PythonResult {
  const PythonResult({
    required this.stdout,
    required this.elapsed,
    this.error,
    this.timedOut = false,
    this.runTime = Duration.zero,
  });

  /// Everything the program printed (questions from input() and the typed
  /// answers included, like a terminal shows them).
  final String stdout;

  /// The last line of the error, e.g.
  /// `ValueError: invalid literal for int() with base 10: 'abc'`.
  /// Null when the program finished without an error.
  final String? error;

  /// True when the program ran too long (e.g. `while True:`) and was
  /// stopped.
  final bool timedOut;

  /// Time for the whole call, including starting Python the first time.
  final Duration elapsed;

  /// Time the program itself ran.
  final Duration runTime;

  bool get ok => error == null && !timedOut;
}

/// Runs Python code. The CODING playground and the MINIGAME checker both
/// use this, so either can be tested with a fake engine.
abstract interface class PythonEngine {
  Future<PythonResult> run(
    String code, {
    List<String> inputs,
    Duration timeout,
  });
}

/// Runs [code] with real Python (fully offline) and returns what it printed,
/// the last line of any error, and whether it was stopped for running longer
/// than [timeout]. input() reads [inputs] one by one; no keyboard needed.
/// Files and the network are turned off.
Future<PythonResult> runPython(
  String code, {
  List<String> inputs = const [],
  Duration timeout = const Duration(seconds: 3),
}) => PyodideEngine.instance.run(code, inputs: inputs, timeout: timeout);

/// Real Python (CPython 3.14 compiled to WebAssembly by Pyodide), running in
/// a hidden WebView inside a Web Worker. Android only for now.
///
/// The files are served straight from the APK at a special https address
/// (Android's WebViewAssetLoader), so there is no server, no socket and no
/// internet permission. A program that runs too long is stopped by killing
/// the worker; the next run gets a fresh Python.
class PyodideEngine implements PythonEngine {
  PyodideEngine._();

  static final instance = PyodideEngine._();

  static const _host = 'appassets.androidplatform.net';
  static const _page =
      'https://$_host/assets/flutter_assets/assets/pyodide/runner.html';

  /// Most characters of output kept per run.
  static const maxOutput = 20000;

  /// How long to wait for Python to start before giving up.
  static const startLimit = Duration(seconds: 90);

  HeadlessInAppWebView? _webView;
  InAppWebViewController? _controller;
  Completer<void>? _pageLoaded;
  final _pending = <String, Completer<PythonResult>>{};
  var _nextId = 0;

  /// How long Python took to start the first time (null until started).
  Duration? lastLoadTime;

  /// Starts Python now (optional), so the first run is faster.
  Future<void> warmUp() => _start();

  Future<void> _start() {
    final existing = _pageLoaded;
    if (existing != null) return existing.future;
    final loaded = _pageLoaded = Completer<void>();
    _webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(_page)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowFileAccess: false,
        allowContentAccess: false,
        // No network at all. This must be true: the release app has no
        // internet permission, and asking Android to allow network loads
        // without it throws a SecurityException.
        blockNetworkLoads: true,
        webViewAssetLoader: WebViewAssetLoader(
          domain: _host,
          pathHandlers: [AssetsPathHandler(path: '/assets/')],
        ),
      ),
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'pyResult',
          callback: (args) => _onMessage(args.first as String),
        );
      },
      onLoadStop: (controller, url) {
        if (!loaded.isCompleted) loaded.complete();
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame ?? false) {
          if (!loaded.isCompleted) {
            loaded.completeError('page did not load: ${error.description}');
          }
        }
      },
      onConsoleMessage: (controller, message) {
        debugPrint('[python] ${message.message}');
      },
    );
    // If the WebView cannot start, report it now (don't wait for the
    // start limit), and allow a later run to try again.
    _webView!.run().catchError((Object e) {
      if (!loaded.isCompleted) loaded.completeError(e);
      _pageLoaded = null;
      _webView = null;
    });
    return loaded.future;
  }

  void _onMessage(String json) {
    final m = jsonDecode(json) as Map<String, dynamic>;
    if (m['type'] == 'status') {
      lastLoadTime = Duration(milliseconds: (m['loadMs'] as num).toInt());
      return;
    }
    final done = _pending.remove(m['id'] as String);
    done?.complete(
      PythonResult(
        stdout: m['stdout'] as String? ?? '',
        error: m['error'] as String?,
        timedOut: m['timedOut'] as bool? ?? false,
        runTime: Duration(milliseconds: (m['runMs'] as num? ?? 0).toInt()),
        elapsed: Duration.zero, // filled in by run()
      ),
    );
  }

  @override
  Future<PythonResult> run(
    String code, {
    List<String> inputs = const [],
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final watch = Stopwatch()..start();
    PythonResult failed(String error) =>
        PythonResult(stdout: '', error: error, elapsed: watch.elapsed);
    try {
      await _start().timeout(startLimit);
    } catch (e) {
      return failed('PythonStartError: $e');
    }
    final id = '${_nextId++}';
    final done = _pending[id] = Completer<PythonResult>();
    final call =
        'pycogRun(${jsonEncode(id)}, ${jsonEncode(code)}, '
        '${jsonEncode(inputs)}, ${timeout.inMilliseconds}, $maxOutput)';
    await _controller!.evaluateJavascript(source: call);
    // Python may still be starting; never wait forever.
    final result = await done.future.timeout(
      startLimit + timeout + const Duration(seconds: 5),
      onTimeout: () {
        _pending.remove(id);
        return failed('PythonStartError: no answer from Python');
      },
    );
    return PythonResult(
      stdout: result.stdout,
      error: result.error,
      timedOut: result.timedOut,
      runTime: result.runTime,
      elapsed: watch.elapsed,
    );
  }

  /// Closes the hidden WebView (Python starts again on the next run).
  Future<void> dispose() async {
    await _webView?.dispose();
    _webView = null;
    _controller = null;
    _pageLoaded = null;
  }
}
