#!/usr/bin/env bash
# Resolves the package the release workflows act on, so they need no crate name.
#
# Usage: package.sh
# Env:   CRATE (optional) - package name; required in a workspace without a root
#        package that has more than one member. Set it as the `CRATE` repository
#        variable.
# Writes `name`, `version`, `dir` (relative to the repository root, `.` for the
# root package), `manifest`, `rust_version` and `has_lib` to $GITHUB_OUTPUT when
# set, and always to stdout.
set -euo pipefail

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

out() {
    echo "$1=$2"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "$1=$2" >> "$GITHUB_OUTPUT"; fi
}

meta="$(cargo metadata --format-version 1 --no-deps)"
# Workspace members only (path dependencies outside the workspace are excluded).
members="$(jq -c '[.workspace_members as $m | .packages[] | select(.id as $id | $m | index($id))]' <<< "$meta")"
root_manifest="$(jq -r '.workspace_root' <<< "$meta")/Cargo.toml"

if [ -n "${CRATE:-}" ]; then
    pkg="$(jq -c --arg n "$CRATE" 'map(select(.name == $n)) | first // empty' <<< "$members")"
    if [ -z "$pkg" ]; then
        echo "::error::CRATE=$CRATE is not a workspace member." >&2
        exit 1
    fi
else
    # The root package, else the only member.
    pkg="$(jq -c --arg m "$root_manifest" 'map(select(.manifest_path == $m)) | first // empty' <<< "$members")"
    if [ -z "$pkg" ] && [ "$(jq length <<< "$members")" -eq 1 ]; then
        pkg="$(jq -c 'first' <<< "$members")"
    fi
    if [ -z "$pkg" ]; then
        echo "::error::Cannot tell which workspace member to release; set the CRATE repository variable." >&2
        exit 1
    fi
fi

manifest="$(jq -r '.manifest_path' <<< "$pkg")"
manifest="${manifest#"$ROOT"/}"
dir="$(dirname "$manifest")"

out name "$(jq -r '.name' <<< "$pkg")"
out version "$(jq -r '.version' <<< "$pkg")"
out dir "$dir"
out manifest "$manifest"
out rust_version "$(jq -r '.rust_version // ""' <<< "$pkg")"
# cargo-semver-checks can only check library targets.
out has_lib "$(jq -r '[.targets[].kind[]] | any(. == "lib" or . == "rlib" or . == "proc-macro")' <<< "$pkg")"
