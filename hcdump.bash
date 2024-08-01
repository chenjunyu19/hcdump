#!/bin/bash

usage() {
    echo "用法：$0 -k <hex_key> [-v <public_key_file>] <app.conf.dat>"
    echo "    -h                    显示此信息"
    echo "    -k <hex_key>          HEX 格式 AES-256-CBC 密钥"
    echo "    -v <public_key_file>  用于验证签名的公钥文件"
    echo "       <app.conf.dat>     app.conf.dat 文件路径"
    exit 1
}

while getopts 'hk:v:' OPT; do
    case $OPT in
        'k')
            hex_key="$OPTARG"
            ;;
        'v')
            public_key_file="$OPTARG"
            ;;
        'h' | '?')
            usage
            ;;
    esac
done

shift $((OPTIND - 1))

if [ $# -ne 1 ] || [ -z "$hex_key" ] || ! [ -f "$1" ]; then
    usage
fi

set -xe

temp_dir="$(mktemp -d --tmpdir hcdump.XXX)"

trap "rm -rf $temp_dir" EXIT

if [ -n "$public_key_file" ]; then
    dd if="$1" of="$temp_dir/app.conf.dat.dgst.sig" bs=1 count=256
    dd if="$1" of="$temp_dir/app.conf.dat.dgst.in" bs=1 skip=256
    openssl dgst -sha256 \
        -verify "$public_key_file" \
        -signature "$temp_dir/app.conf.dat.dgst.sig" \
        "$temp_dir/app.conf.dat.dgst.in" \
        1>&2
fi

iv="$(dd if="$1" bs=1 skip=256 count=16 | hexdump -v -e '/1 "%02x"')"
dd if="$1" of="$temp_dir/app.conf.dat.enc.in" bs=1 skip=$((256+16))
openssl enc -aes-256-cbc -d -K "$hex_key" -iv "$iv" -in "$temp_dir/app.conf.dat.enc.in"
