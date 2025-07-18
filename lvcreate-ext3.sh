#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function lvcreate_ext3 () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m "$BASH_SOURCE")"
  [ "$USER" == root ] || exec sudo -E "$SELFFILE" "$@" || return $?
  local DBGLV="${DEBUGLEVEL:-0}"

  local LVM_HOST="$LVM_HOST"
  [ -n "$LVM_HOST" ] || LVM_HOST="$HOSTNAME"
  local LVM_VG="vg_${LVM_HOST}_luks"
  vgs --noheadings --options vg_name | sed -re 's~^\s+~~;s~\s+$~~' \
    | grep -qxFe "$LVM_VG" || return 3$(
    echo "E: Volume group '$LVM_VG' not found. Try setting LVM_HOST." >&2)

  local LABEL="${LVM_HOST}_$1"; shift
  local SIZE="$1"; shift
  local CMD=(
    lvm lvcreate
    --size "$SIZE"
    --activate y
    # --contiguous y
    --name "$LABEL"
    "$LVM_VG"
    )
  [ "$DBGLV" -lt 2 ] || echo "D: run: ${CMD[*]}" >&2
  "${CMD[@]}" || return $?

  CMD=(
    mkfs.ext3
    -L "$LABEL"
    -m 1
    /dev/mapper/"$LVM_VG"-"$LABEL"
    )
  [ "$DBGLV" -lt 2 ] || echo "D: run: ${CMD[*]}" >&2
  "${CMD[@]}" || return $?
}










lvcreate_ext3 "$@"; exit $?
