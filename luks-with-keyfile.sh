#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function luks_with_keyfile () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  local SELFFILE="$(readlink -m -- "$BASH_SOURCE")"
  local SELFPATH="$(dirname -- "$SELFFILE")"
  [ "$USER" == root ] || exec sudo -E "$SELFFILE" "$@" || return $?

  # cd -- "$SELFPATH" || return $?
  local DBGLV="${DEBUGLEVEL:-0}"

  local KEY="$1"; shift
  [ -e "$KEY" ] || [ "${KEY%.}" == "$KEY" ] || KEY+='key'
  [ -e "$KEY" ] || echo "W: Cannot find key file: $KEY" >&2

  local BFN="$(basename -- "$KEY" .key)"
  local LVM_PV="pv_$BFN"
  local LVM_VG="vg_$BFN"

  local CTNR=
  for CTNR in "$BFN"{.luks,.disk,} /dev/disk/by-partlabel/"$BFN"; do
    [ -e "$CTNR" ] && break
  done
  [ -e "$CTNR" ] || echo "W: Cannot find container: $CTNR" >&2

  modprobe xts   # helps avoid "Failed to open temporary keystore device."
  # other modules that might be helpful:
  # aesni_intel
  # aes_{i586,x86_64}

  lwkf_action "$@" || return $?
}


function lwkf_action () {
  local ACTION="$1"; shift
  if [ "$(type -t lwkf_"$ACTION")" == function ]; then
    lwkf_"$ACTION" "$@"
    return $?
  fi

  local CMD=( cryptsetup )
  local OPT=( --key-file="$KEY" )
  case "$ACTION" in

    format )
      ACTION='luksFormat'
      OPT+=(
        --hash=sha512
        --key-size=512
        --cipher=aes-xts-plain64
        -- "$CTNR"
        );;

    open )
      OPT+=(
        --type=luks
        -- "$CTNR" "$LVM_PV"
        );;

  esac
  CMD+=(
    "$ACTION"
    "${OPT[@]}"
    "$@"
    )
  [ "$DBGLV" -lt 2 ] || echo "D: run: ${CMD[*]}" >&2
  "${CMD[@]}" || return $?


  # Some commands (sometimes) require additional steps:
  case "$ACTION" in
    open )
      # Sometimes, cryptsetup seems to forget to activate the VG.
      lvm vgchange --activate y -- "$LVM_VG" || return $?
      ;;
  esac
}


function lwkf_init () {
  lwkf_action format || return $?
  lwkf_action open || return $?
  lvm vgcreate -- "$LVM_VG" /dev/mapper/"$LVM_PV" || return $?
  lvm vgchange --activate y -- "$LVM_VG" || return $?
}


function lwkf_close () {
  local DM_PFX=/dev/mapper/"$LVM_VG"-
  local ITEM= LV_LABEL= MOUNTS=$'\n'"$(mount | sed -re 's~ on .*$~~')"$'\n'
  for ITEM in "$DM_PFX"*; do
    [[ "$MOUNTS" == *$'\n'"$ITEM"$'\n'* ]] || continue
    LV_LABEL="${ITEM:${#DM_PFX}}"
    echo -n "umount $LV_LABEL: "
    umount -- "$ITEM"
  done

  echo -n "deactivate $LVM_VG (early): "
  lvm vgchange --activate n -- "$LVM_VG"

  echo -n 'check for stubborn/stuck disks: '
  sleep 1s
  for ITEM in "$DM_PFX"* ''; do
    [ -b "$ITEM" ] || continue
    LV_LABEL="${ITEM:${#DM_PFX}}"
    if [ "$1" == --force-detach ]; then
      echo "force-detach $LV_LABEL: "
      dmsetup remove -- "$ITEM" || return $?
    else
      echo "found '$LV_LABEL'."
      echo "E: Found stubborn/stuck disk '$LV_LABEL'." \
        "Consider adding the --force-detach option." >&2
      return 4
    fi
  done

  echo -n "deactivate $LVM_VG (again): "
  lvm vgchange --activate n -- "$LVM_VG"
  echo -n "close LUKS: "
  cryptsetup close -- "$LVM_PV" || return $?
  echo "done."
}

















luks_with_keyfile "$@"; exit $?
