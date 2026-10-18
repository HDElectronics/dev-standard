#!/usr/bin/env python3
"""Build the dev-standard guide page from template.html and the repository's own files.

The rule catalog, the source index, the interview rounds, the terminal captures and the
counts all come from the files they describe, so the page can't drift from the standard.

Usage:
    python3 docs/guide/build.py                    # writes docs/guide/index.html
    python3 docs/guide/build.py --fragment OUT     # also writes the page without the
                                                  # document wrapper (for hosts that add one)
"""

from __future__ import annotations

import argparse
import html
import re
from collections import OrderedDict
from pathlib import Path

SITE = Path(__file__).resolve().parent
ROOT = SITE.parent.parent

CATEGORIES = [
    ("Workflow", "How work moves from idea to merged code.", ["AGT", "INS", "BRN", "SDD", "ADR"]),
    ("Code", "What the code itself looks like.", ["NAM", "STY", "ERR", "TST", "DOC"]),
    ("Collaboration", "How changes reach main.", ["GIT", "BRA", "PR", "REV"]),
    ("Security baseline", "For every repo, deployed or not.", ["SEC"]),
    ("Frontend profile", "For repos with a React UI.", ["UI"]),
    ("Production pack", "For anything that is deployed.", ["AUTH", "ABU", "API", "WEB", "REL", "OBS", "OPS", "DAT"]),
    ("Opt-in packs", "Added per project.", ["EMB", "LLM", "MOB"]),
]
RULE = re.compile(r"^### ([A-Z]+-\d{3}) · (MUST NOT|MUST|SHOULD NOT|SHOULD|MAY) · (.+)$", re.MULTILINE)
e = html.escape


def md_inline(text: str) -> str:
    """Escape text and render `code` spans, the only Markdown the extracted strings use."""
    return re.sub(r"`([^`]+)`", r"<code>\1</code>", e(text))


def frontmatter(text: str) -> dict:
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    data: dict = {"based_on": []}
    if not match:
        return data
    for line in match.group(1).splitlines():
        item = re.match(r"^\s+-\s+name:\s*(.+)$", line)
        url = re.match(r"^\s+url:\s*(.+)$", line)
        scalar = re.match(r"^(\w+):\s*(.*?)\s*(#.*)?$", line)
        if item:
            data["based_on"].append({"name": item.group(1).strip().strip('"'), "url": ""})
        elif url and data["based_on"]:
            data["based_on"][-1]["url"] = url.group(1).strip()
        elif scalar and scalar.group(2):
            data[scalar.group(1)] = scalar.group(2).strip('"')
    return data


def load_groups() -> dict[str, dict]:
    files = [p for p in sorted((ROOT / "standards").rglob("*.md")) if p.name != "README.md"]
    groups = {}
    for path in files:
        text = path.read_text()
        meta = frontmatter(text)
        if "id" not in meta:
            continue
        meta["rules"] = RULE.findall(text)
        meta["path"] = str(path.relative_to(ROOT))
        meta["text"] = text
        groups[meta["id"]] = meta
    return groups


def level_class(level: str) -> str:
    return "must" if level.startswith("MUST") else "should" if level.startswith("SHOULD") else "may"


