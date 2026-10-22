import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
TARGETS = [
    ROOT / "test" / "api_category_repository_test.dart",
    ROOT / "test" / "api_product_repository_test.dart",
]


def fix_run(run: str):
    try:
        return run.encode("cp1251").decode("utf-8")
    except (UnicodeEncodeError, UnicodeDecodeError):
        return None


def fix_text(text: str):
    out = []
    failures = []
    i = 0
    n = len(text)
    while i < n:
        if ord(text[i]) < 128:
            out.append(text[i])
            i += 1
            continue
        j = i
        while j < n and ord(text[j]) >= 128:
            j += 1
        run = text[i:j]
        fixed = fix_run(run)
        if fixed is None:
            failures.append(run)
            out.append(run)
        else:
            out.append(fixed)
        i = j
    return "".join(out), failures


for path in TARGETS:
    original = path.read_text(encoding="utf-8-sig")
    fixed, failures = fix_text(original)
    path.write_text(fixed, encoding="utf-8")
    print(f"{path.name}: changed={original != fixed} unfixed_runs={len(failures)}")
    for run in failures:
        print(f"   left as is: {run[:60]!r}")
