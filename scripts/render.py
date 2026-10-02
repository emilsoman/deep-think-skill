#!/usr/bin/env python3
"""Write SESSION/data.js for the progress page (SESSION/index.html).

Usage: render.py <session-dir>

Many agents call this at the same time. Only one renders; the others mark
the data as dirty, and the renderer runs again until nothing is dirty.
"""
import hashlib
import json
import os
import re
import shutil
import sys
import time
from pathlib import Path

SKILL = Path(__file__).resolve().parent.parent
POST = re.compile(r"^## r(\d+) · (\S+) → (\S+) · (\S+)\s*$")


def read(path):
    try:
        return path.read_text()
    except (FileNotFoundError, NotADirectoryError):
        return None


def tool_meta():
    tools = []
    for f in sorted((SKILL / "tools").glob("*.md")):
        text = f.read_text()
        field = lambda pat: (m.group(1).strip() if (m := re.search(pat, text, re.M)) else "")
        tools.append({
            "slug": f.stem,
            "name": field(r"^# (.+)$") or f.stem,
            "group": field(r"^Group: (.+)$"),
            "use": field(r"^Use it for: (.+)$"),
        })
    return tools


def parse_posts(chat):
    posts, cur = [], None
    in_posts = False
    for line in (chat or "").splitlines():
        m = POST.match(line)
        if m:
            in_posts = True
            if cur:
                posts.append(cur)
            cur = {"round": int(m[1]), "from": m[2], "to": m[3], "time": m[4], "lines": []}
        elif in_posts and cur:
            cur["lines"].append(line)
    if cur:
        posts.append(cur)
    for p in posts:
        p["text"] = "\n".join(p.pop("lines")).strip()
        p["pass"] = p["text"] == "PASS"
    return posts


def parse_events(text):
    events = []
    for line in (text or "").splitlines():
        parts = line.split("\t")
        if len(parts) >= 2:
            events.append({
                "time": parts[0],
                "type": parts[1],
                "round": int(parts[2]) if len(parts) > 2 and parts[2].isdigit() else 0,
                "arg": parts[3] if len(parts) > 3 else "",
            })
    return events


def build(session):
    tools = tool_meta()
    posts = parse_posts(read(session / "chatroom.md"))
    events = parse_events(read(session / "events.log"))

    rounds, max_rounds, stage = 0, 3, "setup"
    started, finished, queued = set(), set(), set()
    for e in events:
        if e["type"] == "round":
            rounds = max(rounds, e["round"])
            if e["arg"].isdigit():
                max_rounds = int(e["arg"])
            stage = "round"
            queued |= {(e["round"], t["slug"]) for t in tools}
        elif e["type"] == "start":
            started.add((e["round"], e["arg"]))
        elif e["type"] == "finish":
            finished.add((e["round"], e["arg"]))
        elif e["type"] == "stage":
            stage = e["arg"]
    rounds = max([rounds] + [p["round"] for p in posts])
    if rounds and stage == "setup":
        stage = "round"

    def state(slug, r):
        mine = [p for p in posts if p["round"] == r and p["from"] == slug]
        key = (r, slug)
        if key in finished or (mine and key not in started):
            if not mine:
                return "silent"
            return "pass" if all(p["pass"] for p in mine) else "done"
        if key in started:
            return "posting" if mine else "running"
        if key in queued:
            return "queued"
        return "idle"

    for t in tools:
        t["result"] = read(session / "tools" / f"{t['slug']}.md")
        t["states"] = {str(r): state(t["slug"], r) for r in range(1, rounds + 1)}
        t["posts"] = sum(1 for p in posts if p["from"] == t["slug"])
        t["mentions"] = sum(1 for p in posts if p["to"] == t["slug"])

    return {
        "session": session.name,
        "path": str(session),
        "rendered": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "stage": stage,
        "round": rounds,
        "maxRounds": max(max_rounds, rounds),
        "problem": read(session / "problem.md") or "",
        "tools": tools,
        "posts": posts,
        "converge": read(session / "converge.md"),
        "report": read(session / "report.md"),
    }


def write(session):
    data = build(session)
    body = json.dumps(data, ensure_ascii=False)
    data["version"] = hashlib.sha1(body.encode()).hexdigest()[:12]
    tmp = session / f".data.js.{os.getpid()}"
    tmp.write_text("window.__DEEP_THINK__ = " + json.dumps(data, ensure_ascii=False) + ";\n")
    os.replace(tmp, session / "data.js")


def main():
    session = Path(sys.argv[1]).resolve()
    if not (session / "problem.md").exists():
        sys.exit(f"not a deep-think session: {session}")
    page = session / "index.html"
    if not page.exists():
        shutil.copy(SKILL / "ui" / "index.html", page)

    lock, dirty = session / ".render.lock", session / ".render.dirty"
    dirty.touch()
    while True:
        try:
            lock.mkdir()
        except FileExistsError:
            try:
                stale = time.time() - lock.stat().st_mtime > 10
            except FileNotFoundError:
                continue
            if stale:
                shutil.rmtree(lock, ignore_errors=True)
                continue
            return  # The lock holder renders again because of the dirty mark.
        try:
            while dirty.exists():
                dirty.unlink(missing_ok=True)
                write(session)
        finally:
            lock.rmdir()
        if not dirty.exists():
            return


if __name__ == "__main__":
    main()
