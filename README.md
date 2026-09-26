# rust-automated-cicd-template

A Rust project template with automated CI, dependency updates, versioning and releases.
The workflows find the crate via `cargo metadata`, so none of them name it.

## Workflows

| Workflow | What it does |
|---|---|
| `build.yml`, `test.yml`, `clippy.yml`, `fmt.yml`, `cargo-deny.yml` | Checks on every PR and push. PRs that touch no relevant files report the checks as passed. |
| `ci.yml` | Checks the crate on its MSRV (`rust-version` in `Cargo.toml`). |
| `coverage.yml` | Line coverage gate (`COVERAGE_MIN` variable, default 0). |
| `semver.yml` | Works out the release a PR needs (with `cargo-semver-checks` for libraries, a patch release for binaries) and pushes the version bump to the PR. |
| `release.yml` | On every push to the default branch: tags a new version, calls `publish.yml` and `changelog.yml`, then brings open Dependabot and auto-merge PRs up to date. |
| `publish.yml` | Publishes to crates.io (skipped without `CARGO_REGISTRY_TOKEN`). |
| `changelog.yml` | Creates the GitHub release and opens an auto-merging PR that updates `CHANGELOG.md`. |
| `dependabot-auto-merge.yml` | Enables auto-merge on Dependabot PRs (`.github/dependabot.yml` groups minor/patch and major updates). |

## Setup

Repository settings:

- Enable **Allow auto-merge**.
- Import `.github/rulessets/main_master_default.json` as a branch ruleset.

Secrets (all optional, but without a bot app or `RELEASE_TOKEN` pushes made by the workflows
don't trigger CI, so auto-merge PRs stall):

| Secret | Used for |
|---|---|
| `BOT_CLIENT_ID`, `BOT_PRIVATE_KEY` | GitHub App that pushes version bumps, opens changelog PRs and enables auto-merge. |
| `RELEASE_TOKEN` | Fallback for the app, and required for `@dependabot rebase` comments (Dependabot ignores apps). |
| `CARGO_REGISTRY_TOKEN` | Publishing to crates.io. |

Variables:

| Variable | Used for |
|---|---|
| `CRATE` | Crate to release in a workspace without a root package and with several members. |
| `COVERAGE_MIN` | Minimum line coverage in percent. |

### Creating the bot secrets

Add secrets under **Settings > Secrets and variables > Actions**. Semver runs on Dependabot PRs
only see **Dependabot** secrets, so add the bot secrets there as well if version bumps should be
pushed to Dependabot PRs.

**GitHub App (`BOT_CLIENT_ID`, `BOT_PRIVATE_KEY`)**

1. Go to **Settings > Developer settings > GitHub Apps > New GitHub App** (your account or the organization).
2. Give it any name and homepage URL, and untick **Webhook > Active**.
3. Under **Repository permissions** set **Contents**, **Pull requests** and **Workflows** to *Read and write*.
   Workflows is only needed to update PR branches that change files in `.github/workflows`.
4. Create the app, then copy the **Client ID** from its settings page into `BOT_CLIENT_ID`.
5. Under **Private keys** click **Generate a private key** and paste the whole downloaded `.pem`
   file (including the `BEGIN`/`END` lines) into `BOT_PRIVATE_KEY`.
6. Click **Install App** and install it on this repository.

**Personal access token (`RELEASE_TOKEN`)**

1. Go to **Settings > Developer settings > Personal access tokens > Fine-grained tokens > Generate new token**.
2. Under **Repository access** choose **Only select repositories** and pick this repository.
3. Set **Contents**, **Pull requests** and **Workflows** to *Read and write*.
4. Save the token as `RELEASE_TOKEN`, and renew it before it expires.

The token acts as your account, so actions it takes (such as `@dependabot rebase` comments) show up
under your name. With the app configured it is only used for those Dependabot comments.
