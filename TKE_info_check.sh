#!/bin/bash
# ------------------------------------------------------------------------------
# 您好！本脚本纯shell编写，用于收集系统日志以及相关服务日志等，
#
# 目前兼容TKE的Ubuntu、Centos，脚本开源，您可以直接用vim打开脚本查阅里面的代码。
#
# 确认脚本无误后，放到容器节点运行。成功后，请把/tmp/tkelog/tkelog.tar.gz打包文件发我们进行问题排查，感谢您的支持！
# ------------------------------------------------------------------------------
export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin/bash
version='2020.1'
#source /etc/profile
[ $(id -u) -gt 0 ] && echo "请用root用户执行此脚本！" && exit 1

#log path
MESSAGESPATH="/var/log/"
LOGPATH='/tmp/tkelog'

#log name
RESULTFILE="$LOGPATH/tkecheck-`hostname`-`date +%Y%m%d`.log"
Kubelet_log_file="$LOGPATH/kubelet-`hostname`-`date +%Y%m%d`.log"
KubeProxy_log_file="$LOGPATH/kube-proxy-`hostname`-`date +%Y%m%d`.log"
Iptables_log_file="$LOGPATH/iptables-`hostname`-`date +%Y%m%d`.log"
Docker_log_file="$LOGPATH/docker-`hostname`-`date +%Y%m%d`.log"
DescribeNode_log_file="$LOGPATH/describeNode-`hostname`-`date +%Y%m%d`.log"
Netstat_log_file="$LOGPATH/netstat-`hostname`-`date +%Y%m%d`.log"
# color
bldred='\033[1;31m' # red
bldgrn='\033[1;32m' # green
bldblu='\033[1;34m' # Blue
bldylw='\033[1;33m' # Yellow
txtrst='\033[0m'    # end

#color fun
info () {
  printf "%b\n" "${bldblu}[INFO]${txtrst} $1" 
}

pass () {
  printf "%b\n" "${bldgrn}[PASS]${txtrst} $1" 
}

warn () {
  printf "%b\n" "${bldred}[WARN]${txtrst} $1" 
}

yell () {
  printf "%b\n" "${bldylw}$1${txtrst}\n"
}

Get_Os(){
    firstos=$(cat /etc/os-release | grep NAME |head -1 |cut -d '=' -f2 |sed 's/\"//g' | awk '{print $1}')
    case $firstos in 
      *CentOS*) ver="CentOS";;
      *Ubuntu*) ver="Ubuntu";;
      *)echo "Get_OS ERROR"
    esac
}

Check_dir(){
    if [ ! -d $LOGPATH ];then
        mkdir $LOGPATH
    else
        rm -rf $LOGPATH && mkdir $LOGPATH
    fi
}

Get_System_Status(){
    echo "############################ 系统检查 ############################"
    if [[ $ver == 'CentOS' ]]; then
        Release=$(cat /etc/centos-release 2>/dev/null)
    elif [[ $ver == 'Ubuntu' ]]; then
        Release=$(cat /etc/issue | awk '{print $1 $2}' 2>/dev/null)
    else
        echo
    fi
    Kernel=$(uname -r)
    OS=$(source /etc/os-release && echo "$NAME")
    Hostname=$(uname -n)
    if [[ $ver == "CentOS" ]];then
        SELinux=$(/usr/sbin/sestatus | grep "SELinux status: " | awk '{print $3}')
    elif [[ $ver == "Ubuntu" ]];then
        SELinux="Ubuntu默认没有selinux"
    fi
    LastReboot=$(who -b | awk '{print $3,$4}')
    uptime=$(uptime | sed 's/.*up \([^,]*\), .*/\1/')
    uuid=$(cat /etc/uuid | awk '{print $3}')
    uuiduptime=$(stat -c %y /etc/uuid)
    clusterid=$(cat /etc/kubernetes/config | grep KUBE_CLUSTER | awk -F '[=]' '{print $2}' | sed 's/\"//g')
    echo "     集群ID：$clusterid"
    echo "       系统：$OS"
    echo "   发行版本：$Release"
    echo "       内核：$Kernel"
    echo "     主机名：$Hostname"
    echo "    SELinux：$SELinux"
    echo "   当前时间：$(date +'%F %T')"
    echo "   最后启动：$LastReboot"
    echo "   运行时间：$uptime"
    echo "       uuid: $uuid"
    echo " UUIDuptime: $uuiduptime"
    export LANG="$default_LANG"
}

KUBE_RESERVED(){
    kubeReservedcpu=$(cat /etc/kubernetes/kubelet | grep 'KUBE_RESERVED' |  cut -d ',' -f1 | awk -F"ed=" '{print $2}' |cut -d '=' -f2 | cut -d 'm' -f1)
    syscpu=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    kubeReservedmemory=$(cat /etc/kubernetes/kubelet | grep 'KUBE_RESERVED' |awk -F"," '{print $2}'|cut -d '=' -f2|cut -d 'M' -f1|tr -d '\r')
    sysmem=$(free -h | grep Mem |awk '{print $2}' |  cut -d 'M' -f1)	
}

