#!/usr/bin/env python3
"""Read-only transfer of explicitly named, genuine XCTAttachment PNGs.

No image manipulation and no repository write token. The recipient verifies
SHA-256, reviews the PNGs, then commits the selected files through normal Git.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import re
import urllib.request

REPOSITORY = "Boketta-ki-Dashboards/pace-life"
ALLOWED_NAMES = {
    "pace-today-light", "pace-today-dark", "pace-modes-light", "pace-paths-light",
    "pace-adaptive-light", "pace-chapters-detail-light", "pace-experiments-detail-light",
    "pace-circle-challenge-light", "pace-profile-light", "pace-profile-dark",
    "pace-profile-accessibility-xxxl-light",
    "pace-dashboard-light", "pace-dashboard-scrolled-light", "pace-dashboard-bottom-light",
    "pace-dashboard-edit-light", "pace-dashboard-dark", "pace-statistics-light", "pace-calendar-light",
    "pace-path-detail-light", "pace-profile-seeded-dark", "pace-circles-light", "pace-circles-dark",
    "pace-development-light", "pace-development-dark", "pace-chapters-light", "pace-chapters-dark",
    "pace-experiments-light", "pace-experiments-dark", "pace-paths-dark", "pace-modes-dark", "pace-adaptive-dark",
}


def read_request(path):
    request = json.loads(Path(path).read_text())
    assert type(request["run_id"]) is int and request["run_id"] > 0
    assert re.fullmatch(r"[0-9a-f]{40}", request["source_commit"])
    assert request["artifact_name"] in {"ios-evidence-macos-15", "ios-evidence-macos-15-intel"}
    assert request["screenshots"] and len(request["screenshots"]) == len(set(request["screenshots"]))
    assert set(request["screenshots"]) <= ALLOWED_NAMES
    return request


def verify_run(request, output):
    assert os.environ["GITHUB_REPOSITORY"] == REPOSITORY
    url = f"https://api.github.com/repos/{REPOSITORY}/actions/runs/{request['run_id']}"
    query = urllib.request.Request(url, headers={
        "Authorization": "Bearer " + os.environ["GH_TOKEN"],
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
    })
    with urllib.request.urlopen(query, timeout=30) as response:
        run = json.load(response)
    assert run["head_sha"] == request["source_commit"], "Source commit mismatch"
    assert run["head_branch"] == "codex/pace-life-offline-beta"
    assert run["repository"]["full_name"] == REPOSITORY
    with Path(output).open("a") as stream:
        stream.write(f"run_id={request['run_id']}\nartifact_name={request['artifact_name']}\n")
    print("Verified source", request["source_commit"], "in", REPOSITORY)


def dictionaries(value):
    if isinstance(value, dict):
        yield value
        for child in value.values():
            yield from dictionaries(child)
    elif isinstance(value, list):
        for child in value:
            yield from dictionaries(child)


def export_images(request, directory):
    root = Path(directory).resolve()
    wanted = set(request["screenshots"])
    found = {}
    manifests = list(root.rglob("manifest.json"))
    for manifest in manifests:
        # Prefer the complete suite, not a duplicate from an early regression.
        if "test-without-building" not in str(manifest):
            continue
        payload = json.loads(manifest.read_text())
        for entry in dictionaries(payload):
            strings = [value for value in entry.values() if isinstance(value, str)]
            filenames = [value for value in strings if value.lower().endswith(".png")]
            for name in wanted:
                if not any(re.search(re.escape(name) + r"(?:\.png|$|[^a-z-])", value) for value in strings):
                    continue
                for filename in filenames:
                    candidate = (manifest.parent / filename).resolve()
                    if candidate.is_relative_to(root) and candidate.is_file():
                        found.setdefault(name, candidate)
    missing = wanted - found.keys()
    if missing:
        # Only generated test metadata; never inspect unrelated files.
        print("Missing named captures:", sorted(missing))
        for manifest in manifests[:2]:
            print("Manifest:", manifest.relative_to(root))
            print(manifest.read_text()[:4000])
        raise SystemExit("Named XCTAttachment selection failed")
    for name in request["screenshots"]:
        data = found[name].read_bytes()
        assert data.startswith(b"\x89PNG\r\n\x1a\n") and 0 < len(data) <= 2 * 1024 * 1024
        metadata = {"name": name + ".png", "bytes": len(data),
                    "sha256": hashlib.sha256(data).hexdigest(),
                    "source_commit": request["source_commit"], "run_id": request["run_id"]}
        print("PACE_IMAGE_BEGIN " + json.dumps(metadata, sort_keys=True))
        encoded = base64.b64encode(data).decode("ascii")
        for offset in range(0, len(encoded), 4096):
            print("PACE_IMAGE_CHUNK " + encoded[offset:offset + 4096])
        print("PACE_IMAGE_END")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--request", required=True)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--github-output")
    mode.add_argument("--artifacts")
    args = parser.parse_args()
    request = read_request(args.request)
    if args.github_output:
        verify_run(request, args.github_output)
    else:
        export_images(request, args.artifacts)
