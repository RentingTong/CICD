#!/bin/bash
####################################################################
#                                                                  #
#   @date: 2018/06/29                                              #
#   @author: Tara                                                  #
#   Restart netword card in the specified order, close all VNC     #
#   consoles and create :1 console, ping dashboard server, kill    #
#   all browser's sessions, kill all python sessions, execute      #
#   DailRegressionAPI.                                             #
#                                                                  #
####################################################################

basedir="/home/emc/Desktop/Automation/dailyRegression/"
password="Password123!"
dashboard_ip="10.62.81.221"

echo $password | sudo rm -rf /tmp/.X*lock
echo $password | sudo rm -rf /tmp/.X11-unix/X*

echo -e "\033[42;37m********************* Restart Network *********************\033[0m"
net_name=`ip r | sed 1d | awk '{print $3}'`
ips=`ip r | sed 1d | awk '{print $9}'`
set -f
net_name=(${net_name// / })
ips=($ips)

for i in "${!ips[@]}"
do
    echo "${net_name[i]} => ${ips[i]}"
    if [[ ${ips[i]} == 10* ]]
    then
        one=${net_name[i]}
    elif [[ ${ips[i]} == 192.168.10.* ]]
    then
        two=${net_name[i]}
    else
        three=${net_name[i]}
        if [[ $((${-+"(${ips[i]//./"+256*("}))))"}>>24&255)) -lt 100 ]]
        then
            echo -e "\033[33m[Warning Message] ${ips[i]} does not match the requirement.\033[0m"
        fi
    fi
done

echo $password | sudo ip link set down $one
echo $password | sudo ip link set up $one
echo $password | sudo ip link set down $two
echo $password | sudo ip link set up $two
echo $password | sudo ip link set down $three
echo $password | sudo ip link set up $three
echo $password | sudo -S service network-manager stop
ret=$?
if [[ ${ret} -ne 0 ]];
then
  echo -e "\033[31m [Error Message] stop Networking failed.\033[0m"
  exit 1
fi
sleep 1
echo $password | sudo -S service network-manager start
ret=$?
if [[ ${ret} -ne 0 ]];
then
  echo -e "\033[31m [Error Message] start Networking failed.\033[0m"
  exit 1
fi
sleep 1
sleep 5
echo -e "\033[32m Network restart successfully.\033[0m"


echo -e "\033[42;37m*********************** Set Up VNC ***********************\033[0m"
session_name="vnc"
session_num=`ps -ef | grep ${session_name} | awk '{print $2}' | wc -l`
session_id=`ps -ef | grep ${session_name} | awk '{print $2}'`
while [ $session_num -gt "1" ]
do
    echo $password | sudo kill -9 $session_id
    session_num=`ps -ef | grep ${session_name} | awk '{print $2}' | wc -l`
    session_id=`ps -ef | grep ${session_name} | awk '{print $2}'`
done

vncserver -geometry 1600x900
ret=$?
if [[ ${ret} -ne 0 ]];
then
    "\033[31m [Error Message] Open VNC console failed.\033[0m"
else
    echo -e "\033[32m Open VNC console :1.\033[0m"
fi

echo -e "\033[42;37m********************* Ping Dashboard *********************\033[0m"
ping_sesult=`ping -c 3 $dashboard_ip | tail -2 | head -1 | awk '{print $4}'`
if [ $ping_sesult -eq "0" ]
then
    echo -e "\033[31m [Error Message] ping $dashboard_ip failed.\033[0m"
else
    echo -e "\033[32m Ping $dashboard_ip successfully.\033[0m"
fi


echo -e "\033[42;37m**************** Start DailyRegression API ****************\033[0m"
cd $basedir
killall chrome
killall firefox
killall python
python RegressionAPI.py 2>&1

