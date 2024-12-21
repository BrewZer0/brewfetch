#!/bin/bash


echo "  ___                 __     _      _    "
echo " | _ )_ _ _____ __ __/ _|___| |_ __| |_  "
echo " | _ \ '_/ -_) V  V /  _/ -_)  _/ _| ' \ "
echo " |___/_| \___|\_/\_/|_| \___|\__\__|_||_|"
echo "                                          "

echo -e "\e[31;40m _________________________________________\e[m"
echo  
# todo: cpu info done, windowmanager when
echo -e "\e[1;33mHost:\e[0m$(hostname 2>/dev/null || echo "Unknown")"
echo -e "\e[1;33mOperating System:\e[0m $(cat /etc/issue | tr -d '\n' | sed 's/\\n \\l//g') on $(uname -m)"  
echo -e "\e[1;33mKernel version:\e[0m $(uname -r)" 
echo -e "\e[1;33mRAM:\e[0m $(awk '/MemTotal/ {print $2 / 1024}' /proc/meminfo) MB" 
echo -e "\e[1;33mSwap:\e[0m $(awk '/SwapTotal/ {print $2 / 1024}' /proc/meminfo) MB"
echo -e "\e[1;33mCPU:\e[0m $(awk '/vendor/ {print $3}' /proc/cpuinfo) $(awk '/model/ {print $3}' /proc/cpuinfo)"
