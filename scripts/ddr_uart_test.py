#!/usr/bin/env python3
"""Read the DDR hardware test result from USB-UART.

The FPGA program sends 'P\n' on pass or 'F\n' on fail after DDR write/readback.
"""
import argparse
import glob
import subprocess
import sys
import time

import serial


def autodetect_port():
    candidates = sorted(glob.glob("/dev/ttyUSB*") + glob.glob("/dev/ttyACM*"))
    for dev in candidates:
        try:
            out = subprocess.check_output(
                ["udevadm", "info", "-q", "property", dev],
                text=True,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            continue
        props = dict(
            line.split("=", 1) for line in out.splitlines() if "=" in line
        )
        model = props.get("ID_MODEL", "")
        vendor = props.get("ID_VENDOR_ID", "")
        product = props.get("ID_MODEL_ID", "")
        if "USB_Serial" in model or (vendor, product) == ("1a86", "7523"):
            return dev
    return candidates[0] if candidates else None


def main():
    ap = argparse.ArgumentParser(description="DDR UART hardware test")
    ap.add_argument("--port", default=None)
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--timeout", type=float, default=30.0)
    args = ap.parse_args()

    port = args.port or autodetect_port()
    if not port:
        print("FAIL: no serial port found")
        sys.exit(1)

    try:
        ser = serial.Serial(port, args.baud, timeout=0.1)
    except serial.SerialException as e:
        print(f"FAIL: cannot open {port}: {e}")
        sys.exit(1)

    ser.reset_input_buffer()
    deadline = time.time() + args.timeout
    data = bytearray()
    while time.time() < deadline:
        chunk = ser.read(64)
        if chunk:
            data.extend(chunk)
            if b"P" in data or b"F" in data:
                break
        time.sleep(0.02)
    ser.close()

    if b"P" in data:
        print(f"PASS: DDR hardware test returned P on {port}")
        sys.exit(0)
    if b"F" in data:
        print(f"FAIL: DDR hardware test returned F on {port}; raw={data!r}")
        sys.exit(1)
    print(f"FAIL: timeout waiting for DDR result on {port}; raw={data!r}")
    sys.exit(1)


if __name__ == "__main__":
    main()
