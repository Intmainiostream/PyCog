// PyCog Python worker: runs one Python program at a time with Pyodide.
//
// It lives in a Web Worker so the page (runner.js) can kill it with
// terminate() when a program runs too long (an infinite loop), and start a
// fresh one. Everything is offline: Pyodide's files come from the app.

import { loadPyodide } from './pyodide.mjs';

// Python side of the sandbox. Loaded once; _pycog_run() is called per run.
const SANDBOX_PY = String.raw`
import builtins, json, sys, time, traceback

# Modules a student's program may not import (files, network, system,
# and the ways out of the sandbox). Stdlib modules can still use them.
_BLOCKED = {
    'js', 'pyodide', 'pyodide_js', '_pyodide', 'micropip', 'ctypes',
    '_ctypes', 'socket', '_socket', 'ssl', '_ssl', 'urllib', 'http',
    'ftplib', 'smtplib', 'subprocess', 'multiprocessing', 'webbrowser',
    'os', 'posix', 'nt', 'sys', 'io', '_io', 'pathlib', 'shutil',
    'tempfile', 'glob', 'gc', 'importlib', 'builtins', 'inspect', 'pickle',
    'marshal', 'code', 'codeop', 'runpy', 'zipimport', 'sqlite3',
}
_real_import = builtins.__import__
_active = [False]


def _guarded_import(name, globals=None, locals=None, fromlist=(), level=0):
    root = name.split('.')[0]
    if root in _BLOCKED or root.startswith('_pycog'):
        raise ImportError(f"The module '{root}' is turned off in PyCog")
    return _real_import(name, globals, locals, fromlist, level)


def _no_files(*args, **kwargs):
    raise PermissionError('Files are turned off in PyCog')


# Second layer: Python's audit hooks (they cannot be removed). While a
# student's program runs, block file and system actions, except Python
# reading its own standard library under /lib/.
_SYSTEM_EVENTS = (
    'os.', 'shutil.', 'socket.', 'subprocess.', 'ctypes.', 'urllib.',
    'http.', 'webbrowser.', 'tempfile.', 'glob.', 'ftplib.', 'smtplib.',
    'pathlib.', 'sqlite3.',
)


def _audit(event, args):
    if not _active[0]:
        return
    if event == 'open':
        path = args[0] if args else None
        mode = args[1] if len(args) > 1 else 'r'
        reading = mode is None or not any(c in str(mode) for c in 'wax+')
        if isinstance(path, str) and path.startswith('/lib/') and reading:
            return
        raise PermissionError('Files are turned off in PyCog')
    if event in ('os.listdir', 'os.scandir'):
        path = args[0] if args else ''
        if isinstance(path, str) and path.startswith('/lib/'):
            return
        raise PermissionError('Files are turned off in PyCog')
    if event.startswith(_SYSTEM_EVENTS):
        raise PermissionError('That is turned off in PyCog')


sys.addaudithook(_audit)


class _Output:
    """Collects what the program prints (up to a limit) and sends it to
    the page about every 0.1 s, so a program that is stopped for running
    too long still shows what it printed."""

    def __init__(self, emit, limit):
        self.parts, self.pending = [], []
        self.size, self.limit, self.cut = 0, limit, False
        self.emit, self.last = emit, time.monotonic()

    def write(self, text):
        text = str(text)
        if self.cut:
            return len(text)
        room = self.limit - self.size
        if len(text) > room:
            text, self.cut = text[:room], True
        self.parts.append(text)
        self.pending.append(text)
        self.size += len(text)
        now = time.monotonic()
        if self.cut or now - self.last > 0.1:
            self.send()
            self.last = now
        return len(text)

    def send(self):
        if self.pending:
            self.emit(''.join(self.pending))
            self.pending = []

    def flush(self):
        pass

    def text(self):
        return ''.join(self.parts) + ('\n[Output too long: cut]' if self.cut else '')


def _last_error_line(exc):
    # The real traceback's last line, e.g.
    # "ValueError: invalid literal for int() with base 10: 'abc'".
    lines = ''.join(traceback.format_exception_only(type(exc), exc)).splitlines()
    for line in lines:
        if line and not line.startswith(' '):
            return line
    return type(exc).__name__


def _pycog_run(code, inputs, limit, emit):
    out = _Output(emit, limit)
    answers = [str(a) for a in inputs]

    def fake_input(prompt=''):
        out.write(str(prompt))
        if not answers:
            raise EOFError('EOF when reading a line')
        answer = answers.pop(0)
        out.write(answer + '\n')  # shown like a terminal: question, answer
        return answer

    safe = dict(builtins.__dict__)
    safe.update(__import__=_guarded_import, open=_no_files, input=fake_input)
    program_globals = {'__name__': '__main__', '__builtins__': safe}
    old_out, old_err = sys.stdout, sys.stderr
    sys.stdout = sys.stderr = out
    error = None
    _active[0] = True
    try:
        exec(compile(code, '<code>', 'exec'), program_globals)
    except SystemExit as exc:
        if exc.code not in (None, 0):
            error = f'SystemExit: {exc.code}'
    except BaseException as exc:
        error = _last_error_line(exc)
    finally:
        _active[0] = False
        sys.stdout, sys.stderr = old_out, old_err
    return json.dumps({'stdout': out.text(), 'error': error})
`;

let pyodide = null;

const ready = (async () => {
  const start = performance.now();
  pyodide = await loadPyodide({ indexURL: './' });
  pyodide.runPython(SANDBOX_PY);
  // No network from JavaScript either. (The app itself has no internet
  // permission, so Android blocks the network anyway.)
  for (const name of ['fetch', 'XMLHttpRequest', 'WebSocket', 'EventSource']) {
    try {
      self[name] = undefined;
    } catch (_) {}
  }
  postMessage({ type: 'ready', loadMs: Math.round(performance.now() - start) });
})().catch((err) => {
  postMessage({ type: 'loadError', error: String((err && err.stack) || err) });
});

self.onmessage = async (event) => {
  const { id, code, inputs, maxOutput } = event.data;
  try {
    await ready;
  } catch (_) {
    return; // loadError was already reported
  }
  postMessage({ type: 'started', id });
  const run = pyodide.globals.get('_pycog_run');
  const pyInputs = pyodide.toPy(inputs || []);
  const emit = (chunk) => postMessage({ type: 'out', id, chunk });
  let result;
  try {
    result = JSON.parse(run(code, pyInputs, maxOutput, emit));
  } catch (err) {
    result = { stdout: '', error: 'InternalError: ' + String(err) };
  } finally {
    pyInputs.destroy();
    run.destroy();
  }
  postMessage({ type: 'done', id, stdout: result.stdout, error: result.error });
};