def render_catalog(groups: dict[str, dict]) -> str:
    out = []
    for name, blurb, ids in CATEGORIES:
        out.append(f'<div class="cat"><div class="cat-head"><h3>{e(name)}</h3><p>{e(blurb)}</p></div><div class="cards">')
        for gid in ids:
            g = groups[gid]
            counts = OrderedDict((k, 0) for k in ("must", "should", "may"))
            for _, level, _ in g["rules"]:
                counts[level_class(level)] += 1
            pills = "".join(f'<span class="lvl {k}">{v} {k.upper()}</span>' for k, v in counts.items() if v)
            sources = "".join(
                f'<a href="{e(s["url"])}">{e(s["name"])}</a>' if s["url"] else f'<span class="src">{e(s["name"])}</span>'
                for s in g["based_on"]
            )
            rules = "".join(
                f'<li><span class="rid">{rid}</span><span class="lvl {level_class(lv)}">{lv}</span><span>{md_inline(title)}</span></li>'
                for rid, lv, title in g["rules"]
            )
            out.append(
                f'<article class="gcard" id="g-{gid.lower()}">'
                f'<div class="gtop"><span class="prefix">{gid}</span><h4>{e(g["title"])}</h4></div>'
                f'<div class="gmeta">{pills}<span class="applies">applies to: {e(g.get("applies_to", "all"))}</span></div>'
                f'<div class="based"><span class="k">Based on</span>{sources}</div>'
                f'<details><summary>{len(g["rules"])} rules</summary><ul class="rules">{rules}</ul>'
                f'<p class="file">Source file: <code>{e(g["path"])}</code></p></details></article>'
            )
        out.append("</div></div>")
    return "\n".join(out)


def render_sources(groups: dict[str, dict]) -> tuple[str, int]:
    index: dict[str, dict] = {}
    for gid, g in groups.items():
        for s in g["based_on"]:
            entry = index.setdefault(s["name"], {"url": s["url"], "groups": []})
            entry["url"] = entry["url"] or s["url"]
            if gid not in entry["groups"]:
                entry["groups"].append(gid)
    rows = []
    for name in sorted(index, key=lambda n: (-len(index[n]["groups"]), n.lower())):
        entry = index[name]
        label = f'<a href="{e(entry["url"])}">{e(name)}</a>' if entry["url"] else e(name)
        chips = "".join(f'<a class="chip" href="#g-{g.lower()}">{g}</a>' for g in entry["groups"])
        rows.append(f"<tr><td>{label}</td><td><div class=\"chips\">{chips}</div></td></tr>")
    return "\n".join(rows), len(index)


def render_anatomy(groups: dict[str, dict], rule_id: str = "ABU-001") -> str:
    g = groups[rule_id.split("-")[0]]
    block = re.search(rf"^### {rule_id} · (.+?) · (.+?)\n\n(.+?)\n\n- \*\*Why:\*\* (.+?)\n- \*\*Check:\*\* (.+?)\n", g["text"], re.MULTILINE | re.DOTALL)
    level, title, statement, why, check = (s.strip() for s in block.groups())
    sources = ", ".join(e(s["name"]) for s in g["based_on"][:2])
    return (
        f'<div class="anatomy"><div class="a-row"><span class="rid">{rule_id}</span><span class="lvl {level_class(level)}">{level}</span>'
        f'<strong>{md_inline(title)}</strong></div><p>{md_inline(statement)}</p>'
        f'<dl><dt>Why</dt><dd>{md_inline(why)}</dd><dt>Check</dt><dd>{md_inline(check)}</dd>'
        f'<dt>Based on</dt><dd>{sources}</dd></dl>'
        f'<p class="file">From <code>{e(g["path"])}</code></p></div>'
    )


def render_rounds() -> str:
    text = (ROOT / "install" / "interview.md").read_text()
    rows = []
    for round_match in re.finditer(r"^## Round (\d) · (.+?)(?: \((.+?)\))?$\n(.*?)(?=^## |\Z)", text, re.MULTILINE | re.DOTALL):
        number, title, when, body = round_match.groups()
        questions = []
        for q in re.finditer(r"^### (Q-[A-Z]+-[A-Za-z0-9]+) · (.+?)$.*?\*\*Question:\*\* (.+?)$", body, re.MULTILINE | re.DOTALL):
            questions.append(f'<li><span class="rid">{q.group(1)}</span> <strong>{md_inline(q.group(2))}</strong><span class="q">{md_inline(q.group(3).strip(chr(34)))}</span></li>')
        rows.append(
            f'<tr><td class="round">{number}</td><td><strong>{md_inline(title)}</strong>'
            f'{f"<span class=when>{md_inline(when)}</span>" if when else ""}</td><td><ul class="qs">{"".join(questions)}</ul></td></tr>'
        )
    return "\n".join(rows)


