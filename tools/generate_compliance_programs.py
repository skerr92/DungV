#!/usr/bin/env python3
"""Generate DungV compliance assembly/images from OASIS YAML tests."""

from __future__ import annotations

import argparse
import ast
from pathlib import Path
import re
import subprocess
import sys


def scalar_value(text: str, key: str) -> str | None:
    match = re.search(rf"^{key}:\s*(.+)$", text, re.MULTILINE)
    return match.group(1).strip() if match else None


def parse_program(text: str) -> list[str]:
    program: list[str] = []
    in_program = False

    for line in text.splitlines():
        stripped = line.strip()
        if stripped == "program:":
            in_program = True
            continue
        if in_program and re.match(r"^[A-Za-z0-9_-]+:", line):
            break
        if not in_program or not stripped.startswith("- "):
            continue

        item = stripped[2:].strip()
        if item.startswith(('"', "'")):
            item = ast.literal_eval(item)
        program.append(item)

    return program


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate DungV assembly/images from OASIS compliance YAML"
    )
    parser.add_argument("--source-dir", type=Path, required=True)
    parser.add_argument("--out-dir", type=Path, required=True)
    parser.add_argument("--profile", action="append", required=True)
    parser.add_argument("--assembler", type=Path, required=True)
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    profiles = set(args.profile)
    args.out_dir.mkdir(parents=True, exist_ok=True)

    generated = 0
    for path in sorted(args.source_dir.glob("*.yaml")):
        text = path.read_text()
        profile = scalar_value(text, "profile")
        if profile not in profiles:
            continue

        name = scalar_value(text, "name")
        if not name:
            print(f"{path}: missing test name", file=sys.stderr)
            return 1

        program = parse_program(text)
        if not program:
            print(f"{path}: missing program", file=sys.stderr)
            return 1

        asm_path = args.out_dir / f"{name}.oas"
        mem_path = args.out_dir / f"{name}.mem"
        asm_path.write_text("\n".join(program) + "\n")
        subprocess.run(
            [sys.executable, str(args.assembler), str(asm_path), "-o", str(mem_path)],
            check=True,
        )
        generated += 1

    if generated == 0:
        print("no compliance tests matched requested profile(s)", file=sys.stderr)
        return 1

    print(f"generated {generated} compliance program(s) in {args.out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
