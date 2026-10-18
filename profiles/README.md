# Profiles

A profile is a set of config fragments for one kind of project. Every repo gets `base`; the installing agent adds the profiles that match the repo's stack, as recorded in `.dev-standard.json` under `profiles`.

| Profile | For | Contents |
|---------|-----|----------|
| [base](base/) | every repo | `.editorconfig`, `lefthook.yml`, `commitlint.config.mjs`, `.vale.ini`, `.github/workflows/standard-ci.yml` |
| [python-api](python-api/) | FastAPI backends | `pyproject.fragment.toml` (ruff, pyright, pytest, coverage), setup guide |
| [react-web](react-web/) | React frontends | `biome.json`, `eslint.config.js`, `tsconfig.strict.json`, setup guide |

`c-embedded` (clang-format, clang-tidy, BARR-C checks) is planned; see `standards/packs/`.

## Merge policy

Profiles are fragments. They are merged into a repo's existing files, never copied over them (INS-003).

1. **File does not exist:** copy the fragment.
2. **File exists, same tool:** merge key by key.
   - Keys the repo does not set: add ours.
   - Keys the repo sets to a different value: keep the repo's value and list the difference in the adoption report. The user decides whether to switch or record a waiver.
   - Lists such as ruff's `select`: add our entries to the repo's; never remove the repo's entries.
3. **The repo uses a different tool for the same job** (for example Prettier instead of Biome, mypy instead of pyright, Husky instead of lefthook): keep the repo's tool, configure it to the same rules where it can, and record the difference in the adoption report. Switching tools is a separate PR, approved by the user.
4. **CI workflows:** add `standard-ci.yml` as a new workflow. Do not edit existing workflows during install. Jobs start in warning mode (`continue-on-error: true`) and are switched to blocking in a later phase (INS-007).
5. **Reformatting:** turning on a formatter for existing code is its own PR, and its commit goes into `.git-blame-ignore-revs` (INS-006).

Mark every block you add with a `dev-standard` comment where the format allows comments, so upgrades can find it.