Get_Cpu_Status(){
    echo ""
    echo ""
    echo "############################ CPU检查 #############################"
    Physical_CPUs=$(grep "physical id" /proc/cpuinfo| sort | uniq | wc -l)
    Virt_CPUs=$(grep "processor" /proc/cpuinfo | wc -l)
    CPU_Kernels=$(grep "cores" /proc/cpuinfo|uniq| awk -F ': ' '{print $2}')
    CPU_Type=$(grep "model name" /proc/cpuinfo | awk -F ': ' '{print $2}' | sort | uniq)
    CPU_Arch=$(uname -m)
    echo "物理CPU个数:$Physical_CPUs"
    echo "逻辑CPU个数:$Virt_CPUs"
    echo "每CPU核心数:$CPU_Kernels"
    echo "CPU型号:$CPU_Type"
    echo "CPU架构:$CPU_Arch"
}

Get_Mem_Status(){
    echo ""
    echo ""
    echo "############################ 内存检查 ############################"
    free -h
    MemStatus=$(free -m | sed -n '2p' | awk '{print "已使用内存:"$3"M,总内存:"$2"M,内存使用率:"$3/$2*100"%"}')

}

Get_Disk_Status(){
# df的时候加-t 参数可以指定type，针对docker的文件格式，这里先待定，等上线后看下固定的文件格式有哪些
    echo ""
    echo ""
    echo "############################ 磁盘检查 ############################"
    df -hiP | sed 's/Mounted on/Mounted/'> /tmp/inode
    df -hTP | sed 's/Mounted on/Mounted/'> /tmp/disk 
    paste /tmp/disk  /tmp/inode  | awk '{print $1,$2,"|",$3,$4,$5,$6,"|",$9,$10,$11,"|",$12,$13}'| column -t 
    basicdisk=$(df -h | head -n 2 | tail -n 1)
    diskuse=$(paste /tmp/disk /tmp/inode | awk '{print $6}' | column -t | head -n 2 | tail -n 1)
    mountname=$(paste /tmp/disk /tmp/inode | awk '{print $13}' | column -t | head -n 2 | tail -n 1)
}

