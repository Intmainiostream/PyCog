// PyCog Python runner page. Flutter calls pycogRun(...); the result goes
// back through the 'pyResult' handler. Python runs in a Web Worker
// (worker.mjs) so a program that runs too long can be killed with
// terminate() and a fresh worker started. One program runs at a time.

let worker = null;
let workerReady = false;
let current = null; // the program running now
const queue = []; // programs waiting their turn
const outbox = []; // messages waiting for Flutter's bridge

function sendToFlutter(message) {
  const bridge = window.flutter_inappwebview;
  if (bridge && bridge.callHandler) {
    bridge.callHandler('pyResult', JSON.stringify(message));
  } else {
    outbox.push(message);
  }
}

window.addEventListener('flutterInAppWebViewPlatformReady', () => {
  while (outbox.length) sendToFlutter(outbox.shift());
});

function startWorker() {
  workerReady = false;
  worker = new Worker('worker.mjs', { type: 'module' });
  worker.onmessage = onWorkerMessage;
  worker.onerror = (event) => {
    event.preventDefault();
    const message = event.message || 'unknown error';
    if (!workerReady) {
      failAll('PythonStartError: ' + message);
      return;
    }
    if (current) {
      finish({ stdout: current.live, error: 'CrashError: ' + message, timedOut: false });
    }
    worker.terminate();
    startWorker();
  };
}

function onWorkerMessage(event) {
  const m = event.data;
  if (m.type === 'ready') {
    workerReady = true;
    sendToFlutter({ type: 'status', ready: true, loadMs: m.loadMs });
    next();
  } else if (m.type === 'loadError') {
    failAll('PythonStartError: ' + m.error);
  } else if (!current || m.id !== current.id) {
    // A message from a program that was already stopped: ignore it.
  } else if (m.type === 'started') {
    current.startedAt = performance.now();
    current.timer = setTimeout(onTimeout, current.timeoutMs);
  } else if (m.type === 'out') {
    current.live += m.chunk;
  } else if (m.type === 'done') {
    finish({ stdout: m.stdout, error: m.error, timedOut: false });
  }
}

function onTimeout() {
  // The program ran too long (e.g. while True:). Kill the worker, keep
  // what it printed so far, and start a fresh Python for the next run.
  worker.terminate();
  finish({ stdout: current.live, error: null, timedOut: true });
  startWorker();
}

function finish(result) {
  const job = current;
  clearTimeout(job.timer);
  current = null;
  const runMs = job.startedAt ? Math.round(performance.now() - job.startedAt) : 0;
  sendToFlutter({ type: 'result', id: job.id, runMs, ...result });
  next();
}

function failAll(error) {
  const jobs = current ? [current, ...queue.splice(0)] : queue.splice(0);
  current = null;
  for (const job of jobs) {
    clearTimeout(job.timer);
    sendToFlutter({ type: 'result', id: job.id, runMs: 0, stdout: '', error, timedOut: false });
  }
}

function next() {
  if (current || !workerReady || queue.length === 0) return;
  current = queue.shift();
  current.live = '';
  worker.postMessage({
    id: current.id,
    code: current.code,
    inputs: current.inputs,
    maxOutput: current.maxOutput,
  });
}

window.pycogRun = (id, code, inputs, timeoutMs, maxOutput) => {
  queue.push({ id, code, inputs, timeoutMs, maxOutput, startedAt: 0, timer: null });
  next();
};

startWorker();
