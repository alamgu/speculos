#!/bin/bash

set -e

function get_text_addr()
{
    local elf="$1"

    armv6l-unknown-none-eabi-readelf -WS "$elf" \
        | grep '\.text' \
        | awk '{ print "0x"$5 }'
}

function main()
{
    local script_dir
    local launcher_text_addr
    local app="$1"
    script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
    local launcher_path=$(readlink -e $script_dir/../lib/*/site-packages/speculos/resources/launcher)
    launcher_text_addr=$(get_text_addr "$launcher_path")
    local gdbinit="${GDBINIT:-$script_dir/gdbinit}"

    cat >/tmp/x.gdb<<EOF
source ${gdbinit}
set architecture arm
target remote 127.0.0.1:1234
handle SIGILL nostop pass noprint
add-symbol-file "${launcher_path}" ${launcher_text_addr}
add-symbol-file "${app}" 0x40000000
b *0x40000000
c
alias reconnect = target remote 127.0.0.1:1234
EOF

    gdb -q -nh -x /tmp/x.gdb
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <app.elf>"
    exit 1
fi

main "$1"
