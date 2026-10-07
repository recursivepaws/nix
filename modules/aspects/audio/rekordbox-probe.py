"""Decide whether rekordbox actually held windows on screen.

Reads a log of "<monotonic seconds> <niri event-stream JSON>" lines.

Under winewayland every Wine window is a real toplevel, so niri sees all of
them -- including the four drop-shadow slivers JUCE wraps around each popup.
That makes the compositor's own event stream a complete view, and the JUCE
teardown bug legible directly: a titled window that maps and dies within
TEARDOWN_FLOOR is the signature (upstream measured it at 11ms on KWin).

An earlier version of this also parsed a WINEDEBUG=+win trace for popups. That
is gone: Wine's +win channel logs no ShowWindow in this build (0 matches in 33k
lines), and under Wayland it would be redundant anyway.
"""

import json
import sys

MIN_LIFETIME = 8.0
TEARDOWN_FLOOR = 1.0
# JUCE's drop shadows are slivers with no title; they are noise, not windows.
SHADOW_PX = 16


def load(path):
    """-> ({id: record}, last timestamp seen)"""
    seen, end = {}, 0.0
    for line in open(path, errors="replace"):
        stamp, _, payload = line.partition(" ")
        try:
            at = float(stamp)
            event = json.loads(payload)
        except ValueError:
            continue
        end = max(end, at)

        def touch(w):
            rec = seen.setdefault(w["id"], {"first": at, "closed": None})
            rec["app_id"] = w.get("app_id") or "?"
            rec["title"] = w.get("title") or ""
            rec["floating"] = w.get("is_floating")
            rec["size"] = (w.get("layout") or {}).get("window_size")

        if "WindowOpenedOrChanged" in event:
            touch(event["WindowOpenedOrChanged"]["window"])
        elif "WindowsChanged" in event:
            for w in event["WindowsChanged"]["windows"]:
                touch(w)
        elif "WindowClosed" in event:
            rec = seen.get(event["WindowClosed"]["id"])
            if rec:
                rec["closed"] = at
    return seen, end


def main(path):
    windows, end = load(path)
    if not windows:
        print("no windows seen at all -- did niri msg event-stream run?")
        return 2

    # Identify rekordbox's own toplevels without hardcoding an app_id:
    # winewayland derives it from the process name, and confirming what it
    # actually picked is part of the point of this probe.
    # app_id only, never the title: a terminal whose title happens to mention
    # rekordbox would otherwise count as a passing window and mask a FAIL.
    def ours(rec):
        return any(
            k in rec["app_id"].lower()
            for k in ("rekordbox", "wine", "explorer.exe")
        )

    mine = {i: r for i, r in windows.items() if ours(r)}
    if not mine:
        others = sorted({r["app_id"] for r in windows.values()})
        print(f"no rekordbox windows; saw app_ids: {', '.join(others)}")
        return 1

    for r in mine.values():
        # A window still open when the capture ended lived at least this long.
        r["life"] = (end if r["closed"] is None else r["closed"]) - r["first"]
        w, h = r["size"] or (0, 0)
        r["shadow"] = not r["title"] and min(w, h) <= SHADOW_PX

    real = {i: r for i, r in mine.items() if not r["shadow"]}
    shadows = len(mine) - len(real)

    print(f"{'id':>5}  {'app_id':<20} {'life':>7}  {'size':>11}  float  title")
    for wid, r in sorted(real.items()):
        size = "x".join(map(str, r["size"])) if r["size"] else "-"
        state = "closed" if r["closed"] is not None else "open"
        print(
            f"{wid:>5}  {r['app_id']:<20} {r['life']:>6.1f}s  {size:>11}  "
            f"{str(r['floating']):<5}  {r['title'][:34]} [{state}]"
        )
    if shadows:
        print(f"  (+{shadows} untitled JUCE shadow slivers, ignored)")

    best = max((r["life"] for r in real.values()), default=0.0)
    torn = [
        r for r in real.values()
        if r["closed"] is not None and r["life"] < TEARDOWN_FLOOR
    ]

    ok = best >= MIN_LIFETIME
    print(f"\nlongest rekordbox window: {best:.1f}s "
          f"(need >= {MIN_LIFETIME:.0f}s) -- {'PASS' if ok else 'FAIL'}")
    for r in torn:
        print(f"  teardown? {r['title'][:40]!r} lived {r['life'] * 1000:.0f}ms")
    if torn:
        print("  titled windows dying this fast is the JUCE signature -- "
              "transient progress dialogs also look like this, so check which")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
