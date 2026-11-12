# Releasing

Releases are hands-free: push a version tag and GitHub builds the zip and uploads it to CurseForge.

Before tagging, `CHANGELOG.md` needs a section for the version (`## v0.9.0`): that section is the
release's notes. Preview them with `python tools/release_notes.py v0.9.0`.

```
git tag v0.9.0
git push origin v0.9.0
```

The workflow in `.github/workflows/release.yml` first writes `RELEASE_NOTES.html` from the tag's
`CHANGELOG.md` section (`tools/release_notes.py`; the job fails if there is no section), then runs
the BigWigsMods packager, which:
- fills `@project-version@` in the .toc files with the tag (e.g. `v0.9.0`),
- zips the addon as `LevelingCodex/` (leaving out README, media and these docs),
- uploads it to the CurseForge project in `## X-Curse-Project-ID` with those notes (HTML: only this
  version's section, so CurseForge doesn't show the whole changelog run together),
- creates a GitHub release with the same zip.

## One-time setup
1. Put the CurseForge project ID into `## X-Curse-Project-ID` in both .toc files.
2. Create a CurseForge API token (CurseForge > My Profile > API Tokens) and add it to this repository as the secret `CF_API_KEY` (Settings > Secrets and variables > Actions > New repository secret).
3. If the first upload fails because CurseForge doesn't recognise interface 16001, add a repository variable `FOREVER_GAME_VERSION` with the game version label CurseForge lists for Forever, then re-run the workflow.

Tags containing `alpha` or `beta` (e.g. `v0.9.0-beta`) are uploaded to CurseForge as alpha/beta files.
