#!/usr/bin/env bash

set -e

TEMP=$(getopt -o m:p: -l mbr:,program: -- "$@")
eval set -- "$TEMP"

while true; do
  case "$1" in
  -m|--mbr)
    mbr=$2
    shift 2
    ;;
  -p|--program)
    program=$2
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

if [[ -z "$mbr" ]]; then
  echo "you must specify mbr file name with -m or --mbr"
  exit 1
fi

if [[ "${mbr##*.}" != "asm" || (-n "$program" && "${program##*.}" != "asm") ]]; then
  echo "assembly file should be *.asm"
  exit 1
fi

if [[ ! -f "$mbr" || (-n "$program" && ! -f "$program") ]]; then
  echo "'$mbr' or '$program' dose not exist"
  exit 1
fi

# 创建img文件
mbrname=${mbr%%.*}
img="$mbrname.img"

if [ ! -f "$img" ]; then
  bximage -mode=create -imgmode=flat -hd=10M -q "$img"
fi

# 把mbr写入img
mbrbin="$mbrname.bin"
nasm -f bin -o "$mbrbin" "$mbr"
# 获取mbr.bin的文件长度
mbrlength=$(wc -c "$mbrbin" | awk '{print $1}')
mbrcount=$((mbrlength / 512 + (mbrlength % 512 > 0)))

dd if="$mbrbin" of="$img" bs=512 count=$mbrcount conv=notrunc

# 把program写入img
if [ -n "$program" ]; then
  programname=${program%%.*}
  programbin="$programname.bin"
  nasm -f bin -o "$programbin" "$program"
  programlength=$(wc -c "$programbin" | awk '{print $1}')
  programcount=$(((programlength / 512) + (programlength % 512 > 0)))
  dd if="$programbin" of="$img" bs=512 seek=100 count=$programcount conv=notrunc
fi

# 启动bochs
export BX_MBR="$img"
bochs -f bochsrc -q
