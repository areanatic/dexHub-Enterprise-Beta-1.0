#!/usr/bin/env python3
"""
Figma REST API Client — Direct design analysis without MCP
Part of DexHub Integration Layer.

Usage:
  python3 figma_rest_client.py --file-key <key> --analyze
  python3 figma_rest_client.py --file-key <key> --analyze --json
  python3 figma_rest_client.py --file-key <key>

Token lookup order:
  1. FIGMA_ACCESS_TOKEN environment variable
  2. .env in current directory
  3. myDex/projects/figma-integration-pocs/.env (fallback)
"""

import os
import json
import sys
import argparse
from pathlib import Path
from typing import Optional, Dict, Any, List
import urllib.request
import urllib.error


def load_env_file(env_path: Path) -> bool:
    """Load .env file into environment. Returns True if token was found."""
    if not env_path.exists():
        return False
    for line in env_path.read_text().strip().split("\n"):
        if line and not line.startswith("#"):
            key, _, val = line.partition("=")
            if val and key.strip():
                os.environ.setdefault(key.strip(), val.strip())
    return "FIGMA_ACCESS_TOKEN" in os.environ


def find_token() -> Optional[str]:
    """Find Figma token from multiple sources."""
    # 1. Already in environment
    if os.getenv("FIGMA_ACCESS_TOKEN"):
        return os.getenv("FIGMA_ACCESS_TOKEN")

    # 2. .env in current directory
    if load_env_file(Path.cwd() / ".env"):
        return os.getenv("FIGMA_ACCESS_TOKEN")

    # 3. .env in figma-integration-pocs project (fallback)
    project_root = Path(__file__).parent
    while project_root != project_root.parent:
        candidate = project_root / "myDex" / "projects" / "figma-integration-pocs" / ".env"
        if candidate.exists():
            load_env_file(candidate)
            return os.getenv("FIGMA_ACCESS_TOKEN")
        project_root = project_root.parent

    return None


FIGMA_API_BASE = "https://api.figma.com/v1"


class FigmaClient:
    def __init__(self, token: str):
        if not token or token == "your_token_here":
            raise ValueError("FIGMA_ACCESS_TOKEN not set. See: .dexCore/core/integrations/figma-mcp/README.md")
        self.token = token
        self.headers = {
            "X-Figma-Token": token,
            "Accept": "application/json"
        }

    def request(self, endpoint: str, method: str = "GET", data: Optional[Dict] = None) -> Dict[str, Any]:
        """Make authenticated request to Figma API."""
        url = f"{FIGMA_API_BASE}{endpoint}"

        try:
            if method == "GET":
                req = urllib.request.Request(url, headers=self.headers, method=method)
            else:
                req = urllib.request.Request(
                    url,
                    data=json.dumps(data).encode() if data else None,
                    headers={**self.headers, "Content-Type": "application/json"},
                    method=method
                )

            with urllib.request.urlopen(req) as response:
                return json.loads(response.read())
        except urllib.error.HTTPError as e:
            error_body = e.read().decode()
            raise RuntimeError(f"Figma API error {e.code}: {error_body}")
        except Exception as e:
            raise RuntimeError(f"Request failed: {e}")

    def get_me(self) -> Dict[str, Any]:
        """Get current user info (token verification)."""
        return self.request("/me")

    def get_file(self, file_key: str) -> Dict[str, Any]:
        """Get file structure (frames, components, tokens)."""
        return self.request(f"/files/{file_key}")

    def get_file_nodes(self, file_key: str, node_ids: List[str]) -> Dict[str, Any]:
        """Get specific nodes from file."""
        ids_str = ",".join(node_ids)
        return self.request(f"/files/{file_key}/nodes?ids={ids_str}")

    def get_file_images(self, file_key: str, node_ids: List[str], fmt: str = "png", scale: float = 2.0) -> Dict[str, Any]:
        """Export nodes as images."""
        ids_str = ",".join(node_ids)
        return self.request(f"/images/{file_key}?ids={ids_str}&format={fmt}&scale={scale}")

    def analyze_design(self, file_key: str) -> Dict[str, Any]:
        """Analyze design: extract pages, frames, components."""
        file_data = self.get_file(file_key)

        analysis = {
            "file_name": file_data.get("name"),
            "version": file_data.get("version"),
            "last_modified": file_data.get("lastModified"),
            "pages": [],
            "components": [],
            "component_count": 0,
            "frame_count": 0
        }

        # Extract pages and frames
        if "document" in file_data:
            doc = file_data["document"]
            for child in doc.get("children", []):
                if child["type"] == "CANVAS":
                    page_info = {
                        "name": child.get("name"),
                        "frames": []
                    }
                    for frame in child.get("children", []):
                        if frame["type"] == "FRAME":
                            page_info["frames"].append({
                                "name": frame.get("name"),
                                "id": frame.get("id"),
                                "type": frame["type"],
                                "width": frame.get("absoluteBoundingBox", {}).get("width"),
                                "height": frame.get("absoluteBoundingBox", {}).get("height"),
                            })
                            analysis["frame_count"] += 1
                    analysis["pages"].append(page_info)

        # Extract components
        if "components" in file_data:
            analysis["components"] = [
                {"name": comp.get("name"), "key": comp.get("key"), "description": comp.get("description", "")}
                for comp in file_data["components"].values()
            ]
            analysis["component_count"] = len(analysis["components"])

        return analysis


def main():
    parser = argparse.ArgumentParser(description="Figma REST API Client (DexHub)")
    parser.add_argument("--file-key", required=True, help="Figma file key (from URL)")
    parser.add_argument("--analyze", action="store_true", help="Analyze design structure")
    parser.add_argument("--verify", action="store_true", help="Verify token only")
    parser.add_argument("--json", action="store_true", help="Output as JSON")

    args = parser.parse_args()

    token = find_token()
    if not token:
        print("FIGMA_ACCESS_TOKEN not found.")
        print("")
        print("Setup:")
        print("  1. Create token: figma.com > Settings > Security > Personal Access Tokens")
        print("  2. Save to .env:  FIGMA_ACCESS_TOKEN=figd_your_token_here")
        print("  3. Or export:     export FIGMA_ACCESS_TOKEN=figd_your_token_here")
        sys.exit(1)

    try:
        client = FigmaClient(token)

        if args.verify:
            user = client.get_me()
            print(f"Token valid: {user.get('email', 'unknown')}")
            return

        if args.analyze:
            result = client.analyze_design(args.file_key)
            if args.json:
                print(json.dumps(result, indent=2))
            else:
                print(f"\nDesign Analysis: {result['file_name']}")
                print(f"Last Modified: {result['last_modified']}")
                print(f"Pages: {len(result['pages'])}  |  Frames: {result['frame_count']}  |  Components: {result['component_count']}")
                print()
                for page in result['pages']:
                    print(f"  {page['name']} ({len(page['frames'])} frames)")
                    for frame in page['frames']:
                        size = ""
                        if frame.get("width") and frame.get("height"):
                            size = f" [{int(frame['width'])}x{int(frame['height'])}]"
                        print(f"    - {frame['name']}{size}")
                print()
                if result['components']:
                    print(f"Components ({result['component_count']}):")
                    for comp in result['components']:
                        desc = f" — {comp['description']}" if comp['description'] else ""
                        print(f"    - {comp['name']}{desc}")
        else:
            file_data = client.get_file(args.file_key)
            print(f"File: {file_data.get('name')}")
            print(f"Version: {file_data.get('version')}")
            if args.json:
                print(json.dumps(file_data, indent=2))

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
