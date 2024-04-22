#!/bin/zsh -eu

PROJECT=$(dirname "$(realpath $0)")
cd $PROJECT

# options
# -----------------------------------
zparseopts -D -E -F -- \
           {h,-help}=help  \
           -clean=clean \
           -check-probe=check_probe \
           -erase=erase \
           {b,-build}=build \
           {u,-burn}=burn \
           {f,-flash}=flash \
    || return

THIS_SCRIPT=$0

# functions
# -----------------------------------
help_usage() {
    print -rC1 -- \
          "" \
          "Usage:" \
          "    $THIS_SCRIPT:t -h,--help                  help" \
          "    $THIS_SCRIPT:t --clean                    clean build environment" \
          "    $THIS_SCRIPT:t --check-probe              check black magic probe" \
          "    $THIS_SCRIPT:t --erase                    erase via black magic" \
          "    $THIS_SCRIPT:t -b,--build BOARD...        build bootloader(s)" \
          "    $THIS_SCRIPT:t -u,--burn BOARD            burn bootloader via black magic" \
          "    $THIS_SCRIPT:t -f,--flash BOARD           update flash bootloader" \
          "    $THIS_SCRIPT:t -bf,--build --flash BOARD  build & update flash bootloader" \
          "    $THIS_SCRIPT:t -bu,--build --burn BOARD   build & burn bootloader via black magic" \
          ""
}

error_exit() {
    print -r "Error: $2" >&2
    exit $1
}

clean() {
    rm -rf _build
    rm -rf node_modules
    rm -rf xpacks
    rm -rf .venv
}

build() {
    local board=$1
    make BOARD=$board all
}

get_latest_bootloader() {
    local board=$1

    local bootloaders=($(ls -t _build/build-${board}/${board}_bootloader-*.zip))
    if [[ $#bootloaders != 0 ]]; then
        echo $bootloaders[1]
    fi
}

get_dfu_device_name() {
    local board=$1

    local board_h="src/boards/${board}/board.h"
    local board_h_lines=("${(@f)$(< $board_h)}")
    local device_name=""
    for l in "$board_h_lines[@]"; do
        if [[ $l =~ "^#define BLEDIS_MODEL.*\"(.*)\"" ]]; then
            echo $match[1]
            break
        fi
    done
}

get_target_serial_port() {
    local device_name=$1

    local l=$(ioreg -rl -c IOUSBHostDevice -n "$device_name" | { grep IOCalloutDevice || true })
    if [[ ! -z $l ]] && [[ $l =~ " = \"(.*)\"" ]]; then
        echo $match[1]
    fi
}

flash() {
    local board=$1

    local bootloader_zip=$(get_latest_bootloader $board)
    [[ -z $bootloader_zip ]] && \
        error_exit 1 "no found bootloader file"

    local device_name=$(get_dfu_device_name $board)
    [[ -z $device_name ]] && \
        error_exit 1 "no found definition for BLEDIS_MODEL"

    local serial_port=$(get_target_serial_port "$device_name")
    [[ -z $serial_port ]] && \
        echo -n "waiting for target [${device_name}] to be connected."

    while [[ -z $serial_port ]]; do
        sleep 1
        echo -n "."
        serial_port=$(get_target_serial_port "$device_name")
        [[ ! -z $serial_port ]] && echo
    done

    adafruit-nrfutil --verbose dfu serial --package $bootloader_zip -p $serial_port -b 115200 --singlebank --touch 1200
}

get_black_magic_serial_ports() {
    local s=$(ioreg -c IOUSBHostDevice | { grep "\"kUSBProductString\" = \"Black Magic Probe" || true })
    if [[ -z $s ]]; then
        return
    fi

    if [[ ! $s =~ "(Black Magic Probe.*)\"" ]]; then
        return
    fi

    local product_name=$match[1]
    local lines=("${(@f)$(ioreg -rl -c IOUSBHostDevice -n "$product_name" | { grep "\"IOCalloutDevice\" = " || true })}")
    if [[ $#lines = 0 ]]; then
        return
    fi

    local serial_ports=()
    for l in "$lines[@]"; do
        if [[ $l =~ " = \"(.*)\"" ]]; then
            serial_ports=($serial_ports $match[1])
        fi
    done
    echo $serial_ports
}

check_probe() {
    local serial_ports=($(get_black_magic_serial_ports))
    if [[ $#serial_ports = 0 ]]; then
        error_exit 1 "no found Black Magic Probe"
    fi

    local gdb_server_port=$serial_ports[1]
    local uart_port=$serial_ports[2]

    arm-none-eabi-gdb --batch \
                      -ex "target extended-remote $gdb_server_port" \
                      -ex "monitor" \
                      -ex "mon swdp_scan"
}

erase() {
    local serial_ports=($(get_black_magic_serial_ports))
    if [[ $#serial_ports = 0 ]]; then
        error_exit 1 "no found Black Magic Probe"
    fi

    local gdb_server_port=$serial_ports[1]
    local uart_port=$serial_ports[2]

    arm-none-eabi-gdb --batch \
                      -ex "target extended-remote $gdb_server_port" \
                      -ex "mon swdp_scan" \
                      -ex "att 1" \
                      -ex "mon erase_mass"
}

burn() {
    local board=$1

    local serial_ports=($(get_black_magic_serial_ports))
    if [[ $#serial_ports = 0 ]]; then
        error_exit 1 "no found Black Magic Probe"
    fi
    local gdb_server_port=$serial_ports[1]
    local uart_port=$serial_ports[2]

    local bootloader_zip=$(get_latest_bootloader $board)
    if [[ -z $bootloader_zip ]]; then
        error_exit 1 "no found bootloader zip file"
    fi

    local bootloader_hex="${bootloader_zip:r}.hex"
    if [[ ! -f $bootloader_hex ]]; then
        error_exit 1 "no found bootloader file [${bootloader_hex}]"
    fi

    arm-none-eabi-gdb --batch \
                      -ex "target extended-remote $gdb_server_port" \
                      -ex "mon swdp_scan" \
                      -ex "file $bootloader_hex" \
                      -ex "att 1" \
                      -ex "mon erase" \
                      -ex load
}

if (( $#help )); then
    help_usage
    return
fi

if (( $#clean )); then
    clean
    return
fi

export DIRENV_LOG_FORMAT=
eval "$(direnv export zsh)"
direnv allow

if [[ ! -d node_modules || ! -d xpacks ]]; then
    npm install
fi

if [[ -d .venv ]]; then
    source .venv/bin/activate
else
    python3 -m venv .venv
    source .venv/bin/activate
    pip3 install -r requirements.txt
fi

if (( $#check_probe )); then
    check_probe
    return
fi

if (( $#erase )); then
    erase
    return
fi

if (( $#build )) || (( $#burn )) || (( $#flash )); then
    [[ $# = 0 ]] && \
        error_exit 1 "no BOARD specified."
fi

target_boards=("$@")

if (( $#build )); then
    for board in $target_boards; do
        build $board
    done
fi

if (( $#burn )); then
    [[ $# != 1 ]] && \
        error_exit 1 "only one BOARD is allowed for --burn."

    burn $target_boards[1]
    return
fi

if (( $#flash )); then
    [[ $# != 1 ]] && \
        error_exit 1 "only one BOARD is allowed for --flash."

    flash $target_boards[1]
fi
