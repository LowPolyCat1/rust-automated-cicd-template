# Stacked Pull Requests

Use stacked pull requests for a feature, per GitHub's guide:
https://docs.github.com/en/pull-requests/how-tos/stacked-pull-requests

Branch each part of the feature off the branch before it, not off `master`. Open a
pull request for each branch, targeted at the branch it came from. The base branch
of the pull request names the dependency; no separate declaration is necessary.

Merge the stack bottom-up. After a pull request merges, retarget the next pull request
in the stack onto `master` (or the new bottom branch). If a lower branch changes,
rebase the branches above it on the new base.

Name each branch per `docs/branch-naming.md`.
