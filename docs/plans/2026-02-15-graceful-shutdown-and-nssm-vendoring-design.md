# Graceful Shutdown and NSSM Vendoring

## Problem

1. The Windows server process is killed via `TerminateProcess` on shutdown, bypassing
   Kolibri's cleanup sequence (HTTP server, IPC pipes, workers, PID files).
2. CI builds fail because the NSSM download from `nssm.cc` returns HTTP 503 errors.

## Solution

### Graceful Shutdown

**File:** `src/kolibri_app/server_manager_windows.py`

Replace `subprocess.terminate()` (which calls `TerminateProcess` on Windows) with
a call to `kolibri.utils.server.stop()`. This function:

1. Writes `"stop"` to `$KOLIBRI_HOME/process_control.flag`
2. `ProcessControlPlugin` (polling every 1s) reads the flag and calls
   `bus.transition("EXITED")`, walking the bus through `RUN -> STOP -> IDLE -> EXIT -> EXITED`
3. All bus plugins fire their cleanup handlers (HTTP server, IPC pipe, workers, PID file)
4. Waits up to 10s for `STATUS_STOPPED`
5. Falls back to `os.kill(pid, CTRL_C_EVENT)` if the process is still alive

The existing `subprocess.terminate()` and Job Object (`JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE`)
remain as a final safety net after `stop()`.

**Scope:** This covers UI-initiated shutdown (user closes the app). NSSM service-initiated
stops (`net stop Kolibri`, system reboot) will still use `TerminateProcess` via NSSM's
default behavior. A Stop/Pre hook could address that in a future change.

### Vendor NSSM Binary

Commit the NSSM 2.24 win64 binary directly to `vendor/nssm/nssm.exe` instead of
downloading it at build time. At 323KB, the binary is small enough to commit directly
without Git LFS. NSSM 2.24 is the latest release (2017) and the project is effectively
unmaintained, so no automated update workflow is needed.

**Changes:**

- Add `vendor/nssm/nssm.exe` (committed binary, 323KB)
- `Makefile`: Remove the `nssm` download target and its usage as a dependency,
  update references to `vendor/nssm/nssm.exe`
- `kolibri.spec`: Update data path from `('nssm.exe', 'nssm')` to
  `('vendor/nssm/nssm.exe', 'nssm')`
- `kolibri.iss`: Update source path from `"nssm.exe"` to `"vendor\nssm\nssm.exe"`
