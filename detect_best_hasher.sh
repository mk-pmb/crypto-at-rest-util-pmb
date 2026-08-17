#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function detect_best_hasher () {
  local HASH_FAMILY_RANKING='
    b
    sha
    md
    '
  ( cd /usr/bin && (
    set -- $HASH_FAMILY_RANKING
    while [ "$#" -ge 1 ]; do
      # $# works as the strength rank column
      printf -- "$#"'\t%s\n' "$1"[0-9]*sum
      shift
    done
  ) ) | grep -vFe '*' | # Drop unresolved globs
    LANG=C sort --version-sort | # Guarded by glob patterns
    tail --lines=1 | # Only best
    cut -sf 2- # Only command name
}






detect_best_hasher "$@"; exit $?
