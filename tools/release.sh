#!/usr/bin/env bash
#
# How does it work:
#
#   1. Will follow the GitLab Flow branching model, if the release branch already exists,
#      `cherry-pick` the latest commit from the default branch to the release branch,
#      otherwise, create a new one before starting the `cherry-pick`.
#      Notice that the release branch naming format will be 'release/<major>.<minor>'
#
#   2. Create a git-tag on the release branch
#
#   3. Build a RubyGems package base on the latest git-tag
#
# Usage:
#
#   Run this script on the default branch.
#
# Requires:
#
#   Git, RubyGems

set -eu

GEM_SPEC="jekyll-theme-chirpy.gemspec"

DEFAULT_BRANCH="master"

_working_branch="$(git branch --show-current)"

## Check git status
check_status() {
  if [[ -n $(git status . -s) ]]; then
    echo "➜ Error: Commit unstaged files first, and then run this tool againt."
    exit -1
  fi

  if [[ $_working_branch != $DEFAULT_BRANCH && $opt_manual == "false" ]]; then
    echo "➜ Error: This operation must be performed on the '$DEFAULT_BRANCH' branch!"
    exit -1
  fi
}

relase() {

  # Read the version number from config file
  _version="$(grep "spec.version" jekyll-theme-chirpy.gemspec | sed 's/.* //;s/"//g')"

  _major=""
  _minor=""
  _patch=""

  IFS='.' read -r -a array <<< "$_version"

  for elem in "${array[@]}"; do
    if [[ -z $_major ]]; then
      _major="$elem"
    elif [[ -z $_minor ]]; then
      _minor="$elem"
    elif [[ -z $_patch ]]; then
      _patch="$elem"
    else
      break
    fi
  done

  _release_branch="release/$_major.$_minor"

  # Pass the latest commit to the release branch

  if [[ -z $(git branch -v | grep "$_release_branch") ]]; then
    # create a new target branch
    git checkout -b "$_release_branch"
  else
    # cherry-pick the latest commit from default branch to release branch
    _last_commit="$(git rev-parse $DEFAULT_BRANCH)"
    git checkout "$_release_branch"
    git cherry-pick "$_last_commit" -m 1
  fi

  ## Create a new tag

  git tag "v$_version"
  echo -e "➜ Create tag v$_version\n"

  ## Build gem package

  rm -f ./*.gem
  gem build "$GEM_SPEC"
  echo -e "➜ Build the gem pakcage for v$_version\n"

}

main() {
  check_status
  relase
}

main
