# Scan corrections and evidence boundary

The Home shortcut previously only changed tabs and lacked a full-label hit shape. It now opens the Clean Up root and starts or resumes an idle scan. An existing active scan is not paused by opening it.

Live Photos were excluded from visual grouping even though Pearl already had their still-image fingerprints. Stills now participate; motion is not compared, and multi-resource Live/RAW/edited assets are still excluded from byte-exact claims.

The previous last-32 insertion list forgot recent neighbors after a newest-first cache rebuild. Bounded date buckets now retain nearby candidates across rebuilds; photo/video bands are separate; eight 8-bit bands catch small hash changes previously spread across all four old bands. Every retrieved candidate still passes the unchanged Vision threshold and complete-link group checks. Exact duplicates still require equal original bytes.

Matching revision 2 rechecks older comparisons without discarding valid cached fingerprints/digests. Recheck all matches does the same on demand. Review decisions remain separate. New/reused work, limited Photos access, unreadable previews and failed original verification are distinguishable. Avoiding a second current-fingerprint disk read removes redundant work; no real-device speedup number is claimed.

## Investigated failure

Initial build `6aefe56a24e1ec2375575ff2` passed 20 core checks and all eight app-flow tests, including the Home edge tap and exact-copy fixture. Its new simulator Vision accuracy assertions failed, so no IPA was produced. Diagnostic run `6aefe85824e1ec2375576088` showed the same almost-constant distances with original/reencoded/unrelated inputs, archived observations, software-normalized RGB images, and CPU or automatic device selection. Inputs had different bytes. This prevents treating that simulator as a valid inference-quality benchmark.

The same production helper source on the native cloud Mac, run `6aefe9eb24e1ec23755760de`, separated unrelated fixtures at distance 0.7183051, matching an independent Euclidean-distance calculation. `scripts/vision_native_check.py` now retains the positive and negative accuracy checks on native macOS using production helper/rule source; the iOS target checks archive fidelity and the UI flows. Thresholds were not loosened to turn the simulator failure green. Final validation results belong in the current settings validation report.

## Next useful work

Build a labeled, privacy-preserving test corpus of true copies, adjacent shots, crops, edits and unrelated images before changing sensitivity. Add crop/edited-video candidate retrieval only with measured false-positive and missed-match rates. Benchmark cold/warm 10,000-item scans on an iPhone, including iCloud availability, heat, interruption and resume. These are future work, not claims made by this patch.
