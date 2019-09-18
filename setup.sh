#!/usr/bin/env bash

TEMP=$(getopt -o d:f: -l directory:,asm:,bin:,img: -- "$@")
eval set -- "$TEMP"

while true; do
  case "$1" in
  -d|--directory)
    directory=$2
    shift 2
    ;;
  -f|--asm)
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

if [ -z "$directory" ]; then
  echo "you must specify directory with -d or --directory"
  exit 1
fi

if [ -z "$asm" ]; then
  echo "you must specify assembly file name with -f or --asm"
  exit 1
fi

# TODO 验证是否存在$filename.asm

filename=$(basename "$asm" .asm)
[ -z "$asm" ] && asm="$filename.asm"
asm="$directory/$asm"
[ -z "$bin" ] && bin="$filename.bin"
bin="$directory/$bin"
[ -z "$img" ] && img="$filename.img"
img="$directory/$img"

if [ ! -f "$img" ]; then
  bximage -mode=create -fd=160k -q "$img"
fi

nasm -f bin -o "$bin" "$asm"
dd if="$bin" of="$img" bs=512 count=1 conv=notrunc
export BX_MBR="$img"
bochs -f bochsrc -q
