#!/usr/bin/env bash
# Determines the minimum version the released package (see package.sh) needs
# compared to a baseline git revision, and optionally bumps its Cargo.toml to it.
#
# Usage: semver-check.sh <baseline-rev> [--write]
#
# A release is required when any of these differ from the baseline:
#   * <package dir>/src/**
#   * <package dir>/Cargo.toml (ignoring the `version` line)
#   * the resolved normal/build dependency tree of the package (Cargo.lock)
# The bump level (patch/minor/major) comes from cargo-semver-checks. Packages
# without a library target have no public API to check and get a patch release.
#
# Writes `name`, `manifest`, `changed`, `level`, `base`, `current`, `required`,
# `ok`, `bumped` to $GITHUB_OUTPUT when set.
set -euo pipefail

BASE_REV="${1:?usage: semver-check.sh <baseline-rev> [--write]}"
WRITE="${2:-}"
ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"

out() {
    echo "$1=$2"
    if [ -n "${GITHUB_OUTPUT:-}" ]; then echo "$1=$2" >> "$GITHUB_OUTPUT"; fi
}

pkg_version() {
    awk -F'"' '/^\[package\]/{f=1;next} /^\[/{f=0} f && /^version[[:space:]]*=/{print $2; exit}'
}

pkg="$(env -u GITHUB_OUTPUT "$(dirname "$0")/package.sh")"
field() { sed -n "s/^$1=//p" <<< "$pkg"; }
NAME="$(field name)"
DIR="$(field dir)"
MANIFEST="$(field manifest)"
HAS_LIB="$(field has_lib)"
out name "$NAME"
out manifest "$MANIFEST"

dep_tree() {
    cargo tree --manifest-path "$1/$MANIFEST" -p "$NAME" --all-features \
        -e normal,build --prefix none --no-dedupe --format '{p}' \
        | sed -E 's/ \(.*\)$//' | grep -v "^$NAME " | sort -u
}

base_version="$(git show "$BASE_REV:$MANIFEST" | pkg_version)"
current_version="$(field version)"
out base "$base_version"
out current "$current_version"

# 1. Did anything that ends up in the published crate change?
changed=false
reasons=()
if ! git diff --quiet "$BASE_REV" -- "$DIR/src"; then
    changed=true
    reasons+=("$DIR/src changed")
fi
if ! diff -q \
    <(git show "$BASE_REV:$MANIFEST" | grep -Ev '^version[[:space:]]*=') \
    <(grep -Ev '^version[[:space:]]*=' "$MANIFEST") > /dev/null; then
    changed=true
    reasons+=("$MANIFEST changed")
fi

worktree="$(mktemp -d)"
trap 'git worktree remove --force "$worktree" >/dev/null 2>&1 || true' EXIT
git worktree add --detach --quiet "$worktree" "$BASE_REV"
if ! diff -u <(dep_tree "$worktree") <(dep_tree "$ROOT"); then
    changed=true
    reasons+=("resolved dependencies of $NAME changed")
fi

out changed "$changed"
if [ "$changed" = false ]; then
    echo "No changes affecting $NAME; no version bump required."
    out level none
    out required "$base_version"
    out ok true
    out bumped false
    exit 0
fi
printf 'Release required: %s\n' "${reasons[@]}"

# 2. Smallest release type cargo-semver-checks accepts.
if [ "$HAS_LIB" != true ]; then
    echo "$NAME has no library target; a patch release is enough."
    level="patch"
else
    level=major
    for t in patch minor; do
        set +e
        cargo semver-checks -p "$NAME" --baseline-rev "$BASE_REV" --release-type "$t" --all-features
        rc=$?
        set -e
        case "$rc" in
            0) level="$t"; break ;;
            100) ;; # semver violation for this release type, try the next one
            *) echo "cargo-semver-checks failed with exit code $rc" >&2; exit "$rc" ;;
        esac
    done
fi
out level "$level"

# 3. Map the level onto a concrete version (0.x: minor acts as major).
IFS=. read -r maj min pat <<< "$base_version"
case "$maj:$level" in
    0:major) required="0.$((min + 1)).0" ;;
    0:*) required="0.$min.$((pat + 1))" ;;
    *:major) required="$((maj + 1)).0.0" ;;
    *:minor) required="$maj.$((min + 1)).0" ;;
    *:patch) required="$maj.$min.$((pat + 1))" ;;
esac
out required "$required"

# `sort -V` puts the smaller version first.
if [ "$(printf '%s\n%s\n' "$required" "$current_version" | sort -V | head -n1)" = "$required" ]; then
    echo "$NAME $current_version satisfies the required $level release ($required)."
    out ok true
    out bumped false
    exit 0
fi

echo "$NAME $current_version is too low: a $level release requires $required."
out ok false
if [ "$WRITE" = "--write" ]; then
    if ! grep -Eq '^version[[:space:]]*=' "$MANIFEST"; then
        echo "::error file=$MANIFEST::No literal version in $MANIFEST (inherited from the workspace?); bump it to $required by hand." >&2
        exit 1
    fi
    sed -i -E "0,/^version[[:space:]]*=.*/s//version = \"$required\"/" "$MANIFEST"
    cargo update --workspace --quiet
    echo "Bumped $NAME to $required."
    out bumped true
else
    out bumped false
fi
