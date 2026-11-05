# Pearl design specification

Selected by the user on November 4, 2026. This is a direction, not a finalized app name.

## Character

Calm, bright, rounded and familiar. The photos provide the visual interest. Warm white surfaces, deep readable text, one restrained sage accent, gentle depth and broad spacing keep large libraries from feeling like a dense control panel.

The user explicitly wants textured loading placeholders and orbs. Keep those elements purposeful and small; do not remove them solely because another design guide dislikes decorative effects.

## Structure

- Three main destinations: Library, Clean Up, Albums.
- Library begins with a Continue card, media entries and year/month browsing.
- Clean Up contains a short ordered list of available categories, with progressive scan results.
- Pushed review screens focus on the photo, selection and next action.
- Advanced filters, preferences and less frequent actions are disclosed inside sheets or menus.
- One prominent action per task; secondary controls remain easy to discover.

## Visual rules

- Use native system typography for controls and readable hierarchy, with Dynamic Type.
- Prefer continuous rounded rectangles, consistent inset spacing and ordinary system symbols.
- Keep regular text approximately at native body size; final tokens must scale rather than hard-code the mockup's pixels.
- Treat the illustrated sage/ivory colors as references. Choose semantic adaptive colors and verify actual contrast in implementation.
- Use true native Liquid Glass where available for navigation and floating controls. Keep photo grids, text and content containers crisp. This follows [Apple's material guidance](https://developer.apple.com/design/human-interface-guidelines/materials).
- Let the system's appearance, Reduce Transparency and Increase Contrast preferences work. Include a designed dark appearance even though the selected reference is light.
- Keep touch targets comfortable and provide labels for icon-only controls.

## Loading texture

The proposed interpretation of “pre-loading texture” is a very fine pearl-grain placeholder and restrained shimmer on unloaded thumbnails. Match the dimensions of the actual content so the layout does not jump. Do not animate text or hold completed content to show an effect. Cached images should appear immediately.

Show existing content during new scans. Separate thumbnail loading, similarity analysis, iCloud download and export as distinct states. Long operations need meaningful status and cancellation; a spinner or orb alone is insufficient.

## Thinking Orbs

Reference: [native ThinkingOrbsKit](https://github.com/Jakubantalik/Libraries.dev/tree/54722cc9a3dcb167037f7d449d6cca4d174e9eb5/packages/thinking-orbs/ports/ios/ThinkingOrbsKit), previously integrated into Elsepin.

Use a small particle orb beside real status text such as “Finding similar photos…” or “Loading preview…”. Match the accent and scale with accessibility text. It is not a giant hero object and must not pretend that a task is still working after completion.

Motion stops under Reduce Motion, Low Power Mode, an inactive scene or offscreen state. A static symbol and the same status text remain. The visual must never own or restart the scan. Hide decorative particles from accessibility so the status is spoken only once.

## Similarity screen

Show the candidate group, an overridable Suggested keeper label, measured reasons and easy comparison. Do not preselect removals. The final control becomes actionable only after the person has a valid selection; the generated image illustrates layout, not enabled/disabled behavior. Keep all and dismiss/protect are first-class choices.

Use ordinary terms: “Exact duplicates”, “Similar photos”, “Possible similar videos”. Avoid confidence percentages unless there is a calibrated, comprehensible basis. A model score is not automatically a probability.

## Assets and limits

- `directions.png`: initial Pearl / Mist / Ink exploration.
- `pearl-similarity.png`: selected Pearl library, cleanup and comparison flow.
- Both were generated with the built-in image-generation tool from the prompts in `PROMPTS.md`.
- All photos/counts are illustrative; no personal library was accessed.
- Screenshots do not prove responsiveness, motion quality, actual Liquid Glass behavior, contrast, VoiceOver, thumbnail accuracy or scanning performance.
