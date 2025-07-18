#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function lvs_diskfree_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  # local SELFPATH="$(dirname -- "$SELFFILE")"
  [ "$(whoami)" == root ] || exec sudo "$SELFFILE" "$@" || return $?
  [ "$#" -ge 1 ] || set -- /dev/vg_*/*

  # NB: Using stat --file-system would give info about the devtmpfs in
  #     which the block device resides in, rather than info about the
  #     file system stored _inside_ the block device.

  local DISK= KEY= VAL=
  local DATA_COLS=( fs {used,free,size}_mb disk )
  printf -v VAL -- '\t%s' "${DATA_COLS[@]}"
  echo "# ${VAL:1}"
  local BYTES_PER_MB=$(( 1024 ** 2 ))
  local -A DICT=()
  for DISK in "$@"; do
    [ -b "$DISK" ] || continue$(echo W: "not a block device: $DISK" >&2)
    VAL="$(file --dereference --special-files --brief -- "$DISK")"
    DICT=()
    case "$VAL" in

      *' ext'[234]' '* )
        VAL='
          s~_*:_*([0-9]+)$~\n\1~
          s~^([a-z_]+)_blocks?\n~block_\1\n~
          s~^blocks?_([a-z_]+)\n~[blk_\1]=~ip
          '
        VAL="$(LANG=C tune2fs -l -- "$DISK" | tr A-Z' ' a-z_ |
          sed -nre "${VAL//$'\n'/;}")"
        eval "DICT=( $VAL [fs]=ext2 )"
        ;;

      * )
        echo W: "Unsupported file system type '$FS_TYPE' on disk '$DISK'" >&2
        continue;;
    esac
    [ -n "${DICT[blk_total]}" ] || DICT[blk_total]="${DICT[blk_count]}"
    unset DICT[blk_count]
    if [ -n "${DICT[blk_used]}" ]; then
      (( DICT[blk_free] = DICT[blk_total] - DICT[blk_used] ))
    elif [ -n "${DICT[blk_free]}" ]; then
      (( DICT[blk_used] = DICT[blk_total] - DICT[blk_free] ))
    fi
    let DICT[free_mb]="${DICT[blk_free]} * ${DICT[blk_size]} / $BYTES_PER_MB"
    let DICT[used_mb]="${DICT[blk_used]} * ${DICT[blk_size]} / $BYTES_PER_MB"
    let DICT[size_mb]="${DICT[blk_total]} * ${DICT[blk_size]} / $BYTES_PER_MB"
    DICT[disk]="$DISK"
    VAL=
    for KEY in "${DATA_COLS[@]}"; do VAL+=$'\t'"${DICT[$KEY]}"; done
    echo "${VAL:1}"
  done
}










lvs_diskfree_cli_init "$@"; exit $?
