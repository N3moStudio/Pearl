#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
swift scripts/assets.swift
xcodegen generate
run_build() {
  local log="$1"
  shift
  if pgrep -lx xcodebuild > "${log%.log}-processes.log"; then
    cat "${log%.log}-processes.log"
    echo 'An existing Xcode build needs review before starting another.'
    return 1
  else
    local inventory_status=$?
    [[ "$inventory_status" == 1 ]] || return "$inventory_status"
  fi
  if ! "$@" > "$log" 2>&1; then
    grep -E -A 5 'error:|failed|FAIL|warning:' "$log" | tail -120 || tail -80 "$log"
    return 1
  fi
  grep -E 'warning:|Executed|TEST SUCCEEDED|BUILD SUCCEEDED' "$log" | tail -20 || true
}
udid=$(xcrun simctl list devices available -j | python3 -c 'import sys,json; d=json.load(sys.stdin); print(next(v["udid"] for a in d["devices"].values() for v in a if "iPhone" in v["name"]))')
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid" -b
run_build build/simulator.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath build/Simulator build-for-testing
xcrun simctl install "$udid" build/Simulator/Build/Products/Debug-iphonesimulator/Pearl.app
xcrun simctl addmedia "$udid" build/fixtures/*.jpg build/fixtures/*.mov
xcrun simctl privacy "$udid" grant photos com.n3mostudio.pearl
test_status=0
test_selection=()
if [[ "${PEARL_SCAN_DIAGNOSTICS:-0}" == 1 ]]; then test_selection=(-only-testing:PearlScanTests); fi
run_build build/ui-tests.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath build/Simulator \
  -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
  -resultBundlePath build/UI.xcresult "${test_selection[@]}" test-without-building || test_status=$?
xcrun xcresulttool export attachments --path build/UI.xcresult --output-path build/screenshots
if [[ "${PEARL_SCAN_DIAGNOSTICS:-0}" == 1 ]]; then exit "$test_status"; fi
[[ "$test_status" == 0 ]] || exit "$test_status"
if [[ "${PEARL_VALIDATE_ONLY:-0}" == 1 ]]; then
  runtime=$(xcrun simctl list runtimes -j | python3 -c 'import sys,json; print(next(r["identifier"] for r in json.load(sys.stdin)["runtimes"] if r.get("isAvailable") and "iOS" in r["name"]))')
  narrow=$(xcrun simctl create 'Pearl Narrow' com.apple.CoreSimulator.SimDeviceType.iPhone-SE-3rd-generation "$runtime")
  xcrun simctl shutdown "$udid"
  xcrun simctl boot "$narrow"
  xcrun simctl bootstatus "$narrow" -b
  xcrun simctl install "$narrow" build/Simulator/Build/Products/Debug-iphonesimulator/Pearl.app
  xcrun simctl addmedia "$narrow" build/fixtures/*.jpg build/fixtures/*.mov
  xcrun simctl privacy "$narrow" grant photos com.n3mostudio.pearl
  narrow_status=0
  run_build build/narrow-tests.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Debug \
    -destination "platform=iOS Simulator,id=$narrow" -derivedDataPath build/Simulator \
    -parallel-testing-enabled NO -maximum-concurrent-test-simulator-destinations 1 \
    -only-testing:PearlUITests/PearlUITests/testAppearancePersistsAndKeepsNativeNavigation \
    -only-testing:PearlUITests/PearlUITests/testLargeTextAndDarkAppearance \
    -resultBundlePath build/Narrow.xcresult test-without-building || narrow_status=$?
  xcrun xcresulttool export attachments --path build/Narrow.xcresult --output-path build/screenshots/narrow
  exit "$narrow_status"
fi

# Only produce a deliverable after the simulator checks succeed.
run_build build/device.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
app='build/DerivedData/Build/Products/Release-iphoneos/Pearl.app'
test -s "$app/OpenSourceNotices.txt"
test -s "$app/PrivacyInfo.xcprivacy"
# Remove any linker-generated ad-hoc signature; the user's sideloader signs it.
if codesign -d "$app" >/dev/null 2>&1; then codesign --remove-signature "$app"; fi
if codesign -d "$app" >/dev/null 2>&1; then echo 'Expected an unsigned app'; exit 1; fi
mkdir -p build/package/Payload
ditto "$app" build/package/Payload/Pearl.app
(cd build/package && zip -qry ../Pearl-0.2.3.ipa Payload)
python3 scripts/verify_ipa.py build/Pearl-0.2.3.ipa > build/package-verification.json
cat build/package-verification.json
