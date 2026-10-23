# Contributing

1. Branch from `main` (`feature/…` or `claude/…`). Keep PRs small and limited to one task.
2. Follow CLAUDE.md (boundaries, coding rules, tests). Update docs and CHANGELOG in the
   same PR.
3. CI and Security must be green. A reviewer approves. Squash or merge; never force-push
   `main`.

## Assets and licensing
- Only original work, or assets with a licence that allows commercial use and
  modification. Record each third-party asset in `ASSETS_LICENSES.md` (source, author,
  licence, changes) in the PR that adds it.
- Never add content from commercial games, ROMs or disassemblies, or from repos without a
  licence (see docs/REPOSITORY_AUDIT.md).
- Code adapted from MIT projects keeps its copyright notice.

## Upgrades
- **Godot:** change `GODOT_VERSION` and both SHA-512 lines in `tools/ci/install-godot.sh`
  (from the release's `SHA512-SUMS.txt`), update `config/features` and docs, open the
  project headless, run all tests and the web smoke test, and review the engine changelog
  for web-export changes.
- **Node.js:** check the release schedule and advisories (SECURITY.md); update `.nvmrc`,
  the Dockerfile tag, `engines` and `@types/node`; run CI; deploy to staging first.
- **npm packages:** exact versions in `package.json`, regenerate the lockfile with
  `npm install`, read the changelogs, run CI. Avoid new dependencies unless they are
  justified in the PR.
- **Actions:** pin by full commit SHA with the version in a comment.
