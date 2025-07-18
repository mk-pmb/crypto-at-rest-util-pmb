#!/bin/bash
# -*- coding: utf-8, tab-width: 2 -*-


function openssl_enc_with_keyfile_cli_init () {
  export LANG{,UAGE}=en_US.UTF-8  # make error messages search engine-friendly
  set -o pipefail -o errexit
  local DBGLV="${DEBUGLEVEL:-0}"
  local CIPHER="${OPENSSL_CIPHER:-aes-256-cbc}"
  local KEY_FILE="$1"; shift
  [ -f "$KEY_FILE" ] || return 4$(
    echo E: "Key file seems to not be a regular file: $KEY_FILE" >&2)
  local ENC_CMD=(
    openssl
    enc
    -"$CIPHER"
    -pass file:"$KEY_FILE"
    -pbkdf2
    -salt
    )
  local SRC= MODE= DEST=
  for SRC in "$@"; do
    DEST="$(basename -- "$SRC")"
    case "$SRC" in
      *.enc ) MODE='de'; DEST="${DEST%.*}";;
      * )
        MODE='en'
        # DEST+=".$(printf '%(%d%m%y-%H%M%S)T' -1)-$$"
        DEST+='.enc'
        ;;
    esac
    echo "${MODE^}crypt $DEST <- $SRC:"
    [ ! -f "$DEST" ] || return 4$(
      echo E: "Flinching: Destination exists: $DEST" >&2)
    pv -- "$SRC" | "${ENC_CMD[@]}" -"${MODE:0:1}" -out "$DEST" || return $?
  done
}










openssl_enc_with_keyfile_cli_init "$@"; exit $?