def render_terminal(name: str) -> str:
    lines = []
    for line in (SITE / "captures" / f"{name}.txt").read_text().rstrip("\n").split("\n"):
        esc = e(line)
        if line.startswith("$"):
            esc = f'<span class="t-cmd">{esc}</span>'
        elif line.startswith("[exit"):
            code = re.search(r"\d+", line).group(0)
            esc = f'<span class="t-exit {"bad" if code != "0" else "ok"}">exit {code}</span>'
        else:
            esc = re.sub(r"^(ERROR)", r'<span class="t-err">\1</span>', esc)
            esc = re.sub(r"^(WARNING)", r'<span class="t-warn">\1</span>', esc)
            esc = re.sub(r"^(OK|✔.*)$", r'<span class="t-ok">\1</span>', esc)
            esc = re.sub(r"\b([A-Z]{2,4}-\d{3})\b", r'<span class="t-rule">\1</span>', esc)
        lines.append(esc)
    return "<pre class=\"term\"><code>" + "\n".join(lines) + "</code></pre>"


def stats(groups: dict[str, dict], n_sources: int) -> dict[str, str]:
    cli = (ROOT / "cli" / "dev-standard").read_text()
    checks = re.search(r"ALL_CHECKS = \((.+?)\)", cli).group(1).count('"') // 2
    hooks = len([p for p in (ROOT / "enforce" / "hooks").glob("*.sh") if p.name != "lib.sh"])
    tests = len(re.findall(r"^\s+def test_", (ROOT / "tests" / "test_dev_standard.py").read_text(), re.MULTILINE))
    return {
        "N_RULES": str(sum(len(g["rules"]) for g in groups.values())),
        "N_GROUPS": str(len(groups)),
        "N_SOURCES": str(n_sources),
        "N_HOOKS": str(hooks),
        "N_CHECKS": str(checks),
        "N_TESTS": str(tests),
        "VERSION": (ROOT / "VERSION").read_text().strip(),
    }


def build() -> str:
    groups = load_groups()
    sources, n_sources = render_sources(groups)
    page = (SITE / "template.html").read_text()
    replacements = {
        "<!--CATALOG-->": render_catalog(groups),
        "<!--SOURCES-->": sources,
        "<!--ANATOMY-->": render_anatomy(groups),
        "<!--ROUNDS-->": render_rounds(),
    }
    for name in ("hook-spec", "hook-brainstorm", "hook-approve", "hook-bypass", "hook-dod", "cli", "tests"):
        replacements[f"<!--TERM:{name}-->"] = render_terminal(name)
    for key, value in stats(groups, n_sources).items():
        replacements[f"{{{{{key}}}}}"] = value
    for key, value in replacements.items():
        if key not in page:
            raise SystemExit(f"template.html has no {key}")
        page = page.replace(key, value)
    leftover = re.findall(r"<!--(?:CATALOG|SOURCES|ANATOMY|ROUNDS|TERM:[\w-]+)-->|\{\{[A-Z_]+\}\}", page)
    if leftover:
        raise SystemExit(f"unfilled placeholders: {leftover}")
    return page


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--fragment", help="also write the page without the document wrapper")
    args = parser.parse_args()
    fragment = build()
    document = (
        '<!doctype html>\n<html lang="en">\n<meta charset="utf-8">\n'
        '<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">\n' + fragment + "\n</html>\n"
    )
    (SITE / "index.html").write_text(document)
    print(f"wrote {SITE / 'index.html'}")
    if args.fragment:
        Path(args.fragment).write_text(fragment)
        print(f"wrote {args.fragment}")


if __name__ == "__main__":
    main()
