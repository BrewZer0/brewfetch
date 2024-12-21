#!/bin/bash

# Default settings
VERBOSE=false
COLOR_LABEL="\e[1;33m"  # Bold yellow
COLOR_INFO="\e[0m"      # Reset
COLOR_ERROR="\e[1;31m"  # Bold red
COLOR_RESET="\e[0m"     # Reset

# Help message function
show_help() {
    cat << EOF
Brewfetch - A system information fetcher
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
while [[ "$#" -gt 0 ]]; do
    case $1 in
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
    if [ "$VERBOSE" = true ]; then
        echo -e "${COLOR_ERROR}Error: $1${COLOR_RESET}" >&2
    fi
}

# ASCII art
echo "  ___                 __     _      _    "
echo " | _ )_ _ _____ __ __/ _|___| |_ __| |_  "
echo " | _ \ '_/ -_) V  V /  _/ -_)  _/ _| ' \ "
echo " |___/_| \___|\_/\_/|_| \___|\__\__|_||_|"
echo "                                          "

# Function to get package manager and package count
get_package_info() {
    local result=""
    local managers=("dpkg" "rpm" "pacman" "brew" "port")
    local commands=("-l" "-qa" "-Q" "list" "-q installed")
    
    for i in "${!managers[@]}"; do
        if command -v "${managers[$i]}" >/dev/null 2>&1; then
            local count=$(eval "${managers[$i]} ${commands[$i]}" 2>/dev/null | wc -l)
            [ ! -z "$result" ] && result+=", "
            result+="${managers[$i]}: $count packages"
        fi
    done
    
    [ -z "$result" ] && result="Unknown"
    echo "$result"
}

# Function to get shell info
get_shell_info() {
    local shell_path="${SHELL:-Unknown}"
    local shell_version=""
    
    case "$shell_path" in
        *bash) shell_version=$(bash --version | head -n1 | cut -d' ' -f4) ;;
        *zsh) shell_version=$(zsh --version | cut -d' ' -f2) ;;
        *fish) shell_version=$(fish --version | cut -d' ' -f3) ;;
    esac
    
    [ ! -z "$shell_version" ] && shell_path="$shell_path ($shell_version)"
    echo "$shell_path"
}

# Function to get terminal info
get_terminal_info() {
    if [ ! -z "$TERM_PROGRAM" ]; then
        echo "$TERM_PROGRAM${TERM_PROGRAM_VERSION:+ $TERM_PROGRAM_VERSION}"
    elif [ ! -z "$TERMINATOR_UUID" ]; then
        echo "Terminator"
    elif [ ! -z "$GNOME_TERMINAL_SERVICE" ]; then
        echo "GNOME Terminal"
    elif [ ! -z "$KONSOLE_VERSION" ]; then
        echo "Konsole"
    else
        echo "$TERM"
    fi
}

# Function to get screen resolution
get_screen_resolution() {
    if command -v xrandr >/dev/null 2>&1; then
        xrandr --current 2>/dev/null | grep '*' | awk '{print $1}' | tr '\n' ', ' | sed 's/,$//' || echo "Unknown"
    else
        log_error "xrandr not installed"
        echo "Unknown"
    fi
}

# Function to get CPU temperature
get_cpu_temp() {
    local temp=""
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        temp=$(awk '{printf "%.1f°C", $1/1000}' /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
    elif command -v sensors >/dev/null 2>&1; then
        temp=$(sensors 2>/dev/null | grep -i "CPU Temperature" | awk '{print $3}' | tr -d '+')
    fi
    [ -z "$temp" ] && temp="Unknown"
    echo "$temp"
}

# Function to get network speed
get_network_speed() {
    if command -v awk >/dev/null 2>&1 && [ -f "/proc/net/dev" ]; then
        local interface=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'dev \K\w+' || echo "")
        if [ ! -z "$interface" ]; then
            local stats1=$(cat /proc/net/dev | grep "$interface:" | awk '{print $2,$10}')
            sleep 1
            local stats2=$(cat /proc/net/dev | grep "$interface:" | awk '{print $2,$10}')
            local rx1=$(echo "$stats1" | awk '{print $1}')
            local tx1=$(echo "$stats1" | awk '{print $2}')
            local rx2=$(echo "$stats2" | awk '{print $1}')
            local tx2=$(echo "$stats2" | awk '{print $2}')
            local rxspeed=$(( (rx2-rx1) / 1024 ))
            local txspeed=$(( (tx2-tx1) / 1024 ))
            echo "↓${rxspeed}KB/s ↑${txspeed}KB/s"
        else
            echo "Unknown"
        fi
    else
        echo "Unknown"
    fi
}

# Function to get desktop environment
get_de() {
    if [ ! -z "$XDG_CURRENT_DESKTOP" ]; then
        echo "$XDG_CURRENT_DESKTOP"
    elif [ ! -z "$DESKTOP_SESSION" ]; then
        echo "$DESKTOP_SESSION"
    else
        log_error "Could not detect desktop environment"
        echo "Unknown"
    fi
}

# Function to get window manager
get_wm() {
    if [ -z "$DISPLAY" ]; then
        log_error "No X Server running"
        echo "No X Server"
        return
    fi
    
    if command -v wmctrl >/dev/null 2>&1; then
        wmctrl -m | grep "Name:" | cut -d: -f2 | tr -d ' ' 2>/dev/null || {
            log_error "Failed to get window manager info"
            echo "Unknown"
        }
    else
        log_error "wmctrl not installed"
        echo "Unknown"
    fi
}

