Release notes for GitHub releases.

- `release-notes/vX.Y.Z.md`: the GitHub release's notes for tag `vX.Y.Z`,
  passed to `gh release create` with `--notes-file`. `scripts/build-dmg-signed.sh`
  prints the command once the build is notarized.
