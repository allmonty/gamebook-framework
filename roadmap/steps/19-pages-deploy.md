# Step 19: Deploy to GitHub Pages

## Scope
`.github/workflows/pages.yml`: on push to main, build the site and deploy `site/build/`. The owner enables Pages in the repo settings.

## Files
.github/workflows/pages.yml

## Tests
the build runs locally the same way

## Done when
Workflow file reviewed; owner told how to enable Pages.

## Handoff notes
- `.github/workflows/pages.yml`: on push to `main` (or by hand), builds `site/` with Dart 3.13.7 and deploys `site/build/` with the official Pages actions.
- The owner must set Settings > Pages > Source to "GitHub Actions" once. Not done by us (outward-facing).
- The local build runs the same commands and produces about 830 KB (the compiled player is about 200 KB). The build now deletes `main.dart.js.deps`, which lists build-machine paths.
- The site uses relative links only, so it works under the project path (`https://<owner>.github.io/gamebook-framework/`).
