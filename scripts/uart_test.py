#!/usr/bin/env python3
"""
uart_test.py - Automated UART loopback test.
Sends bytes one-at-a-time and verifies each is echoed back.

Usage: python3 scripts/uart_test.py [--port /dev/ttyUSB1] [--baud 115200]
"""
import serial
import sys
import time
import argparse
import glob
import subprocess

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
        props = dict(line.split("=", 1) for line in out.splitlines() if "=" in line)
        model = props.get("ID_MODEL", "")
        vendor = props.get("ID_VENDOR_ID", "")
        product = props.get("ID_MODEL_ID", "")
        if "USB_Serial" in model or (vendor, product) == ("1a86", "7523"):
            return dev
    return candidates[0] if candidates else None

def main():
    ap = argparse.ArgumentParser(description="UART loopback test")
    ap.add_argument("--port", default=None)
    ap.add_argument("--baud", type=int, default=115200)
    ap.add_argument("--timeout", type=float, default=3.0,
                    help="seconds to wait per byte echo")
    args = ap.parse_args()

    test_data = bytes(range(0x21, 0x7F))  # printable ASCII, skip space

    try:
        port = args.port or autodetect_port()
        if not port:
            print("FAIL: no serial port found")
            sys.exit(1)
        ser = serial.Serial(port, args.baud, timeout=args.timeout)
    except serial.SerialException as e:
        print(f"FAIL: cannot open serial port: {e}")
        sys.exit(1)

    time.sleep(0.2)
    ser.reset_input_buffer()

    ok = 0
    fails = []

    for b in test_data:
        ser.write(bytes([b]))
        ser.flush()
        echo = ser.read(1)
        if echo == bytes([b]):
            ok += 1
        else:
            got = f"0x{echo[0]:02x}" if echo else "timeout"
            fails.append((b, got))

    ser.close()

    if fails:
        print(f"FAIL: {len(fails)}/{len(test_data)} mismatches")
        for sent, got in fails[:10]:
            print(f"  sent 0x{sent:02x} ({chr(sent)!r}), got {got}")
        sys.exit(1)
    else:
        print(f"PASS: {ok}/{len(test_data)} bytes echoed correctly")
        sys.exit(0)

if __name__ == "__main__":
    main()
