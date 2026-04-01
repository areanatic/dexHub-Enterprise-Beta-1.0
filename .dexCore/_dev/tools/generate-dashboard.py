#!/usr/bin/env python3
"""
DexHub Dashboard Generator
===========================
Reads project files and regenerates dexhub-dashboard.html with embedded file contents.

Usage:
  python3 .dexCore/_dev/tools/generate-dashboard.py

This updates the FILE_CONTENTS section in the dashboard HTML so that
touchpoint links show live file contents in the flyout viewer.
"""

import os
import json
import re
import sys
from datetime import datetime
from pathlib import Path

# Dashboard version — update on each release
DASHBOARD_VERSION = "EA-2.0 Beta"

# Project root = 3 levels up from this script
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent.parent.parent
DASHBOARD_PATH = SCRIPT_DIR / "dexhub-dashboard.html"

# Files to embed (relative to project root)
FILES_TO_EMBED = [
    ".claude/CLAUDE.md",
    ".github/copilot-instructions.md",
    ".dexCore/core/agents/dex-master.md",
    ".dexCore/core/agents/mydex-agent.md",
    ".dexCore/_cfg/config.yaml",
    ".dexCore/_cfg/agent-manifest.csv",
    ".dexCore/_dev/agents/dev-mode-master.md",
    ".dexCore/_dev/analysis/BUG-REANALYSIS-HOLISTIC-2026-03-14.md",
    ".dexCore/_dev/analysis/HOLISTIC-ROADMAP-REVIEW-2026-03-14.md",
    ".dexCore/_dev/todos/features.md",
    ".dexCore/_dev/todos/bugs.md",
    ".dexCore/_dev/CHANGELOG.md",
    ".dexCore/dxm/agents/",  # Directory — will scan all .md files
]

# Additional pattern: scan all agent .md files
AGENT_DIR = ".dexCore/dxm/agents"


def read_file_safe(path: Path, max_lines: int = 500) -> str:
    """Read file content, truncate if too long."""
    try:
        content = path.read_text(encoding="utf-8", errors="replace")
        lines = content.splitlines()
        if len(lines) > max_lines:
            truncated = "\n".join(lines[:max_lines])
            truncated += f"\n\n... ({len(lines) - max_lines} weitere Zeilen gekuerzt) ..."
            return truncated
        return content
    except Exception as e:
        return f"[Fehler beim Lesen: {e}]"


def collect_files() -> dict:
    """Collect all files to embed."""
    files = {}

    for rel_path in FILES_TO_EMBED:
        full_path = PROJECT_ROOT / rel_path
        if full_path.is_dir():
            # Scan directory for .md files
            for md_file in sorted(full_path.glob("*.md")):
                key = str(md_file.relative_to(PROJECT_ROOT))
                files[key] = read_file_safe(md_file)
            for csv_file in sorted(full_path.glob("*.csv")):
                key = str(csv_file.relative_to(PROJECT_ROOT))
                files[key] = read_file_safe(csv_file)
        elif full_path.is_file():
            files[rel_path] = read_file_safe(full_path)

    # Also scan agent directory
    agent_path = PROJECT_ROOT / AGENT_DIR
    if agent_path.is_dir():
        for md_file in sorted(agent_path.glob("*.md")):
            key = str(md_file.relative_to(PROJECT_ROOT))
            if key not in files:
                files[key] = read_file_safe(md_file, max_lines=200)

    return files


def update_header(html: str) -> str:
    """Update version badge and timestamp in dashboard header."""
    now = datetime.now()
    months_de = ["Januar", "Februar", "März", "April", "Mai", "Juni",
                 "Juli", "August", "September", "Oktober", "November", "Dezember"]
    date_str = f"Stand: {now.day}. {months_de[now.month - 1]} {now.year}, {now.strftime('%H:%M')} Uhr"

    # Update version badge
    html = re.sub(
        r'<span class="version">[^<]+</span>',
        f'<span class="version">{DASHBOARD_VERSION}</span>',
        html
    )
    # Update date
    html = re.sub(
        r'<div class="date">[^<]+</div>',
        f'<div class="date">{date_str}</div>',
        html
    )
    return html


def inject_into_dashboard(files: dict) -> bool:
    """Inject FILE_CONTENTS into the dashboard HTML."""
    if not DASHBOARD_PATH.exists():
        print(f"Dashboard not found: {DASHBOARD_PATH}")
        return False

    html = DASHBOARD_PATH.read_text(encoding="utf-8")

    # Create the JS object — compact (no indent) to avoid issues
    js_data = json.dumps(files, ensure_ascii=False)
    # Escape </script> inside strings to prevent HTML parser breakage
    js_data = js_data.replace("</script>", "<\\/script>")

    # Markers in the HTML
    start_marker = "// === FILE_CONTENTS_START ==="
    end_marker = "// === FILE_CONTENTS_END ==="

    replacement = f"{start_marker}\nconst FILE_CONTENTS = {js_data};\n{end_marker}"

    if start_marker in html and end_marker in html:
        # Split-and-rejoin to avoid re.sub backslash interpretation
        before = html.split(start_marker, 1)[0]
        after = html.split(end_marker, 1)[1]
        html = before + replacement + after
    else:
        # Insert before the first const (after script tag)
        insert_point = "// ==================== DATA ===================="
        if insert_point in html:
            injection = f"{replacement}\n\n"
            html = html.replace(insert_point, injection + insert_point)
        else:
            print("Could not find injection point in dashboard HTML!")
            return False

    # Update header (version + timestamp)
    html = update_header(html)

    DASHBOARD_PATH.write_text(html, encoding="utf-8")
    return True


def main():
    print("DexHub Dashboard Generator")
    print(f"Project root: {PROJECT_ROOT}")
    print(f"Dashboard:    {DASHBOARD_PATH}")
    print()

    # Collect files
    files = collect_files()
    print(f"Collected {len(files)} files:")
    for path, content in files.items():
        lines = content.count("\n") + 1
        print(f"  {path} ({lines} lines)")

    # Inject into dashboard
    if inject_into_dashboard(files):
        print(f"\nDashboard updated successfully!")
        print(f"Open: {DASHBOARD_PATH}")
    else:
        print("\nFailed to update dashboard!", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
