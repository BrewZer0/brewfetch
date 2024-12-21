#!/bin/bash


# ok... i have fairly no clue on how to make one. the easiest wat i can think of it is doing like this

cat bf

echo -e "\e[31;40m _________________________________________\e[m"
echo  
# todo: cpu info done, windowmanager when
echo -e "\e[1;33mOperative System:\e[0m $(cat /etc/issue | tr -d '\n' | sed 's/\\n \\l//g') on $(uname -m)"  
echo -e "\e[1;33mKernel version:\e[0m $(uname -r)" 
echo -e "\e[1;33mRAM:\e[0m $(awk '/MemTotal/ {print $2 / 1024}' /proc/meminfo) MB" 
echo -e "\e[1;33mSwap:\e[0m $(awk '/SwapTotal/ {print $2 / 1024}' /proc/meminfo) MB"
echo -e "\e[1;33mCPU:\e[0m $(awk '/vendor/ {print $3}' /proc/cpuinfo) $(awk '/model/ {print $3}' /proc/cpuinfo)"
echo  