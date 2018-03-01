# Shows local and remote git branches, in order of recency,
# allows one to be selected, which will then be checked out
#
# Parameters:
# - initial query text (optional)
#
# Requirements:
# - the current directory must be a git repository
#
# Assumptions:
# - the primary remote is called "origin"
#
# Compatibility:
# - Only tested on macOS
# - Perhaps the `awk` command is not portable
b() {
  local branches branch

  # Get references (branches, tags), ordered by descending commit date,
  # showing only the name (not the commit hash or type); remove HEAD;
  # remove "origin/" prefix; remove duplicate entries (i.e. local vs remote)
  branches=$(git for-each-ref --sort=-committerdate --format="%(refname:short)" \
             refs/heads refs/remotes/origin --sort=-committerdate \
             | grep -v origin/HEAD | sed 's#origin/##' | awk '!x[$0]++')

  # Search branches with fzf, return immediately if there are no results, or
  # exactly one result. Where there are multiple matches for the same query,
  # the recency of the branch takes precedence; then check out that branch
  branch=$(echo "$branches" | fzf -0 -1 --query="$*" --tiebreak=index) && \
    git checkout "$branch"
}
