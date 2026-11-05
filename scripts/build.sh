#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
swift scripts/assets.swift
xcodegen generate
run_build() {
  local log="$1"
  shift
  if ! "$@" > "$log" 2>&1; then
    grep -E -A 5 'error:|failed|FAIL|warning:' "$log" | tail -120 || tail -80 "$log"
    return 1
  fi
  grep -E 'warning:|Executed|TEST SUCCEEDED|BUILD SUCCEEDED' "$log" | tail -20 || true
}
run_build build/device.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Release \
  -destination 'generic/platform=iOS' -derivedDataPath build/DerivedData \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY='' build
app='build/DerivedData/Build/Products/Release-iphoneos/Pearl.app'
test -s "$app/OpenSourceNotices.txt"
test -s "$app/PrivacyInfo.xcprivacy"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
mkdir -p build/package/Payload
ditto "$app" build/package/Payload/Pearl.app
(cd build/package && zip -qry ../Pearl-0.1.0.ipa Payload)
shasum -a 256 build/Pearl-0.1.0.ipa
udid=$(xcrun simctl list devices available -j | python3 -c 'import sys,json; d=json.load(sys.stdin); print(next(v["udid"] for a in d["devices"].values() for v in a if "iPhone" in v["name"]))')
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid" -b
run_build build/simulator.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath build/Simulator build-for-testing
xcrun simctl install "$udid" build/Simulator/Build/Products/Debug-iphonesimulator/Pearl.app
xcrun simctl addmedia "$udid" build/fixtures/*.jpg build/fixtures/*.mov
xcrun simctl privacy "$udid" grant photos com.n3mostudio.pearl
run_build build/ui-tests.log xcodebuild -project Pearl.xcodeproj -scheme Pearl -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath build/Simulator \
  -resultBundlePath build/UI.xcresult test-without-building
xcrun xcresulttool export attachments --path build/UI.xcresult --output-path build/screenshots
