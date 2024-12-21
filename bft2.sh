#!/bin/bash

# Default settings
VERBOSE=false
COLOR_LABEL="\e[1;33m"
COLOR_INFO="\e[0m"
COLOR_ERROR="\e[1;31m"
COLOR_RESET="\e[0m"

# Help message function
show_help() {
    cat << EOF
Brewfetch - A lightweight system information fetcher
Usage: $(basename "$0") [OPTIONS]

Options:
    -h, --help     Show this help message and exit
    -v, --verbose  Show error messages and debugging information
    --no-color     Disable colored output
    --version      Show version information

Examples:
    $(basename "$0")              # Run with default settings
    $(basename "$0") --no-color   # Run without colors
    $(basename "$0") --verbose    # Show detailed error messages

Report bugs to: https://github.com/BrewZer0/brewfetch/issues
EOF
    exit 0
}

# Version information
show_version() {
    echo "Brewfetch v1.0.0"
    echo "Copyright (C) 2024"
    echo "License: MIT"
    exit 0
}

# Parse command line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help) show_help ;;
        -v|--verbose) VERBOSE=true ;;
        --no-color) COLOR_LABEL=""; COLOR_INFO=""; COLOR_ERROR=""; COLOR_RESET="" ;;
        --version) show_version ;;
        *) echo "Unknown parameter: $1"; echo "Use -h or --help for usage information"; exit 1 ;;
    esac
    shift
done

# Error handling function
log_error() {
    [ "$VERBOSE" = true ] && echo -e "${COLOR_ERROR}Error: $1${COLOR_RESET}" >&2
}

# ASCII art
cat << "EOF"
  ___                 __     _      _    
 | _ )_ _ _____ __ __/ _|___| |_ __| |_  
 | _ \ '_/ -_) V  V /  _/ -_)  _/ _| ' \ 
 |___/_| \___|\_/\_/|_| \___|\__\__|_||_|
                                          
EOF

# Function to get package count
get_package_info() {
    for cmd in dpkg rpm pacman brew port; do
        if command -v "$cmd" > /dev/null 2>&1; then
            case "$cmd" in
                dpkg) count=$(dpkg --get-selections 2>/dev/null | wc -l) ;;
                rpm) count=$(rpm -qa 2>/dev/null | wc -l) ;;
                pacman) count=$(pacman -Q 2>/dev/null | wc -l) ;;
                brew) count=$(brew list 2>/dev/null | wc -l) ;;
                port) count=$(port installed 2>/dev/null | wc -l) ;;
            esac
            [ "$count" -gt 0 ] 2>/dev/null && echo "$cmd: $count packages" && return
        fi
    done
    echo "Unknown"
}

# Function to get shell info
get_shell_info() {
    basename "$SHELL" 2>/dev/null || echo "Unknown"
}

# Function to get terminal info
get_terminal_info() {
    [ -n "$TERM" ] && echo "$TERM" || echo "Unknown"
}

# Function to get desktop environment
get_de() {
    [ -n "$XDG_CURRENT_DESKTOP" ] && echo "$XDG_CURRENT_DESKTOP" || \
    [ -n "$DESKTOP_SESSION" ] && echo "$DESKTOP_SESSION" || \
    echo "Unknown"
}

# Function to get window manager
get_wm() {
    [ -z "$DISPLAY" ] && echo "No X Server" && return
    ps -e 2>/dev/null | grep -m 1 -o -E "openbox|kwin|mutter|xfwm4|muffin|mate-window-manager|marco|metacity|compiz|icewm" || echo "Unknown"
}

# Function to get GPU info
get_gpu() {
    if [ -d "/sys/class/drm" ]; then
        ls -d1 /sys/class/drm/card[0-9]* 2>/dev/null | head -n1 | xargs -I {} cat {}/device/uevent 2>/dev/null | grep "DRIVER=" | sed 's/DRIVER=//' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Function to get battery info
get_battery() {
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] || continue
        cap=$(cat "$bat/capacity" 2>/dev/null)
        sta=$(cat "$bat/status" 2>/dev/null)
        [ -n "$cap" ] && [ -n "$sta" ] && echo "$(basename "$bat"): ${cap}% - ${sta}" && return
    done
    echo "No battery detected"
}

# Function to get disk usage
get_disk_usage() {
    df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2 " (" $5 ")"}' || echo "Unknown"
}

# Function to get local IP
get_local_ip() {
    if command -v hostname >/dev/null 2>&1; then
        hostname -I 2>/dev/null | cut -d' ' -f1 || echo "Unknown"
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | head -n1 | awk '{print $2}' || echo "Unknown"
    else
        echo "Unknown"
    fi
}

# Function to get memory info
get_memory() {
    if [ -f "/proc/meminfo" ]; then
        total=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
        free=$(awk '/MemFree/ {print int($2/1024)}' /proc/meminfo)
        used=$((total - free))
        echo "${used}MB/${total}MB"
    else
        echo "Unknown"
    fi
}

echo -e "${COLOR_LABEL} _________________________________________${COLOR_RESET}"
echo

# System information display
echo -e "${COLOR_LABEL}Host:${COLOR_INFO} $(hostname 2>/dev/null || echo "Unknown")"
echo -e "${COLOR_LABEL}OS:${COLOR_INFO} $(cat /etc/issue 2>/dev/null | head -n1 | sed 's/\\n \\l//g' || echo "Unknown")"
echo -e "${COLOR_LABEL}Kernel:${COLOR_INFO} $(uname -r 2>/dev/null || echo "Unknown")"
echo -e "${COLOR_LABEL}Uptime:${COLOR_INFO} $(uptime | cut -d',' -f1 | sed 's/.*up *//' || echo "Unknown")"
echo -e "${COLOR_LABEL}Shell:${COLOR_INFO} $(get_shell_info)"
echo -e "${COLOR_LABEL}Terminal:${COLOR_INFO} $(get_terminal_info)"
echo -e "${COLOR_LABEL}Packages:${COLOR_INFO} $(get_package_info)"
echo -e "${COLOR_LABEL}Desktop Environment:${COLOR_INFO} $(get_de)"
echo -e "${COLOR_LABEL}Window Manager:${COLOR_INFO} $(get_wm)"
echo -e "${COLOR_LABEL}CPU:${COLOR_INFO} $(sed -n 's/model name[[:space:]]*: //p' /proc/cpuinfo 2>/dev/null | head -n1 || echo "Unknown")"
echo -e "${COLOR_LABEL}GPU:${COLOR_INFO} $(get_gpu)"
echo -e "${COLOR_LABEL}Memory:${COLOR_INFO} $(get_memory)"
echo -e "${COLOR_LABEL}Disk Usage:${COLOR_INFO} $(get_disk_usage)"
echo -e "${COLOR_LABEL}Local IP:${COLOR_INFO} $(get_local_ip)"
echo -e "${COLOR_LABEL}Battery:${COLOR_INFO} $(get_battery)"
echo -e "${COLOR_LABEL}Locale:${COLOR_INFO} ${LANG:-Unknown}"
echo

[ "$VERBOSE" = true ] && echo "Note: Verbose mode is enabled. Error messages were displayed above if any occurred."