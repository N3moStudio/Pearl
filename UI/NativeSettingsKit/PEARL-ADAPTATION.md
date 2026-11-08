# Pearl integration

This repository's copy retains the kit documents, source, examples (not linked into Pearl), tests and notices. The original shared folder and other apps are unchanged.

Small host extensions: `NSKPalette` exposes its seven-token initializer and conforms to Sendable; an optional environment palette override lets Pearl keep sage/ivory without relabeling another kit theme. List/row/card/floating components read that resolved palette. Decorative row symbols are contained in a 20pt image inside their 32pt slot at maximum accessibility sizes.

Pearl owns its appearance persistence and its nine-choice theme screen (Pearl plus the eight kit themes). No storage or runtime services were added to the kit. Its example product is not a shipping dependency. Native evidence belongs to Pearl's validation report, not the copied kit's historical Windows-only validation result.

The host resolves the selected palette for both the app root and open presentations. Settings and queue sheets apply their own preferred color scheme without changing view identity. This avoids mixed light surfaces/dark controls when a theme changes in an already-open sheet; the kit itself still owns no window or persisted state.
