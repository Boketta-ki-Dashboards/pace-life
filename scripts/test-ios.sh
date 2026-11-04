#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
action="${1:-test}"
case "$action" in test|build-for-testing|test-without-building|test-navigation|test-regressions) ;; *) echo "Unsupported action: $action" >&2; exit 2;; esac
build_action="$action"
test_arguments=(CODE_SIGNING_ALLOWED=NO)
if [[ "$action" == "test-navigation" || "$action" == "test-regressions" ]]; then
  build_action="test-without-building"
  test_arguments+=(-only-testing:PaceLifeUITests/PaceLifeUITests/testManualPathMilestoneSurvivesRelaunch)
fi
if [[ "$action" == "test-regressions" ]]; then
  test_arguments+=(-only-testing:PaceLifeUITests/PaceLifeUITests/testChapterPhotoPickerCancelImportRemovalAndRelaunch)
fi
simulator_id="${SIMULATOR_ID:-$(xcrun simctl list devices available -j | python3 -c 'import json,sys; d=json.load(sys.stdin); print(next(v["udid"] for k,vs in d["devices"].items() if "iOS" in k for v in vs if v["name"].startswith("iPhone")))')}"
# Wait for the chosen simulator's actual boot before XCTest initializes AX.
# Serial UI execution avoids a second, unprepared cloned simulator.
if [[ "$action" != "build-for-testing" ]]; then
  xcrun simctl bootstatus "$simulator_id" -b
  if [[ "$action" != "test-navigation" ]]; then
    # Explicitly synthetic fixture for native PhotosPicker automation. Never
    # delete or replace the simulator user's existing Photos library.
    xcrun simctl addmedia "$simulator_id" "$PWD/PaceLifeUITests/Fixtures/chapter-photo.png"
  fi
fi
# On either Intel or Apple Silicon, use Xcode's destination-selected architecture.
# Debug ONLY_ACTIVE_ARCH is consistent across the app and its Swift package.
log_file="${RUNNER_TEMP:-/tmp}/pace-ios-${action}.log"
set +e
xcodebuild -project PaceLife.xcodeproj -scheme PaceLife \
  -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath DerivedData -resultBundlePath "${RESULT_BUNDLE_PATH:-/tmp/PaceLife-${action}-$(date +%s).xcresult}" \
  -parallel-testing-enabled NO "${test_arguments[@]}" "$build_action" 2>&1 | tee "$log_file"
result=${PIPESTATUS[0]}
set -e
if [[ -n "${GITHUB_ACTIONS:-}" && "$result" -ne 0 ]]; then
  # Surface actual compiler/test errors even when full logs need a GitHub login.
  python3 - "$log_file" <<'PY'
import sys
from pathlib import Path
lines = Path(sys.argv[1]).read_text(errors='replace').splitlines()
errors = [line for line in lines if ' error:' in line or 'failed -' in line or 'Testing failed:' in line]
for line in errors[:20]:
    escaped = line.replace('%', '%25').replace('\r', '%0D').replace('\n', '%0A')
    print('::error::' + escaped)
PY
fi
exit "$result"
