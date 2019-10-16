#!/usr/bin/env bash

set -e

TEMP=$(getopt -o f:c: -- "$@")
eval set -- "$TEMP"

while true; do
  case "$1" in
  -f)
    asm=$2
    shift 2
    ;;
  -c)
    count=$2
    shift 2
    ;;
  --)
    shift
    break
    ;;
  *)
    echo "Internal error!"
    exit 1
    ;;
  esac
done

if [ -z "$asm" ]; then
  echo "you must specify assembly file name with -f"
  exit 1
fi

if [ "${asm##*.}" != "asm" ]; then
  echo "assembly file should be *.asm"
  exit 1
fi

if [ ! -f "$asm" ]; then
  echo "assembly file '$asm' dose not exist"
  exit 1
fi

[ -z "$count" ] && count=1
filename=${asm%%.*}
[ -z "$bin" ] && bin="$filename.bin"
[ -z "$img" ] && img="$filename.img"

if [ ! -f "$img" ]; then
  bximage -mode=create -imgmode=flat -hd=10M -q "$img"
fi

nasm -f bin -o "$bin" "$asm"
dd if="$bin" of="$img" bs=512 count=$count conv=notrunc
export BX_MBR="$img"
bochs -f bochsrc -q
