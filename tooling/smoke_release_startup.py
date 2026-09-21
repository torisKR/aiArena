"""Emulator-only cold startup regression; never clears app data or log buffers.
Run after installing release-derived APK splits. Captures evidence per launch.
"""
import argparse
import pathlib
import subprocess
import time

PACKAGE = "com.toris.tokenfront.tokenfront"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--output", required=True)
    parser.add_argument("--runs", type=int, default=3)
    args = parser.parse_args()
    assert args.serial.startswith("emulator-"), "Physical-device writes forbidden"
    adb = ["adb", "-s", args.serial]
    out = pathlib.Path(args.output)
    out.mkdir(parents=True, exist_ok=True)

    def run(*command):
        return subprocess.check_output(adb + list(command), text=True)

    package = run("shell", "dumpsys", "package", PACKAGE)
    assert "versionName=" in package, "Install release APK splits first"
    assert "DEBUGGABLE" not in package, "Must exercise release, not debug code"
    for index in range(args.runs):
        run("shell", "am", "force-stop", PACKAGE)
        launch = run("shell", "am", "start", "-W", "-n", PACKAGE + "/.MainActivity")
        (out / f"launch-{index}.txt").write_text(launch)
        time.sleep(8)
        pid = subprocess.run(adb + ["shell", "pidof", PACKAGE], capture_output=True, text=True).stdout.strip()
        assert pid, "Tokenfront exited during startup; inspect package-specific logcat"
        logs = run("logcat", "-d", "-v", "threadtime", "--pid=" + pid)
        (out / f"logcat-{index}.txt").write_text(logs)
        assert "FATAL EXCEPTION" not in logs and "Unhandled Exception" not in logs
        activities = run("shell", "dumpsys", "activity", "activities")
        (out / f"activities-{index}.txt").write_text(activities)
        assert any(PACKAGE in line and "ResumedActivity" in line for line in activities.splitlines())
        (out / f"screen-{index}.png").write_bytes(subprocess.check_output(adb + ["exec-out", "screencap", "-p"]))
        print(f"PASS cold launch {index + 1}: release PID {pid} alive and resumed")


if __name__ == "__main__":
    main()
