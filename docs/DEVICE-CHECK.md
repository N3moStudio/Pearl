# First iPhone check

Import `Pearl-0.2.1.ipa` into your usual iOS sideloader and let it sign the app for your Apple account/device. Pearl requires iOS 18 or newer. Build 4 is unsigned and needs personal signing/provisioning. Keep the bundle ID consistent across upgrades to retain local review choices.

1. Start with a small selected library containing disposable copies. Open Photos, Videos, Screenshots and an older month. Use the grid's Filter menu to combine date and media type.
2. Open a photo; try zoom, Delete, Heart, Keep, Undo, partial/reversed drags and the thumbnail filmstrip. Open Swipe, select a month, and confirm its title/count/percentage. Close only with the top-left button. Remove should only add to the review queue. Close and reopen Pearl to confirm saved decisions.
3. Use the center heart to make an item a favorite; verify it in Apple Photos. Return to Pearl; it should not remain staged for removal. Protect and unprotect another item in Pearl.
4. Open Clean Up and scan. Compare a same-photo re-export, a different photo, a re-encoded video and a video with different audio. Video suggestions must remain review-only. Five sampled frames cannot establish audio equivalence.
5. On iOS 26+, begin a scan, switch Pearl tabs, leave for another app, then lock the phone. Check the system Live Activity against in-app progress and cancel from it. Resume and confirm completed work is reused. Force-quit/relaunch and check saved recovery. On iOS 18–25 or when background execution is unavailable, leaving should save and pause. Test Low Power Mode and heat interruption. Time cold and warm scans on a 10,000+ item library and observe memory/battery; simulator tests do not establish these results.
6. Try a cloud-only photo and video with downloads off, then enable iCloud downloads explicitly. The poster should stay visible until a playable frame is ready. Try cancel/retry during loading, rapid filmstrip changes, and favoriting a visible photo. Missing local resources must be reported rather than silently treated as unique.
7. Create an album, select several photos in a grid and use Add to album. They should remain in the main library.
8. With disposable copies only, stage removal, inspect the final queue, cancel the app confirmation, then cancel Apple's confirmation. The queue should remain. Confirm a separate deletion and verify Photos → Recently Deleted recovery.
9. Check large text, dark appearance, VoiceOver, Reduce Motion and Reduce Transparency on the physical device. Confirm comfortable reading and controls in portrait and landscape.

No personal photos need to be uploaded for debugging. Report the screen, action and error wording; screenshots should use disposable media if shared.