# Function to get GPU info
get_gpu() {
    if command -v lspci >/dev/null 2>&1; then
        lspci | grep -i 'vga\|3d\|2d' | head -n1 | sed 's/.*: //' 2>/dev/null || {
            log_error "Failed to get GPU info from lspci"
            echo "Unknown"
        }
    else
        log_error "lspci not installed"
        echo "Unknown"
    fi
}

# Function to get battery info
get_battery() {
    local battery_found=false
    local result=""
    
    for bat in /sys/class/power_supply/BAT*; do
        if [ -d "$bat" ]; then
            battery_found=true
            capacity=$(cat "$bat/capacity" 2>/dev/null)
            status=$(cat "$bat/status" 2>/dev/null)
            if [ ! -z "$capacity" ] && [ ! -z "$status" ]; then
                [ ! -z "$result" ] && result+=", "
                result+="$(basename "$bat"): ${capacity}% - ${status}"
            fi
        fi
    done
    
    if [ "$battery_found" = true ]; then
        echo "$result"
    else
        log_error "No battery detected"
        echo "No battery detected"
    fi
}

# Function to get disk usage
get_disk_usage() {
    local result=""
    local error_occurred=false
    
    while read -r line; do
        if [[ $line =~ ^/dev/ ]]; then
            mountpoint=$(echo "$line" | awk '{print $6}')
            used=$(echo "$line" | awk '{print $3}')
            total=$(echo "$line" | awk '{print $2}')
            usage=$(echo "$line" | awk '{print $5}')
            
            # Skip pseudo filesystems
            if [[ "$total" =~ ^[0-9] ]]; then
                [ ! -z "$result" ] && result+=", "
                result+="$mountpoint: $used/$total ($usage)"
            fi
        fi
    done < <(df -h 2>/dev/null || { error_occurred=true; })
    
    if [ "$error_occurred" = true ]; then
        log_error "Error getting disk usage information"
    fi
    
    [ -z "$result" ] && result="Unknown"
    echo "$result"
}

# Function to get local IP
get_local_ip() {
    local result=""
    if command -v ip >/dev/null 2>&1; then
        result=$(ip addr show 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d/ -f1 | tr '\n' ', ' | sed 's/,$//')
    elif command -v ifconfig >/dev/null 2>&1; then
        result=$(ifconfig 2>/dev/null | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | tr '\n' ', ' | sed 's/,$//')
    fi
    
    if [ -z "$result" ]; then
        log_error "Could not detect IP address"
        echo "Unknown"
    else
        echo "$result"
    fi
}

echo -e "${COLOR_LABEL} _________________________________________\e[m"
echo

# System information display
echo -e "${COLOR_LABEL}Host:${COLOR_INFO} $(hostname 2>/dev/null || echo "Unknown")"
echo -e "${COLOR_LABEL}OS:${COLOR_INFO} $(cat /etc/issue 2>/dev/null | tr -d '\n' | sed 's/\\n \\l//g' || echo "Unknown") on $(uname -m 2>/dev/null || echo "Unknown")"
echo -e "${COLOR_LABEL}Kernel:${COLOR_INFO} $(uname -r 2>/dev/null || echo "Unknown")"
echo -e "${COLOR_LABEL}Uptime:${COLOR_INFO} $(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")"
echo -e "${COLOR_LABEL}Shell:${COLOR_INFO} $(get_shell_info)"
echo -e "${COLOR_LABEL}Terminal:${COLOR_INFO} $(get_terminal_info)"
echo -e "${COLOR_LABEL}Packages:${COLOR_INFO} $(get_package_info)"
echo -e "${COLOR_LABEL}Desktop Environment:${COLOR_INFO} $(get_de)"
echo -e "${COLOR_LABEL}Window Manager:${COLOR_INFO} $(get_wm)"
echo -e "${COLOR_LABEL}Resolution:${COLOR_INFO} $(get_screen_resolution)"
echo -e "${COLOR_LABEL}CPU:${COLOR_INFO} $(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo 2>/dev/null | sed 's/^[ \t]*//' || echo "Unknown")"
echo -e "${COLOR_LABEL}CPU Temp:${COLOR_INFO} $(get_cpu_temp)"
echo -e "${COLOR_LABEL}GPU:${COLOR_INFO} $(get_gpu)"
echo -e "${COLOR_LABEL}Memory:${COLOR_INFO} $(free -h 2>/dev/null | awk '/^Mem:/ {printf "%sB/%sB (%s used)", $3, $2, $3/$2*100 "%"}' || echo "Unknown")"
echo -e "${COLOR_LABEL}Swap:${COLOR_INFO} $(free -h 2>/dev/null | awk '/^Swap:/ {printf "%sB/%sB (%s used)", $3, $2, $3/$2*100 "%"}' || echo "Unknown")"
echo -e "${COLOR_LABEL}Disk Usage:${COLOR_INFO} $(get_disk_usage)"
echo -e "${COLOR_LABEL}Network Speed:${COLOR_INFO} $(get_network_speed)"
echo -e "${COLOR_LABEL}Local IP:${COLOR_INFO} $(get_local_ip)"
echo -e "${COLOR_LABEL}Battery:${COLOR_INFO} $(get_battery)"
echo -e "${COLOR_LABEL}Locale:${COLOR_INFO} ${LANG:-Unknown}"
echo

if [ "$VERBOSE" = true ]; then
    echo -e "Note: Verbose mode is enabled. Error messages were displayed above if any occurred."
fi