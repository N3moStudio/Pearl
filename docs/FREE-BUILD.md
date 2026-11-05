# Private builds and free usage

Pearl stays private. Open **Actions → Build Pearl → Run workflow** on `main`, leave **Run core tests only** unchecked, then download the **Pearl** artifact after a successful run. The artifact contains `Pearl-0.2.1.ipa`, saved logs, test results and simulator screenshots. Re-sign the IPA using your existing personal sideload workflow; no paid Apple certificate is needed to produce this unsigned/personal-signing build.

The workflow uses the standard Apple Silicon `macos-26` runner and keeps artifacts for three days. It uses the repository owner's included private-repository allowance. This is free only while that allowance remains and the account is eligible to run jobs. The previous `xcode-27` label was also a standard runner; changing labels does not fix an account billing block. No spending limits, payment methods or repository visibility are changed by this project.

Deleting old workflow runs removes their logs/artifacts and can reduce future storage use. It does not restore consumed minutes or erase already accrued charges. At the user's request, all 14 previous Pearl runs were deleted before the new 0.2.1 build attempt. The previous downloaded 0.2.0 IPA and local verification evidence were retained.

If GitHub blocks hosted jobs, a Mac you already have can run `swift test` and `bash scripts/build.sh` locally with Xcode 26 or newer and XcodeGen installed. A private, trusted self-hosted Mac runner also avoids GitHub-hosted compute charges. Windows alone cannot compile this native iOS app. There is no promise of unlimited free private macOS hosting and no public-repository workaround here.

Sources checked November 4, 2026:
- [GitHub Actions billing and included allowances](https://docs.github.com/en/billing/concepts/product-billing/github-actions)
- [Standard runner images and labels](https://github.com/actions/runner-images)
- [Self-hosted runners](https://docs.github.com/en/actions/concepts/runners/self-hosted-runners)

## Preview changes in 0.2.1

- Keep a low-resolution poster while the larger preview loads and through favorite/metadata changes.
- Keep the poster over AVKit until `isReadyForDisplay` confirms a video frame exists.
- Cancel media loads when leaving or skipping; ignore callbacks from a discarded player.
- Bound video download and first-frame waits, with retry/cancel/iCloud options.
- Move the protection context menu to the heart button so it does not compete with photo dragging.
- Preserve the final large-text, home gradient and large-library filmstrip improvements already on main.
- Add colored-fixture screenshot assertions around partial swipes, favorite changes and filmstrip jumps; add explicit video poster/playback/navigation coverage. These checks must pass on a Mac before claiming the preview fix is verified.

Apple reference: [AVPlayerViewController.isReadyForDisplay](https://developer.apple.com/documentation/avkit/avplayerviewcontroller/isreadyfordisplay).
