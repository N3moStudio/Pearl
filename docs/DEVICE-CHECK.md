# First iPhone check

Import `Pearl-0.1.0.ipa` into your usual iOS sideloader and let it sign the app for your Apple account/device. Pearl requires iOS 18 or newer. The build's ad-hoc signature is an integrity signature, not personal provisioning. Keep the bundle ID consistent across upgrades to retain local review choices.

1. Start with a small selected library containing disposable copies. Open Photos, Videos, Screenshots and an older month. Use the grid's Filter menu to combine date and media type.
2. Open a photo; try zoom, Keep, Remove, Undo and Skip. Remove should only add to the review queue. Close and reopen Pearl to confirm saved decisions.
3. Make an item a favorite in Apple Photos. Return to Pearl; it should not remain staged for removal. Protect and unprotect another item in Pearl.
4. Open Clean Up and scan. Compare a same-photo re-export, a different photo, a re-encoded video and a video with different audio. Video suggestions must remain review-only. Five sampled frames cannot establish audio equivalence.
5. Pause a scan, leave the app, or enable Low Power Mode; check that work stops and existing results remain visible. Scan again to reuse cached fingerprints. Verify on your real library before drawing conclusions about speed or battery use.
6. Try a cloud-only photo with downloads off, then enable iCloud downloads explicitly. Missing local resources must be reported rather than silently treated as unique.
7. Create an album, select several photos in a grid and use Add to album. They should remain in the main library.
8. With disposable copies only, stage removal, inspect the final queue, cancel the app confirmation, then cancel Apple's confirmation. The queue should remain. Confirm a separate deletion and verify Photos → Recently Deleted recovery.
9. Check large text, dark appearance, VoiceOver, Reduce Motion and Reduce Transparency on the physical device. Confirm comfortable reading and controls in portrait and landscape.

No personal photos need to be uploaded for debugging. Report the screen, action and error wording; screenshots should use disposable media if shared.
