import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

CONTINUATION = (
    "\u0402\u0403\u201a\u0453\u201e\u2026\u2020\u2021\u20ac\u2030\u0409\u2039"
    "\u040a\u040c\u040b\u040f\u0452\u2018\u2019\u201c\u201d\u2022\u2013\u2014"
    "\u2122\u0459\u203a\u045a\u045c\u045b\u045f\u00a0\u040e\u045e\u0408\u00a4"
    "\u0490\u00a6\u00a7\u00a9\u0404\u00ac\u00ad\u00ae\u0407"
    "\u00b0\u00b1\u0406\u0456\u0491\u00b5\u00b6\u00b7\u2116\u0454\u0458\u0405\u0455\u0457"
)

MOJI = re.compile("[\u0420\u0421\u0412\u0432][" + re.escape(CONTINUATION) + "]")

targets = []
for pattern in ("lib/**/*.dart", "test/**/*.dart", "mock-server.js", "web/index.html"):
    targets.extend(ROOT.glob(pattern))

found = []
for path in sorted(targets):
    text = path.read_text(encoding="utf-8", errors="replace")
    hits = MOJI.findall(text)
    if hits:
        found.append(f"{path.relative_to(ROOT)}: {len(hits)}")

print("\n".join(found) if found else "чисто")
sys.exit(1 if found else 0)
