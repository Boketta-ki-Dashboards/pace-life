#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Uses an installed iPhone simulator, never a guessed device name.
simulator_id="$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(v["udid"] for k,vs in d["devices"].items() if "iOS" in k for v in vs if v["name"].startswith("iPhone")))')"
xcodebuild -project PaceLife.xcodeproj -scheme PaceLife \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath DerivedData -resultBundlePath "${RESULT_BUNDLE_PATH:-/tmp/PaceLife-$(date +%s).xcresult}" \
  CODE_SIGNING_ALLOWED=NO test
