#!/usr/bin/env bash

TEMP=$(getopt -o '' -l asm:,bin:,img: -- "$@")
eval set -- "$TEMP"

while true; do
  case "$1" in
  --asm)
    asm=$2
    shift 2
    ;;
  --bin)
    bin=$2
    shift 2
    ;;
  --img)
    img=$2
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

if [ -n "$asm" ]; then
  filename=$(basename "$asm" .asm)
else
  filename="5-1"
fi
[ -z "$asm" ] && asm="$filename.asm"
[ -z "$bin" ] && bin="$filename.bin"
[ -z "$img" ] && img="$filename.img"

if [ ! -f "$img" ]; then
  bximage -mode=create -fd=160k -q "$img"
fi

nasm -f bin -o "$bin" "$asm"
dd if="$bin" of="$img" bs=512 count=1 conv=notrunc
export BX_MBR="$img"
bochs -f bochsrc -q
