#!/bin/sh
echo "  ___                 __     _      _    "
echo " | _ )_ _ _____ __ __/ _|___| |_ __| |_  "
echo " | _ \ '_/ -_) V  V /  _/ -_)  _/ _| ' \ "
echo " |___/_| \___|\_/\_/|_| \___|\__\__|_||_|"
echo "                                          "
echo " _________________________________________"
echo  
echo  "Host: $(hostname 2>/dev/null || echo "Unknown")"
echo "Shell: $SHELL"
echo  "OS: $(uname -o) on $(uname -m)"  
echo  "Kernel version: $(uname -r)"
echo  "RAM: $(awk '/MemTotal/ {print $2 / 1024}' /proc/meminfo) MB" 
echo  "Swap: $(awk '/SwapTotal/ {print $2 / 1024}' /proc/meminfo) MB"