Get_Disk_Indoe_Status(){
#inode数判断，低于95输出报警。
    local disks=(`df -i | sed 1d | awk '{print $1,$5}' |tr -d %`)
    local len=${#disks[@]}
    for ((i=1;i<=$len;i=i+2));do
        if [ ${disks[i]} -ge 95 ];then
            echo "卷：${disks[$i-1]} 当前indoe使用率：${disks[$i]}%,"indoe使用大于等于95%，请检查。""
            return 1
        else
            echo "卷：${disks[$i-1]} 当前indoe使用率：${disks[$i]}% "
           return 0
        fi
    done
}

Get_Disk_Use_Status(){
#磁盘使用率判断
    local disks=(`df  | sed 1d | awk '{print $1,$5}' |tr -d %`)
    local len=${#disks[@]}
    for ((i=1;i<=$len;i=i+2));do
        if [ ${disks[i]} -ge 90 ];then
            echo "卷：${disks[$i-1]} 当前磁盘使用率：${disks[$i]}%,"磁盘使用大于等于90%，请检查。""
            return 1
        else
            echo "卷：${disks[$i-1]} 当前磁盘使用率：${disks[$i]}% "
            return 0
        fi
    done
}

Get_Service_Status(){
    echo ""
    echo ""
    echo "############################ 服务检查 ############################"
    echo ""
    conf=$(systemctl list-unit-files --type=service --state=enabled --no-pager | grep "enabled")
    process=$(systemctl list-units --type=service --state=running --no-pager | grep ".service")	
    echo "设置了开机启动的服务"
    echo "--------"
    echo "$conf"  | column -t
    echo ""
    echo "正在运行的服务"
    echo "--------------"
    echo "$process"
}

Get_Login_Status(){
    echo ""
    echo ""
    echo "############################ 登录检查 ############################"
    last | head
}

Get_Network_Status(){
    echo ""
    echo ""
    echo "############################ 网络检查 ############################"
    ipmessages=$(for i in $(ip link | grep BROADCAST | awk -F: '{print $2}' | grep -v 'veth');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' | grep -v "veth" | tr -d '\n'  ;done)
    echo "ip信息"
    ip a
    echo ""
    for i in $(ip link | grep BROADCAST | awk -F: '{print $2}' | grep -v 'veth');do ip add show $i | grep -E "BROADCAST|global"| awk '{print $2}' | tr '\n' ' ' | grep -v "veth" ;done
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    DNS=$(grep nameserver /etc/resolv.conf| grep -v "#" | awk '{print $2}' | tr '\n' ',' | sed 's/,$//')
    echo "网关：$GATEWAY "
    echo ""
    nameserver="183.60.83.19,183.60.82.98"
    if [[ $DNS != $nameserver ]];then
        echo "默认的DNS是：183.60.83.19,183.60.82.98，请检查DNS是否修改，如果修改了将导致依赖的服务无法解析！"
        echo "当前的DNS：$DNS"
        return 1
    else
        echo "DNS：$DNS"
        return 0
    fi
}

Get_Route_Status(){
    echo ""
    echo ""
    echo "############################ 路由表检查 ############################"
    route -n
}

Get_Listen_Status(){
    echo ""
    echo "network status"
    echo "ss -ntul | column -t"
    ss -ntul | column -t
}

Get_Netstat_Status(){
    echo "netstat -nultp"
    netstat -nultp
    echo "netstat -nt"
    netstat -nt
    echo "netstat -nu"
    netstat -nu
    echo "netstat -ln"
    netstat -ln
    echo "netstat -nat |awk '{print $6}'|sort|uniq -c|sort -rn"
    netstat -nat |awk '{print $6}'|sort|uniq -c|sort -rn
}

Get_How_LongAgo(){
    # 计算一个时间戳离现在有多久了
    datetime="$*"
    [ -z "$datetime" ] && echo "错误的参数：Get_How_LongAgo() $*"
    Timestamp=$(date +%s -d "$datetime")    #转化为时间戳
    Now_Timestamp=$(date +%s)
    Difference_Timestamp=$(($Now_Timestamp-$Timestamp))
    days=0;hours=0;minutes=0;
    sec_in_day=$((60*60*24));
    sec_in_hour=$((60*60));
    sec_in_minute=60
    while (( $(($Difference_Timestamp-$sec_in_day)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_day
        let days++
    done
    while (( $(($Difference_Timestamp-$sec_in_hour)) > 1 ))
    do
        let Difference_Timestamp=Difference_Timestamp-sec_in_hour
        let hours++
    done
    echo "$days 天 $hours 小时前"
}

Get_User_LastLogin(){
    username=$1
    : ${username:="`whoami`"}
    thisYear=$(date +%Y)
    oldesYear=$(last | tail -n1 | awk '{print $NF}')
    while(( $thisYear >= $oldesYear));do
        loginBeforeToday=$(last $username | grep $username | wc -l)
        loginBeforeNewYearsDayOfThisYear=$(last $username -t $thisYear"0101000000" | grep $username | wc -l)
        if [ $loginBeforeToday -eq 0 ];then
            echo "从未登录过"
            break
        elif [ $loginBeforeToday -gt $loginBeforeNewYearsDayOfThisYear ];then
            lastDateTime=$(last -i $username | head -n1 | awk '{for(i=4;i<(NF-2);i++)printf"%s ",$i}')" $thisYear" #格式如: Sat Nov 2 20:33 2015
            lastDateTime=$(date "+%Y-%m-%d %H:%M:%S" -d "$lastDateTime")
            echo "$lastDateTime"
            break
        else
            thisYear=$((thisYear-1))
        fi
    done
}

Get_User_Status(){
    echo ""
    echo ""
    echo "############################ 用户检查 ############################"
    #/etc/passwd 最后修改时间
    pwdfile="$(cat /etc/passwd)"
    Modify=$(stat /etc/passwd | grep Modify | tr '.' ' ' | awk '{print $2,$3}')

    echo "/etc/passwd 最后修改时间：$Modify ($(Get_How_LongAgo $Modify))"
    echo ""
    echo "特权用户"
    echo "--------"
    RootUser=""
    for user in $(echo "$pwdfile" | awk -F: '{print $1}');do
        if [ $(id -u $user) -eq 0 ];then
            echo "$user"
            RootUser="$RootUser,$user"
        fi
    done
    echo ""
    echo "用户列表"
    echo "--------"
    USERs=0
    echo "$(
    echo "用户名 UID GID HOME SHELL 最后一次登录"
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
        for username in $(grep "$shell" /etc/passwd| awk -F: '{print $1}');do
            userLastLogin="$(Get_User_LastLogin $username)"
            echo "$pwdfile" | grep -w "$username" |grep -w "$shell"| awk -F: -v lastlogin="$(echo "$userLastLogin" | tr ' ' '_')" '{print $1,$3,$4,$6,$7,lastlogin}'
        done
        let USERs=USERs+$(echo "$pwdfile" | grep "$shell"| wc -l)
    done
    )" | column -t
    echo ""
    echo "空密码用户"
    echo "----------"
    USEREmptyPassword=""
    for shell in $(grep -v "/sbin/nologin" /etc/shells);do
            for user in $(echo "$pwdfile" | grep "$shell" | cut -d: -f1);do
            r=$(awk -F: '$2=="!!"{print $1}' /etc/shadow | grep -w $user)
            if [ ! -z $r ];then
                echo $r
                USEREmptyPassword="$USEREmptyPassword,"$r
            fi
        done    
    done
    echo ""
    echo "相同ID的用户"
    echo "------------"
    USERTheSameUID=""
    UIDs=$(cut -d: -f3 /etc/passwd | sort | uniq -c | awk '$1>1{print $2}')
    for uid in $UIDs;do
        echo -n "$uid";
        USERTheSameUID="$uid"
        r=$(awk -F: 'ORS="";$3=='"$uid"'{print ":",$1}' /etc/passwd)
        echo "$r"
        echo ""
        USERTheSameUID="$USERTheSameUID $r,"
    done
}

Get_Sudoers_Status(){
    echo ""
    echo ""
    echo "############################ Sudoers检查 #########################"
    conf=$(grep -v "^#" /etc/sudoers| grep -v "^Defaults" | sed '/^$/d')
    echo "$conf"
    echo ""
}

Get_Installed_Status(){
    echo ""
    echo ""
    echo "############################ 软件检查 ############################"
    if [[ $ver == "CentOS" ]];then
        rpm -qa --last | head | column -t 
    elif [[ $ver == "Ubuntu" ]];then
        dpkg -l 
    fi
}

Get_Process_Status(){
    echo ""
    echo ""
    echo "############################ 进程检查 ############################"
    echo "内存占用TOP10"
    echo "-------------"
    echo  "PID %MEM RSS COMMAND
    $(ps aux | awk '{print $2, $4, $6, $11}' | sort -k3rn | head -n 10 )" | column -t
    echo ""
    echo "CPU占用TOP10"
    echo "------------"
    top b -n1 | head -17 | tail -11
}

Get_Process_Udevs_Status(){
    #特殊进程判断入口
    if [ $(ps axu | grep udevs | grep -v grep | wc -l) -ge 1 ];then
        echo ""
        echo "特殊进程";
        echo "--------"
        ps -ef | head -n1
        ps axu | grep udevs | grep -v grep
        return 1 #如果进入了循环代表有特殊的进程，返回错误值1
    else
        return 0
    fi
}

Get_Process_Sgagent_Status(){
    #sgagent 监控组件是否安装和运行检测入口
    if [ $(ps axu | grep sgagent | grep -v grep | wc -l) -ge 1 ];then
        sgagentStatus="存在"
        echo "sgagent进程："
        ps ax | grep sgagent
        return 0
    else
        sgagentStatus="不存在"
        echo "sgagent进程不存在。"
        return 1
    fi
}

Get_Process_Barad_Status(){
    #barad_agent
    if [ $(ps -ef | grep   barad_agent | grep -v grep | wc -l) -ge 1 ];then
        baradStatus="存在"
        echo " barad_agent进程："
        ps ax | grep barad_agent
        return 0
    else
        baradStatus="不存在"
        echo "barad_agent进程不存在，请检查。"
        return 1
    fi
}

Get_Process_Defunct_Status(){
#僵尸进程
    if [ $(ps -ef | grep defunct | grep -v grep | wc -l) -ge 1 ];then
        echo ""
        echo "僵尸进程";
        echo "--------"
        ps -ef | head -n1
        ps -ef | grep defunct | grep -v grep
        defunct=$(ps -ef | grep defunct | grep -v grep)
        return 1
    fi
}

Get_Firewall_Status(){
#防火墙策略保存
    iptables-save > $Iptables_log_file
}

Get_State(){
#用于函数Get_NTP_Status,获取ntp的服务状态
    if [[ $ver == "Ubuntu" ]]; then
        if [ `/etc/init.d/ntp status | grep running | wc -l` -ge 1 ]; then
            r="active"
        else
            r="inactive"
        fi
    elif [[ $ver == "CentOS" ]]; then
        r="$(systemctl is-active $1 2>&1)"
    else
        r="Get_State.Get_OS：ERROR"
    fi
    echo "$r"
}

Get_NTP_Status(){
    #NTP服务状态，当前时间，配置等
    echo ""
    echo ""
    echo "############################ NTP检查 #############################"
    if [ -e /etc/ntp.conf ];then
        echo "服务状态：$(Get_State ntpd)"
        echo ""
        echo "/etc/ntp.conf"
        echo "-------------"
        cat /etc/ntp.conf 2>/dev/null | grep -v "^#" | sed '/^$/d'
    fi
    ntpdate=$(date +"%Y-%m-%d %H:%M.%S")
    echo "执行脚本时的时间：$ntpdate"
    ntpq -p 
}

Get_K8s_Node_Status(){
    echo ""
    echo ""
    #检查集群node状态
    NotReadyNode=$(kubectl get node | grep NotReady | awk '{print $1}' |tr '\n' ',' | sed 's/,$//')
    if [[ $(kubectl get node | grep NotReady | wc -l) -ge 1 ]];then
        echo "集群NotReady，请检查集群"
        return 1
    else
        return 0
    fi
}

Get_K8s_Node_Basis_Status(){
    echo "########################### 获取k8s部分信息 ############################" 
    echo "kubectl get node -o wide" 
    kubectl get node -o wide
    echo ""
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' 
    echo "节点状态概览："
    kubectl get nodes -o jsonpath="$JSONPATH" 
    echo ""
    echo "kubectl get pods --all-namespaces -o wide" 
    kubectl get pods --all-namespaces -o wide
    echo ""
    echo "kubectl get service"
    kubectl get service --all-namespaces
    echo ""
    echo "kubectl get hpa"
    kubectl get hpa --all-namespaces >/dev/null 2>&1
    echo ""
    echo "kubectl get deploy --all-namespaces"
    kubectl get deploy --all-namespaces
    echo ""
    echo "kubectl get rs --all-namespaces"
    kubectl get rs --all-namespaces
    echo ""
    echo "kubectl version"
    kubectl version
    echo ""
    echo "kubectl api-versions"
    kubectl api-versions
    echo ""
    echo "kubectl get event --all-namespaces"
    kubectl get event --all-namespaces
    echo ""
    echo "获取node的资源使用情况"
    echo ""
    nodes=$(kubectl get node --no-headers -o custom-columns=NAME:.metadata.name)
    for node in $nodes; do
    echo "Node: $node"
    kubectl describe node "$node" | sed '1,/Non-terminated Pods/d'
    echo
    done
    kubectl describe node > $DescribeNode_log_file
    kubectl cluster-info dump --output-directory="$LOGPATH/cluster-dump" -o yaml -n kube-system
}

Get_K8s_Components_Status(){
    #检查组件的日志
    journalctl --since "2 day ago" -l -u kubelet > $Kubelet_log_file
    journalctl --since "2 day ago" -l -u kube-proxy > $KubeProxy_log_file
    journalctl --since "2 day ago" -l -u dockerd  > $Docker_log_file
}

Get_Docker_Status(){
    echo ""
    echo ""
    echo "############################ 检查docker #############################"
    systemctl status dockerd
    echo
    echo "docker version"
    docker version
    echo ""
    echo "docker info"
    docker info
}

Get_Http_Proxy(){
    echo ""
    echo ""
    echo "############################ 检查/etc/profile中是否有配置http proxy#############################"
    if [[ $(cat /etc/profile | grep http | wc -l ) -ge 1 ]];then
        echo "/etc/profile 中可能有设置http proxy,请检查是否配置了代理服务器"
        return 1
    else
        echo "/etc/profile未发现异常"
        return 0
    fi
}
speedtest(){
    echo "############################ 测速 #############################"
    # wget https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py 
    # chmod +x speedtest.py
    # echo "开始测速"
    # python speedtest.py --simple
    echo "ping -c 5 www.baidu.com"
    ping -c 5 www.baidu.com
    echo
}
centos72(){
    echo "######## 系统初始化过程的某些配置文件 ########"
    echo
    echo "文件描述符的最大值 /etc/security/limits.conf"
    softnofile=$(cat /etc/security/limits.conf  | grep 'root soft nofile' | awk '{print $4}')
    if [ $softnofile != 100001 ];then
        echo "root soft nofile被修改"
        echo "现值:root soft nofile:"$softnofile
    else
        echo "root soft nofile:"$softnofile
    fi
    hardnofile=$(cat /etc/security/limits.conf  | grep 'root hard nofile' | awk '{print $4}')
    if [ $hardnofile != 100002 ];then
        echo "root hard nofile被修改"
        echo "现值:root hard nofile:"$hardnofile
    else
        echo "root hard nofile:"$hardnofile
    fi
    echo
    echo "history 配置 /etc/bashrc"
    cat /etc/bashrc | grep export
    echo
    echo "selinux  配置 /etc/selinux/config"
    selinuxstatus=$(cat /etc/selinux/config | grep SELINUX= | grep -v '#' | cut -d '=' -f2)
    if [ $selinuxstatus != 'disabled' ];then
        echo "selinux被修改，请检查"
        echo "现值:SELINUX="$selinuxstatus
    else
        echo "SELINUX="$selinuxstatus
    fi
    echo
    echo "/etc/sysconfig/network-scripts/ifcfg-eth0中clear_NM_control 的值展示"
    nmcontrolled=$(cat /etc/sysconfig/network-scripts/ifcfg-eth0 | grep NM_CONTROLLED | cut -d '=' -f2)
    echo "NM_CONTROLLED="$nmcontrolled
    
    echo
    echo "systemd 配置"
    timeoutstartsec=$(cat /etc/systemd/system/rc-local.service | grep TimeoutStartSec | cut -d '=' -f2)
    if [ $timeoutstartsec != 0  ];then
        echo "TimeoutStartSec被修改"
        echo "TimeoutStartSec="$timeoutstartsec
    else
        echo "TimeoutStartSec="$timeoutstartsec
    fi
    timeoutstopsec=$(cat /etc/systemd/system/rc-local.service | grep TimeoutStopSec | cut -d '=' -f2)
    if [ $timeoutstopsec != 30 ];then
        echo "TimeoutStopSec被修改"
        echo "TimeoutStopSec="$timeoutstopsec
    else
        echo "TimeoutStopSec="$timeoutstopsec
    fi
    defaulttimeoutstopsec=$(cat /etc/systemd/system.conf | grep DefaultTimeoutStopSec | cut -d '=' -f2)
    if [ $defaulttimeoutstopsec != '30s' ];then
        echo "DefaultTimeoutStopSec被修改"
        echo "现值为：DefaultTimeoutStopSec="$defaulttimeoutstopsec
    else
        echo "DefaultTimeoutStopSec="$defaulttimeoutstopsec
    fi
    echo
    echo "sshd_config 配置 "
    usedns=$(cat /etc/ssh/sshd_config | grep UseDNS | awk '{print $2}')
    if [ $usedns == 'no' ];then
        echo "usedns" $usedns
    else
        echo "/etc/ssh/sshd_config 被修改"
    fi
    echo
    echo "密码最小长度"
    cat /etc/login.defs | grep PASS_MIN_LEN | grep -v '#'
    echo
    echo "Nouveau kernel driver配置"
    cat /etc/modprobe.d/nvidia-installer-disable-nouveau.conf
    echo
    
}

Get_pid_status(){
    max_pid=$(cat /proc/sys/kernel/pid_max)
    current_pid=$(ps -eLf | wc -l)
    if [ $current_pid -gt $max_pid ]; then
        echo "当前实际pid数量 $current_pid,已超过全局PID限制 $max_pid";
    else
        echo "当前实际pid数量 $current_pid,全局PID限制 $max_pid";
    fi
}

Get_inotify_Watch(){
# This script shows processes holding the inotify fd, alone with HOW MANY directories each inotify fd watches(0 will be ignored).
echo "############################shows processes holding the inotify fd"
total=0
result="EXE PID FD-INFO INOTIFY-WATCHES\n"
while read pid fd; do \
  exe="$(readlink -f /proc/$pid/exe || echo n/a)"; \
  fdinfo="/proc/$pid/fdinfo/$fd" ; \
  count="$(grep -c inotify "$fdinfo" || true)"; \
  if [ $((count)) != 0 ]; then
    total=$((total+count)); \
    result+="$exe $pid $fdinfo $count\n"; \
  fi
done <<< "$(lsof +c 0 -n -P -u root|awk '/inotify$/ { gsub(/[urw]$/,"",$4); print $2" "$4 }')" && echo "total $total inotify watches" && result="$(echo -e $result|column -t)\n" && echo -e "$result" | head -1 && echo -e "$result" | sed "1d" | sort -k 4rn;
}

tarlog(){
    tarname=tkelog-`date +%Y%m%d-%H.%M.%S`.tar.gz
    #打包日志
    if [[ $ver == "CentOS" ]];then
        cd $MESSAGESPATH && tar --warning=no-file-changed -czf messages.tar.gz messages
        cd $MESSAGESPATH && mv messages.tar.gz $LOGPATH/.
    elif [[ $ver == "Ubuntu" ]];then
        cd $MESSAGESPATH && tar --warning=no-file-changed -czf syslog.tar.gz syslog
        cd $MESSAGESPATH && mv syslog.tar.gz $LOGPATH/.
    else
    #tlinux暂缓之计
        cd $MESSAGESPATH && tar --warning=no-file-changed -czf messages.tar.gz messages
        cd $MESSAGESPATH && mv messages.tar.gz $LOGPATH/.
    fi
    cd $LOGPATH && dmesg -T > dmesg.log
    cd $LOGPATH && sudo sysctl -a > sysctl 2>& 1
    cd $LOGPATH && tar -czf $tarname *
    #日志已打包，删除相关的log，只剩下tkelog.tar
    rm -rf $LOGPATH/*.log && rm -rf $LOGPATH/baladlog*
    rm -rf $LOGPATH/messages.tar.gz
    rm -rf $LOGPATH/syslog.tar.gz
    rm -rf $LOGPATH/sysctl
    rm -rf $LOGPATH/cluster-dump
}

Globalcheck(){
    Get_Os
    Check_dir
    
    Get_System_Status >> $RESULTFILE
    Get_System_StatusCode=$?
    if [ $Get_System_StatusCode -eq 0 ];then
        info "系统基础信息:$ver $Kernel"
    else
        warn "收集系统基础信息失败...×" 
    fi
    
    KUBE_RESERVED
    info "kubelet CPU预留资源:$kubeReservedcpu"m" Mem预留资源:$kubeReservedmemory"Mi""  
    
    Get_Cpu_Status >> $RESULTFILE
    Get_Cpu_StatusCode=$?
    if [ $Get_Cpu_StatusCode -eq 0 ];then
        info "正在收集CPU基础信息...CPU型号:$CPU_Type"   
    else
        info "收集基础CPU失败...×"   
    fi
    Get_Mem_Status >> $RESULTFILE
    Get_Mem_StatusCode=$?
    if [ $Get_Mem_StatusCode -eq 0 ];then
        info "内存基本使用情况:$MemStatus"   
    else
        warn "收集内存信息失败...×"   
    fi
    Get_Disk_Status >> $RESULTFILE
    Get_Disk_StatusCode=$?
    if [ $Get_Disk_StatusCode -eq 0 ];then
        info "正在收集磁盘基础状态...√ 部分展示：磁盘使用率:$diskuse 卷名:$mountname "   
    else
        info "收集磁盘异常...×"   
    fi
    Get_inotify_Watch >>$RESULTFILE
    Get_Disk_Indoe_Status >> $RESULTFILE
    Get_Disk_Indoe_StatusCode=$?
    case $Get_Disk_Indoe_StatusCode in 
    0)pass "当前磁盘indoe数正常...√" ;;
    1)warn "磁盘indoe使用率过高请检查...×"  ;;	
    esac
    Get_Disk_Use_Status >> $RESULTFILE
    Get_Disk_Use_StatusCode=$?
    case $Get_Disk_Use_StatusCode in 
    0)pass "当前磁盘使用率正常...√"   ;;
    1)warn "当前磁盘使用率过高请检查...×"  ;;    
    esac
    Get_Network_Status >> $RESULTFILE
    Get_Network_StatusCode=$?
    case $Get_Network_StatusCode in
    0)info "基础网络信息:$ipmessages" ;;
    1)warn "当前的DNS异常：$DNS...×"  ;;
    esac
    Get_Route_Status >> $RESULTFILE
    Get_Route_StatusCode=$?
    if [ $Get_Route_StatusCode -eq 0 ];then
        info "正在收集路由...√"    
    else
        warn "收集路由异常...×"   
    fi	
    Get_Listen_Status >> $RESULTFILE
    Get_Listen_StatusCode=$?
    if [ $Get_Listen_StatusCode -eq 0 ];then
        info "正在收集监听...√"   
    else
        info "收集监听异常...×"   
    fi	
    Get_Netstat_Status >> $Netstat_log_file
    Get_Process_Status >> $RESULTFILE
    Get_Process_StatusCode=$?
    case $Get_Process_Status in
    0)info "收集内存TOP10的进程...√"  ;;
    1)warn "收集内存TOP10进程失败...×"   ;;
    esac
    Get_pid_status >> $RESULTFILE
    Get_pid_statusCode=$?
    case $Get_pid_statusCode in
    0)info "收集内存TOP10的进程...√"  ;;
    1)warn "收集内存TOP10进程失败...×"   ;;
    esac
    Get_Process_Udevs_Status >> $RESULTFILE
    Get_Process_Udevs_StatusCode=$?
    case $Get_Process_Udevs_StatusCode in
    0)pass "检查是否有特殊进程... 无特殊进程√"  ;;
    1)warn "检查发现有特殊进程，请排查...×"   ;;
    esac
    Get_Process_Barad_Status >> $RESULTFILE
    Get_Process_Barad_StatusCode=$?
    case $Get_Process_Barad_StatusCode in
    0)pass "检查巴拉多进程是否存在... $baradStatus √"  ;;
    1)warn "检查发现巴拉多进程 $baradStatus ×"   ;;
    esac
    Get_Process_Sgagent_Status >> $RESULTFILE
    Get_Process_Sgagent_StatusCode=$?
    case $Get_Process_Sgagent_StatusCode in
    0)pass "检查Sgagent进程是否存在... $sgagentStatus √"  ;;
    1)warn "Sgagent进程不存在... $sgagentStatus ×"   ;;
    esac
    Get_Process_Defunct_Status >> $RESULTFILE
    Get_Process_Defunct_StatusCode=$?
    case $Get_Process_Defunct_StatusCode in
    0)pass "检查是否含有僵尸进程...未发现僵尸进程√"  ;;
    1)warn "发现含有僵尸进程,请检查...× $defunct"   ;;
    esac
    Get_Service_Status >> $RESULTFILE
    Get_Service_StatusCode=$?
    if [ $Get_Service_StatusCode -eq 0 ];then
        info "正在收集服务状态...√"   
    else
        warn "收集服务状态异常...×"   
    fi
    Get_Login_Status >> $RESULTFILE
    Get_Login_StatusCode=$?
    if [  $Get_Login_StatusCode -eq 0 ];then
        info "正在收集登录记录...√"   
    else
        warn "收集登录记录异常...×"   
    fi
    Get_User_Status >> $RESULTFILE
    Get_User_StatusCode=$?
    if [ $Get_User_StatusCode -eq 0 ];then
        info "正在收集用户状态...√"   
    else
        warn "收集用户状态异常...×"   
    fi
    Get_Sudoers_Status >> $RESULTFILE
    Get_Sudoers_StatusCode=$?
    if [ $Get_Sudoers_StatusCode -eq 0 ];then
        info "正在收集Sudoers...√"   
    else
        warn "收集Sudoers异常...×"  
    fi
    Get_Firewall_Status >> $RESULTFILE
    Get_Firewall_StatusCode=$?
    case $Get_Firewall_StatusCode in
    0)info "正在收集防火墙规则 ...√"  ;;
    1)warn "收集防火墙失败...×"   ;;
    esac
    Get_NTP_Status >> $RESULTFILE
    Get_NTP_StatusCode=$?
    case $Get_NTP_StatusCode in
    0)info "正在检查NTP状态 ...√"  ;;
    1)warn "检查NTP状态异常...×"   ;;
    esac
    Get_Installed_Status >> $RESULTFILE
    Get_Installed_StatusCode=$?
    case $Get_Installed_StatusCode in
    0)info "正在检查已安装软件...√"  ;;
    1)warn "检查安装软件异常...×"   ;;
    esac
    Get_K8s_Node_Status >> $RESULTFILE
    Get_K8s_Node_StatusCode=$?
    case $Get_K8s_Node_StatusCode in
    0)pass "集群运行状态正常...√"  ;;
    1)warn "集群$NotReadyNode:NotReday...×"   ;;
    esac
    Get_K8s_Node_Basis_Status >> $RESULTFILE
    Get_K8s_Node_Basis_StatusCode=$?
    if [ $Get_K8s_Node_Basis_StatusCode -eq 0 ];then
        info "收集k8s基础信息...√"   
    else
        warn "收集K8s基础信息异常...×"  
    fi
    case $Get_Installed_StatusCode in
    0)info "收集k8s版本号,api和基础信息...√"  ;;
    1)warn "收集k8s版本号,api和基础信息失败...×"   ;;
    esac
    Get_K8s_Components_Status >> $RESULTFILE
    Get_K8s_Components_StatusCode=$?
    case $Get_K8s_Components_StatusCode in
    0)info "正在收集k8s组件日志...√"  ;;
    1)warn "收集k8s组件日志异常...×"   ;;
    esac
    Get_Docker_Status >> $RESULTFILE
    Get_Docker_StatusCode=$?
    if [ $Get_Docker_StatusCode -eq 0 ];then
        info "正在收集docker...√"    
    else
        warn "收集Docker异常...×"  
    fi
    Get_Http_Proxy >> $RESULTFILE
    Get_Http_ProxyCode=$?
    case $checkHttpProxyCode in
    0)info "正在检查是否配置http proxy...√"   ;;
    1)warn "检查http proxy 异常...×"   ;;
    esac
    speedtest >> $RESULTFILE
    if [[ $ver == "CentOS" ]];then
        centos72 >> $RESULTFILE
    elif [[ $ver == "Ubuntu" ]];then
        echo 
    fi
    
    tarlog
    tarlogCode=$?
    if [ $tarlogCode -eq 0 ];then
        info "正在打包日志文件~~~"   
    else
        warn "打包文件异常...×"   
    fi
}

yell_info() {
yell "# ------------------------------------------------------------------------------
# v$version ,当前集群：$clusterid
# 您好！本脚本纯shell编写，用于收集系统日志以及相关服务、组件日志等，
#
# 目前兼容TKE的Ubuntu、Centos，脚本开源，您可以用编辑器打开脚本查阅里面的代码。
#
# 确认脚本无误后，放到TKE集群节点上运行。
#
# 成功后，请把/tmp/tkelog/tkelog.tar.gz打包文件发我们进行问题排查，感谢您的支持！
# ------------------------------------------------------------------------------"
}
yell_info

while true; do
 read -p"继续请输(y)退出请输(n)：" yn
 case $yn in
 [Yy]* ) Globalcheck; break;;
 [Nn]* ) echo "goodbye~";exit;;
 * ) echo "输入有误，请输入yes/y/no/n";;
 esac
done

info "检查结果已放置在：$LOGPATH/$tarname"  
info "详细结果可看$RESULTFILE"  

