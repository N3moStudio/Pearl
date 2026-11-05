"""Verify packaging identity and privacy resources without needing Xcode."""
import hashlib
import json
import pathlib
import plistlib
import struct
import sys
import zipfile

ipa = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(ipa) as archive:
    names = archive.namelist()
    assert all(not n.startswith('/') and '..' not in pathlib.PurePosixPath(n).parts for n in names)
    root = 'Payload/Pearl.app/'
    assert all(n == 'Payload/' or n.startswith(root) for n in names), 'Unexpected payload'
    info = plistlib.loads(archive.read(root + 'Info.plist'))
    assert info['CFBundleIdentifier'] == 'com.n3mostudio.pearl'
    assert info['CFBundleShortVersionString'] == '0.2.1'
    assert info['CFBundleVersion'] == '4'
    assert 'processing' in info['UIBackgroundModes']
    assert info['BGTaskSchedulerPermittedIdentifiers'] == ['com.n3mostudio.pearl.scan.*']
    assert info['MinimumOSVersion'] == '18.0'
    assert info['NSPhotoLibraryUsageDescription']
    assert info['CFBundleIcons']['CFBundlePrimaryIcon']['CFBundleIconName'] == 'AppIcon'
    binary = archive.read(root + info['CFBundleExecutable'])
    magic, cpu = struct.unpack('<II', binary[:8])
    assert magic == 0xfeedfacf and cpu == 0x100000c, 'Expected arm64 Mach-O'
    assert not any('/_CodeSignature/' in n for n in names), 'Expected unsigned payload'
    # No embedded signature command in the app's 64-bit Mach-O executable.
    command_count = struct.unpack_from('<I', binary, 16)[0]
    command_offset = 32
    for _ in range(command_count):
        command, command_size = struct.unpack_from('<II', binary, command_offset)
        assert command_size >= 8 and command_offset + command_size <= len(binary)
        assert command != 0x1d, 'Expected no LC_CODE_SIGNATURE in unsigned executable'
        command_offset += command_size
    notices = archive.read(root + 'OpenSourceNotices.txt').decode()
    assert 'MIT License' in notices and 'Jakub Antalik' in notices
    privacy = plistlib.loads(archive.read(root + 'PrivacyInfo.xcprivacy'))
    assert not privacy['NSPrivacyTracking'] and not privacy['NSPrivacyCollectedDataTypes']
    assert not any(x in n.lower() for n in names for x in ['fixtures/', 'review-v1.json', '.p12', '.mobileprovision', '.git/'])
print(json.dumps({'path': str(ipa.resolve()), 'bytes': ipa.stat().st_size,
                  'sha256': hashlib.sha256(ipa.read_bytes()).hexdigest(),
                  'bundle': info['CFBundleIdentifier'], 'version': info['CFBundleShortVersionString'],
                  'build': info['CFBundleVersion'],
                  'minimum_ios': info['MinimumOSVersion'], 'architecture': 'arm64',
                  'signature': 'unsigned; personal sideload signing required'}, indent=2))
