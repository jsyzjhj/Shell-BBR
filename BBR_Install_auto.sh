#!/bin/bash

function Colorset() {
  #颜色配置
  echo=echo
  for cmd in echo /bin/echo; do
    $cmd >/dev/null 2>&1 || continue
    if ! $cmd -e "" | grep -qE '^-e'; then
      echo=$cmd
      break
    fi
  done
  CSI=$($echo -e "\033[")
  CEND="${CSI}0m"
  CDGREEN="${CSI}32m"
  CRED="${CSI}1;31m"
  CGREEN="${CSI}1;32m"
  CYELLOW="${CSI}1;33m"
  CBLUE="${CSI}1;34m"
  CMAGENTA="${CSI}1;35m"
  CCYAN="${CSI}1;36m"
  CSUCCESS="$CDGREEN"
  CFAILURE="$CRED"
  CQUESTION="$CMAGENTA"
  CWARNING="$CYELLOW"
  CMSG="$CCYAN"
}

function Logprefix() {
  #输出log
  echo -n ${CGREEN}'CraftYun >> '
}

function Checksystem() {
  cd
  Logprefix;echo ${CMSG}'[Info]检查系统'${CEND}
  #检查系统
  if [[ $(id -u) != '0' ]]; then
    Logprefix;echo ${CWARNING}'[Error]请使用root用户安装!'${CEND}
    exit
  fi

  if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
    DISTRO='CentOS'
  else
    DISTRO='unknow'
  fi

  if [[ ${DISTRO} == 'unknow' ]]; then
    Logprefix;echo ${CWARNING}'[Error]请使用Centos系统安装!'${CEND}
    exit
  fi

  if grep -Eqi "release 5." /etc/redhat-release; then
      RHEL_Version='5'
  elif grep -Eqi "release 6." /etc/redhat-release; then
      RHEL_Version='6'
  elif grep -Eqi "release 7." /etc/redhat-release; then
      RHEL_Version='7'
  fi

  if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
      OS_Bit='64'
  else
      OS_Bit='32'
  fi
}

function Coloseselinux() {
  #关闭selinux
  Logprefix;echo ${CMSG}'[Info]关闭Selinux'${CEND}
  [ -s /etc/selinux/config ] && sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	setenforce 0 >/dev/null 2>&1
}

function Yumupdate() {
  #升级系统软件
  #Logprefix;echo ${CMSG}'[Info]升级系统软件,可能需要花费较长时间，请耐心等待'${CEND}
  #yum -y update
}

function Installbasesoftware() {
  #安装基础软件
  Logprefix;echo ${CMSG}'[Info]安装基础软件'${CEND}
  Logprefix;echo ${CMSG}'[Info]安装epel源'${CEND}
  yum -y install epel-release
  Logprefix;echo ${CMSG}'[Info]安装wget'${CEND}
  yum -y install wget
  Logprefix;echo ${CMSG}'[Info]安装lrzsz'${CEND}
  yum -y install lrzsz
  Logprefix;echo ${CMSG}'[Info]安装zip unzip'${CEND}
  yum -y install unzip zip
  Logprefix;echo ${CMSG}'[Info]安装Development Tools'${CEND}
  yum -y groupinstall "Development Tools"
}

function Askuser() {
  Logprefix;echo ${CMSG}'[Info]提示:按下回车键开始，或使用CTRL+C退出'${CEND}
  read
  InstallKernel
  InstallBBR
  Kernel_Optimize
}

function Kernel_Optimize() {
  Logprefix;echo ${CMSG}'[Info]优化内核参数'${CEND}
  echo 'net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_wmem = 8192 4336600 873200
net.ipv4.tcp_rmem = 32768 4336600 873200
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_synack_retries = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 786432 1048576 1572864
net.ipv4.tcp_fin_timeout = 30
#net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.ip_local_port_range = 1024 65000' >> /etc/sysctl.conf
  sysctl -p
  Logprefix;echo ${CMAGENTA}'[Success]优化完成'${CEND}
}

function InstallKernel() {
  Coloseselinux
  Installbasesoftware
  Yumupdate
  # 安装内核
  Logprefix;echo ${CMSG}'[Info]安装kernel'${CEND}
  rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

  if grep -Eqi "release 5." /etc/redhat-release; then
	  Logprefix;echo ${CWARNING}'[Error]请使用Centos6或7安装!'${CEND}
	  exit
  elif grep -Eqi "release 6." /etc/redhat-release; then
      rpm -Uvh 'http://www.elrepo.org/elrepo-release-6-8.el6.elrepo.noarch.rpm'
  elif grep -Eqi "release 7." /etc/redhat-release; then
      rpm -Uvh 'http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm'
  fi
  
  # 安装内核
  yum -y remove kernel-headers
  yum -y --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers kernel-ml-devel
  # 设置启动顺序
  grub2-set-default 0
}

function InstallBBR() {
  echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
  echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
  sysctl -p
  lsmod | grep bbr
  Logprefix;echo ${CMAGENTA}'[Success]安装完成'${CEND}
}

Colorset
Checksystem

#安装开始
Askuser
