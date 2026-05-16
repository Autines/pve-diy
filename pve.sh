#!/bin/bash 
####
# 2024 https://github.com/shidahuilang/pve
# 2025 https://github.com/xiangfeidexiaohuo/pve-diy
####

# PVE语言设置
pvelocale(){
	sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen && TIME g "PVE语言包设置完成!"
}
if [ `export|grep 'LC_ALL'|wc -l` = 0 ];then
	pvelocale
	if [ `grep "LC_ALL" /etc/profile|wc -l` = 0 ];then
		echo "export LC_ALL='en_US.UTF-8'" >> /etc/profile
		echo "export LANG='en_US.UTF-8'" >> /etc/profile
	fi
fi
if [ `grep "alias ll" /etc/profile|wc -l` = 0 ];then
	echo "alias ll='ls -alh'" >> /etc/profile
	echo "alias sn='snapraid'" >> /etc/profile
fi
source /etc/profile
# pause
pause(){
    read -n 1 -p " 按任意键继续... " input
    if [[ -n ${input} ]]; then
        echo -e "\b\n"
    fi
}

# 字体颜色设置
TIME() {
[[ -z "$1" ]] && {
	echo -ne " "
} || {
	 case $1 in
	r) export Color="\e[31;1m";;
	g) export Color="\e[32;1m";;
	b) export Color="\e[34;1m";;
	y) export Color="\e[33;1m";;
	z) export Color="\e[35;1m";;
	l) export Color="\e[36;1m";;
	  esac
	[[ $# -lt 2 ]] && echo -e "\e[36m\e[0m ${1}" || {
		echo -e "\e[36m\e[0m ${Color}${2}\e[0m"
	 }
	  }
}


#--------------PVE更换软件源----------------
# apt国内源
aptsources() {
	sver=`cat /etc/debian_version |awk -F"." '{print $1}'`
	case "$sver" in
 	13 )
  		sver="trixie"
 	;;
 	12 )
  		sver="bookworm"
 	;;
	11 )
		sver="bullseye"
	;;
	10 )
		sver="buster"
	;;
	9 )
		sver="stretch"
	;;
	8 )
		sver="jessie"
	;;
	7 )
		sver="wheezy"
	;;
	6 )
		sver="squeeze"
	;;
	* )
		sver=""
	;;
	esac
	if [ ! $sver ];then
		TIME r "您的版本不支持！"
		exit 1
	fi

	[[ -e /etc/apt/sources.list ]] && cp -rf /etc/apt/sources.list /etc/apt/backup/sources.list.bak
	[[ -e /etc/apt/sources.list.d/debian.sources ]] && mv /etc/apt/sources.list.d/debian.sources /etc/apt/backup/debian.sources.bak

	echo " 请选择您需要的apt国内源"
	echo " 1. 清华大学镜像站"
	echo " 2. 中科大镜像站"
	input="请输入选择[默认1]"
	while :; do
	read -t 30 -p " ${input}： " aptsource || echo
	aptsource=${aptsource:-1}
	case $aptsource in
	1)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver} main contrib non-free non-free-firmware
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver}-updates main contrib non-free non-free-firmware
		deb https://mirrors.tuna.tsinghua.edu.cn/debian/ ${sver}-backports main contrib non-free non-free-firmware
		deb https://mirrors.tuna.tsinghua.edu.cn/debian-security ${sver}-security main contrib non-free non-free-firmware
	EOF
	break
	;;
	2)
	cat > /etc/apt/sources.list <<-EOF
		deb https://mirrors.ustc.edu.cn/debian/ ${sver} main contrib non-free non-free-firmware
		deb https://mirrors.ustc.edu.cn/debian/ ${sver}-updates main contrib non-free non-free-firmware
		deb https://mirrors.ustc.edu.cn/debian/ ${sver}-backports main contrib non-free non-free-firmware
		deb https://mirrors.ustc.edu.cn/debian-security/ ${sver}-security main contrib non-free non-free-firmware
	EOF
	break
	;;
	*)
	TIME r "请输入正确编码！"
	;;
	esac
	done
	TIME g "apt源，更换完成!"
}
# CT模板国内源
ctsources() {
    [[ -e /usr/share/perl5/PVE/APLInfo.pm ]] && cp -rf /usr/share/perl5/PVE/APLInfo.pm /etc/apt/backup/APLInfo.pm.bak
    [[ -e /var/lib/pve-manager/apl-info/download.proxmox.com ]] && cp -rf /var/lib/pve-manager/apl-info/download.proxmox.com /etc/apt/backup/download.proxmox.com.bak
	echo " 请选择您需要的CT模板国内源"
	echo " 1. 清华大学镜像站"
	echo " 2. 中科大镜像站"
	input="请输入选择[默认1]"
	while :; do
	read -t 30 -p " ${input}： " ctsource || echo
	ctsource=${ctsource:-1}
	case $ctsource in
	1)
	sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
	sed -i 's|http://mirrors.ustc.edu.cn/proxmox|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
    pveam update
	break
	;;
	2)
	sed -i 's|http://download.proxmox.com|http://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
	sed -i 's|https://mirrors.tuna.tsinghua.edu.cn/proxmox|http://mirrors.ustc.edu.cn/proxmox|g' /usr/share/perl5/PVE/APLInfo.pm
    pveam update
	break
	;;
	*)
	TIME r "请输入正确编码！"
	;;
	esac
	done
	TIME g "CT模板源，更换完成!"
}
# 更换使用帮助源
pvehelp(){
	[[ ! -d /etc/apt/sources.list.d ]] && mkdir -p /etc/apt/sources.list.d
	[[ -e /etc/apt/sources.list.d/ceph.sources ]] && mv /etc/apt/sources.list.d/ceph.sources /etc/apt/backup/ceph.sources.bak
	[[ -e /etc/apt/sources.list.d/ceph.list ]] && mv /etc/apt/sources.list.d/ceph.list /etc/apt/backup/ceph.list.bak

    [[ -e /etc/apt/sources.list.d/pve-no-subscription.list ]] && cp -rf /etc/apt/sources.list.d/pve-no-subscription.list /etc/apt/backup/pve-no-subscription.list.bak

	cat > /etc/apt/sources.list.d/pve-no-subscription.list <<-EOF
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian ${sver} pve-no-subscription
EOF
	TIME g "使用帮助源，更换完成!"
}
# 关闭企业源
pveenterprise(){
	if [[ -e /etc/apt/sources.list.d/pve-enterprise.sources ]];then
		mv /etc/apt/sources.list.d/pve-enterprise.sources /etc/apt/backup/pve-enterprise.sources.bak
		TIME g "企业源pve-enterprise.sources已移除完成!"
	else
		TIME g "企业源pve-enterprise.sources不存在，忽略!"
	fi

	if [[ -e /etc/apt/sources.list.d/pve-enterprise.list ]];then
		mv /etc/apt/sources.list.d/pve-enterprise.list /etc/apt/backup/pve-enterprise.list.bak
		TIME g "企业源pve-enterprise.list已移除完成!"
	else
		TIME g "企业源pve-enterprise.list不存在，忽略!"
	fi
}
# 移除无效订阅
novalidsub(){
	# 移除 Proxmox VE 无有效订阅提示 (6.4-5、6、8、9 、13；7.0-9、10、11已测试通过)
	cp -rf /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js.bak
	sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	# sed -i 's#if (res === null || res === undefined || !res || res#if (false) {#g' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	# sed -i '/data.status.toLowerCase/d' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
	TIME g "已移除订阅提示!"
}
pvegpg(){
	[[ -e /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg ]] && mv /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg /etc/apt/backup/proxmox-release-${sver}.gpg.bak
	wget -q --timeout=5 --tries=1 --show-progres http://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/proxmox-release-${sver}.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg
	if [[ $? -ne 0 ]];then
		TIME r "尝试重新下载..."
		wget -q --timeout=5 --tries=1 --show-progres https://raw.githubusercontent.com/xiangfeidexiaohuo/pve-diy/master/gpg/proxmox-release-${sver}.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-${sver}.gpg
			if [[ $? -ne 0 ]];then
				TIME r "下载秘钥失败，请检查网络再尝试!"
				sleep 2
				exit 1
		else
			TIME g "密匙下载完成!"
			fi
	else
		TIME g "密匙下载完成!"	
	fi
}
pve_optimization(){
	echo
	clear
	TIME y "提示：PVE原配置文件放入/etc/apt/backup文件夹"
	[[ ! -d /etc/apt/backup ]] && mkdir -p /etc/apt/backup
	echo
	TIME y "※※※※※ 更换apt源... ※※※※※"
	aptsources
	echo
	TIME y "※※※※※ 更换CT模板源... ※※※※※"
	ctsources
	echo
	TIME y "※※※※※ 更换使用帮助源... ※※※※※"
	pvehelp
	echo
	TIME y "※※※※※ 关闭企业源... ※※※※※"
	pveenterprise
	echo
	TIME y "※※※※※ 移除 Proxmox VE 无有效订阅提示... ※※※※※"
	novalidsub
	echo
	TIME y "※※※※※ 下载 Proxmox VE 源的密匙... ※※※※※"
	pvegpg
	echo
	TIME y "※※※※※ 重新加载服务配置文件、重启web控制台... ※※※※※"
	systemctl daemon-reload && systemctl restart pveproxy.service && TIME g "服务重启完成!"
	sleep 3
	echo
	TIME y "※※※※※ 更新源、更新常用软件和升级... ※※※※※"
	# apt-get update && apt-get install -y net-tools curl git
	# apt-get dist-upgrade -y
	TIME g "更新源命令：apt-get update -y"
	TIME g "更新软件包命令：apt-get upgrade -y"
	TIME g "更新PVE命令：apt-get dist-upgrade -y"
	echo
	TIME g "修改完毕！"
}
#--------------PVE更换软件源----------------



#---------PVE8/9添加ceph-squid源-----------
pve9_ceph(){
	sver=`cat /etc/debian_version |awk -F"." '{print $1}'`
	case "$sver" in
 	13 )
  		sver="trixie"
 	;;
 	12 )
  		sver="bookworm"
 	;;
	* )
		sver=""
	;;
	esac
	if [ ! $sver ];then
		TIME r "版本不支持！"
		exit 1
	fi

	TIME g "ceph-squid目前仅支持PVE8和9！"
	[[ ! -d /etc/apt/backup ]] && mkdir -p /etc/apt/backup
	[[ ! -d /etc/apt/sources.list.d ]] && mkdir -p /etc/apt/sources.list.d

	[[ -e /etc/apt/sources.list.d/ceph.sources ]] && mv /etc/apt/sources.list.d/ceph.sources /etc/apt/backup/ceph.sources.bak
    [[ -e /etc/apt/sources.list.d/ceph.list ]] && mv /etc/apt/sources.list.d/ceph.list /etc/apt/backup/ceph.list.bak

    [[ -e /usr/share/perl5/PVE/CLI/pveceph.pm ]] && cp -rf /usr/share/perl5/PVE/CLI/pveceph.pm /etc/apt/backup/pveceph.pm.bak
	sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/CLI/pveceph.pm

	cat > /etc/apt/sources.list.d/ceph.list <<-EOF
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/ceph-squid ${sver} no-subscription
EOF
	TIME g "添加ceph-squid源完成!"
}
#---------PVE8/9添加ceph-squid源-----------


#---------PVE7/8添加ceph-quincy源-----------
pve8_ceph(){
	sver=`cat /etc/debian_version |awk -F"." '{print $1}'`
	case "$sver" in
 	12 )
  		sver="bookworm"
 	;;
 	11 )
  		sver="bullseye"
 	;;
	* )
		sver=""
	;;
	esac
	if [ ! $sver ];then
		TIME r "版本不支持！"
		exit 1
	fi

	TIME g "ceph-quincy目前仅支持PVE7和8！"
	[[ ! -d /etc/apt/backup ]] && mkdir -p /etc/apt/backup
	[[ ! -d /etc/apt/sources.list.d ]] && mkdir -p /etc/apt/sources.list.d

	[[ -e /etc/apt/sources.list.d/ceph.sources ]] && mv /etc/apt/sources.list.d/ceph.sources /etc/apt/backup/ceph.sources.bak
    [[ -e /etc/apt/sources.list.d/ceph.list ]] && mv /etc/apt/sources.list.d/ceph.list /etc/apt/backup/ceph.list.bak

    [[ -e /usr/share/perl5/PVE/CLI/pveceph.pm ]] && cp -rf /usr/share/perl5/PVE/CLI/pveceph.pm /etc/apt/backup/pveceph.pm.bak
	sed -i 's|http://download.proxmox.com|https://mirrors.tuna.tsinghua.edu.cn/proxmox|g' /usr/share/perl5/PVE/CLI/pveceph.pm

	cat > /etc/apt/sources.list.d/ceph.list <<-EOF
deb https://mirrors.tuna.tsinghua.edu.cn/proxmox/debian/ceph-quincy ${sver} main
EOF
	TIME g "添加ceph-quincy源完成!"
}
#---------PVE7/8添加ceph-quincy源-----------


#---------PVE一键卸载ceph-----------
remove_ceph(){
TIME g "会卸载ceph，并删除所有ceph相关文件！"

systemctl stop ceph-mon.target && systemctl stop ceph-mgr.target && systemctl stop ceph-mds.target && systemctl stop ceph-osd.target
rm -rf /etc/systemd/system/ceph*

killall -9 ceph-mon ceph-mgr ceph-mds ceph-osd
rm -rf /var/lib/ceph/mon/* && rm -rf /var/lib/ceph/mgr/* && rm -rf /var/lib/ceph/mds/* && rm -rf /var/lib/ceph/osd/*

pveceph purge

apt purge -y ceph-mon ceph-osd ceph-mgr ceph-mds
apt purge -y ceph-base ceph-mgr-modules-core

rm -rf /etc/ceph && rm -rf /etc/pve/ceph.conf  && rm -rf /etc/pve/priv/ceph.* && rm -rf /var/log/ceph && rm -rf /etc/pve/ceph && rm -rf /var/lib/ceph

[[ -e /etc/apt/sources.list.d/ceph.sources ]] && mv /etc/apt/sources.list.d/ceph.sources /etc/apt/backup/ceph.sources.bak

TIME g "已成功卸载ceph."
}
#---------PVE一键卸载ceph-----------


#--------------开启硬件直通----------------
# 开启硬件直通
enable_pass(){
	echo
	TIME y "开启硬件直通..."
	if [ `dmesg | grep -e DMAR -e IOMMU|wc -l` = 0 ];then
		TIME r "您的硬件不支持直通！"
		pause
		menu
	fi
	if [ `cat /proc/cpuinfo|grep Intel|wc -l` = 0 ];then
		iommu="amd_iommu=on"
	else
		iommu="intel_iommu=on"
	fi
	if [ `grep $iommu /etc/default/grub|wc -l` = 0 ];then
		sed -i 's|quiet|quiet '$iommu'|' /etc/default/grub
		update-grub
		if [ `grep "vfio" /etc/modules|wc -l` = 0 ];then
			cat <<-EOF >> /etc/modules
				vfio
				vfio_iommu_type1
				vfio_pci
				vfio_virqfd
				kvmgt
			EOF
		fi
		
	if [ ! -f "/etc/modprobe.d/blacklist.conf" ];then
       echo "blacklist snd_hda_intel" >> /etc/modprobe.d/blacklist.conf 
       echo "blacklist snd_hda_codec_hdmi" >> /etc/modprobe.d/blacklist.conf 
       echo "blacklist i915" >> /etc/modprobe.d/blacklist.conf 
       fi


    if [ ! -f "/etc/modprobe.d/vfio.conf" ];then
      echo "options vfio-pci ids=8086:3185" >> /etc/modprobe.d/vfio.conf
       fi	
		TIME g "开启设置后需要重启系统，请稍后重启。"
	else
		TIME r "您已经配置过!"
	   fi

}
# 关闭硬件直通
disable_pass(){
	echo
	TIME y "关闭硬件直通..."
	if [ `dmesg | grep -e DMAR -e IOMMU|wc -l` = 0 ];then
		TIME r "您的硬件不支持直通！"
		pause
		menu
	fi
	if [ `cat /proc/cpuinfo|grep Intel|wc -l` = 0 ];then
		iommu="amd_iommu=on"
	else
		iommu="intel_iommu=on"
	fi
	if [ `grep $iommu /etc/default/grub|wc -l` = 0 ];then
		TIME r "您还没有配置过该项"
	else
		{
			sed -i 's/ '$iommu'//g' /etc/default/grub
			sed -i '/vfio/d' /etc/modules
			rm -rf /etc/modprobe.d/blacklist.conf
			rm -rf /etc/modprobe.d/vfio.conf
			sleep 1
		}|TIME g "关闭设置后需要重启系统，请稍后重启。"
		sleep 1
		update-grub
	fi
}
# 硬件直通菜单
hw_passth(){
	while :; do
		clear
		cat <<-EOF
`TIME y "	      配置硬件直通"`
┌──────────────────────────────────────────┐
    1. 开启硬件直通
    2. 关闭硬件直通
├──────────────────────────────────────────┤
    0. 返回
└──────────────────────────────────────────┘
EOF
		echo -ne " 请选择: [ ]\b\b"
		read -t 60 hwmenuid
		hwmenuid=${hwmenuid:-0}
		case "${hwmenuid}" in
		1)
			enable_pass
			pause
			hw_passth
			break
		;;
		2)
			disable_pass
			pause
			hw_passth
			break
		;;
		0)
			menu
			break
		;;
		*)
		;;
		esac
	done
}
#--------------开启硬件直通----------------


#--------------设置CPU电源模式----------------

# 设置CPU电源模式
cpupower(){
	governors=`cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors`
	while :; do
		clear
		cat <<-EOF
`TIME y "	      设置CPU电源模式"`
┌──────────────────────────────────────────┐

    1. 设置CPU模式 conservative(保守)
    2. 设置CPU模式 ondemand(按需)
    3. 设置CPU模式 powersave(节能)
    4. 设置CPU模式 performance(性能)
    5. 设置CPU模式 schedutil(负载)

    6. 恢复系统默认电源设置

├──────────────────────────────────────────┤
    0. 返回
└──────────────────────────────────────────┘
EOF
		echo
		echo "部分CPU默认是pstate驱动，仅有 performance 和 powersave 模式；更智能，响应更快！"
		echo
		echo "你的CPU支持 ${governors} 等模式"
		echo
		echo
		echo
		echo -ne " 请选择: [ ]\b\b"
		read -t 60 cpupowerid
		cpupowerid=${cpupowerid:-2}
		case "${cpupowerid}" in
		1)
			GOVERNOR="conservative"
		;;
		2)
			GOVERNOR="ondemand"
		;;	
		3)
			GOVERNOR="powersave"
		;;
		4)
			GOVERNOR="performance"
		;;
		5)
			GOVERNOR="schedutil"
		;;
		6)
			cpupower_del
			break
		;;
		0)
			menu
			break
		;;
		*)
			echo "你的输入无效 ,请重新输入 !!!"
			pause
			cpupower
		;;
		esac
		if [[ ${GOVERNOR} != "" ]]; then
			if [[ -n `echo "${governors}" | grep -o "${GOVERNOR}"` ]]; then
				echo "您选择的CPU模式：${GOVERNOR}"
				echo
				cpupower_add
			else
				echo "您的CPU不支持该模式！"
				cpupower
			fi
		fi
	done
}

# 修改CPU模式
cpupower_add(){
	echo "${GOVERNOR}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	echo "查看当前CPU模式"
	cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor

	echo "添加开机任务"
	NEW_CRONTAB_COMMAND="sleep 10 && echo "${GOVERNOR}" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null #CPU Power Mode"
	EXISTING_CRONTAB=$(crontab -l 2>/dev/null)
     if [[ -n "$EXISTING_CRONTAB" ]]; then
       TEMP_CRONTAB_FILE=$(mktemp)
       echo "$EXISTING_CRONTAB" | grep -v "@reboot sleep 10 && echo*" > "$TEMP_CRONTAB_FILE"
       crontab "$TEMP_CRONTAB_FILE"
       rm "$TEMP_CRONTAB_FILE"
     fi
	# 修改完成
    (crontab -l 2>/dev/null; echo "@reboot $NEW_CRONTAB_COMMAND") | crontab -
    echo -e "\n检查计划任务设置 (使用 'crontab -l' 命令来检查)"

    pause
}

# 恢复系统默认电源设置
cpupower_del(){
	# 恢复性模式
	echo "performance" | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null
	# 删除计划任务
    EXISTING_CRONTAB=$(crontab -l 2>/dev/null)
    if [[ -n "$EXISTING_CRONTAB" ]]; then
      TEMP_CRONTAB_FILE=$(mktemp)
      echo "$EXISTING_CRONTAB" | grep -v "@reboot sleep 10 && echo*" > "$TEMP_CRONTAB_FILE"
      crontab "$TEMP_CRONTAB_FILE"
      rm "$TEMP_CRONTAB_FILE"
    fi

    echo "已恢复系统默认电源设置！"
}
#--------------设置CPU电源模式----------------


#--------------CPU、主板、硬盘温度显示----------------

# 安装工具
cpu_add(){

nodes="/usr/share/perl5/PVE/API2/Nodes.pm"
pvemanagerlib="/usr/share/pve-manager/js/pvemanagerlib.js"
proxmoxlib="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

pvever=$(pveversion | awk -F"/" '{print $2}')
echo pve版本$pvever

# 判断是否已经执行过修改
[ ! -e $nodes.$pvever.bak ] || { echo 已经执行过修改，请勿重复执行; exit 1;}

# 先刷新下源
apt-get update
sleep 5
echo "开始修改~"

# 输入需要安装的软件包
packages=(lm-sensors nvme-cli sysstat linux-cpupower)

# 查询软件包，判断是否安装
for package in "${packages[@]}"; do
    if ! dpkg -s "$package" &> /dev/null; then
        echo "$package 未安装，开始安装软件包"
        apt-get install "${packages[@]}" -y
        modprobe msr
        install=ok
        break
    fi
done


[[ -e /usr/sbin/linux-cpupower ]] && chmod +s /usr/sbin/linux-cpupower
chmod +s /usr/sbin/nvme
[[ -e /usr/sbin/hddtemp ]] && chmod +s /usr/sbin/hddtemp
chmod +s /usr/sbin/smartctl
chmod +s /usr/sbin/turbostat || echo "Failed to set permissions for /usr/sbin/turbostat"
modprobe msr && echo msr > /etc/modules-load.d/turbostat-msr.conf


# 软件包安装完成
if [ "$install" == "ok" ]; then
    echo 软件包安装完成，检测硬件信息
sensors-detect --auto > /tmp/sensors
drivers=`sed -n '/Chip drivers/,/\#----cut here/p' /tmp/sensors|sed '/Chip /d'|sed '/cut/d'`
if [ `echo $drivers|wc -w` = 0 ];then
    echo 没有找到任何驱动，似乎你的系统不支持或驱动安装失败。
    pause
    menu
else
    for i in $drivers
    do
        modprobe $i
        if [ `grep $i /etc/modules|wc -l` = 0 ];then
            echo $i >> /etc/modules
        fi
    done
    sensors
    sleep 3
    echo 驱动信息配置成功。
fi
[[ -e /etc/init.d/kmod ]] && /etc/init.d/kmod start
rm /tmp/sensors
# 驱动信息配置完成
fi

echo 备份源文件
# 删除旧版本备份文件
rm -f  $nodes.*.bak
rm -f  $pvemanagerlib.*.bak
rm -f  $proxmoxlib.*.bak
# 备份当前版本文件
[ ! -e $nodes.$pvever.bak ] && cp $nodes $nodes.$pvever.bak
[ ! -e $pvemanagerlib.$pvever.bak ] && cp $pvemanagerlib $pvemanagerlib.$pvever.bak
[ ! -e $proxmoxlib.$pvever.bak ] && cp $proxmoxlib $proxmoxlib.$pvever.bak

# 生成系统变量
tmpf=tmpfile.temp
touch $tmpf
cat > $tmpf << 'EOF' 
        $res->{thermalstate} = `sensors`;
        $res->{cpusensors} = `cat /proc/cpuinfo | grep MHz; lscpu | grep MHz; echo "Governor: \$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)"; echo "Package Power: \$(turbostat -S -q -s PkgWatt -i 0.1 -n 1 -c package 2>/dev/null | grep -v PkgWatt | tail -1)"`;

        $res->{hdd_temperatures} = `for disk in /dev/sd[a-z]; do smartctl -a \$disk; done | grep -E "Device Model|Capacity|Power_On_Hours|Temperature"`;
		
        my $powermode = `cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor && turbostat -S -q -s PkgWatt -i 0.1 -n 1 -c package | grep -v PkgWatt`;
        $res->{cpupower} = $powermode;

EOF

# NVME磁盘变量
for i in {0..9}; do
    for dev in "/dev/nvme${i}" "/dev/nvme${i}n1"; do
        if [ -b "$dev" ]; then
            echo "检测到NVME磁盘: $dev" >&2
            cat >> $tmpf << EOF

        my \$nvme${i}_temperatures = \`smartctl -a $dev | grep -E "Model Number|(?=Total|Namespace)[^:]+Capacity|Temperature:|Available Spare:|Percentage|Data Unit|Power Cycles|Power On Hours|Unsafe Shutdowns|Integrity Errors"\`;
        my \$nvme${i}_io = \`iostat -d -x -k 1 1 | grep -E "^${dev##*/}"\`;
        \$res->{nvme${i}_status} = \$nvme${i}_temperatures . \$nvme${i}_io;

EOF
            break
        fi
    done
done

###################  修改node.pm   ##########################
echo 修改node.pm：
echo 找到关键字 PVE::pvecfg::version_text 的行号并跳到下一行
# 显示匹配的行
ln=$(expr $(sed -n -e '/PVE::pvecfg::version_text/=' $nodes) + 1)
echo "匹配的行号：" $ln

echo 修改结果：
sed -i "${ln}r $tmpf" $nodes
# 显示修改结果
sed -n '/PVE::pvecfg::version_text/,+18p' $nodes
rm $tmpf



###################  修改pvemanagerlib.js   ##########################
tmpf=tmpfile.temp
touch $tmpf
cat > $tmpf << 'EOF'

		
		{
			itemId: 'thermal',
			colspan: 2,
			printBar: false,
			title: gettext('温度(°C)'),
			textField: 'thermalstate',
			renderer: function(value) {
				let lines = value.trim().split(/\s+(?=^\w+-)/m).sort();
				let result = [];
				let cpuTemps = [];
				let boardTemp = null;
				let nvmeTemp = null;
				let cpuCrit = null;
				let nvmeCrit = null;
				for (let line of lines) {
					let name = line.match(/^[^-]+/)[0].toUpperCase();
					let temps = line.match(/(?<=:\s+)[+-][\d.]+(?=.?°C)/g);
					if (!temps) continue;
					temps = temps.map(t => Math.round(Number(t)));
					let critMatch = line.match(/(?<=\bcrit\b[^+]+\+)\d+/);
					if (/coretemp/i.test(name)) {
						cpuTemps = temps;
						if (critMatch) cpuCrit = critMatch[0];
					} else if (name === 'ACPITZ') {
						boardTemp = temps[0];
					} else if (name.includes('NVME')) {
						nvmeTemp = temps[0];
						if (critMatch) nvmeCrit = critMatch[0];
					}
				}
				let parts = [];
				if (cpuTemps.length) {
					let main = cpuTemps[0] + '°C';
					let others = cpuTemps.slice(1);
					let othersStr = others.length ? ' ( ' + others.join(' | ') + ' )' : '';
					let cpuStr = `CPU: ${main}${othersStr}`;
					if (cpuCrit) cpuStr += ` ,超限: ${cpuCrit}°C`;
					parts.push(cpuStr);
				}
				if (boardTemp !== null) parts.push(`主板: ${boardTemp}°C`);
				if (nvmeTemp !== null) {
					let nvmeStr = `NVME: ${nvmeTemp}°C`;
					if (nvmeCrit) nvmeStr += ` ,超限: ${nvmeCrit}°C`;
					parts.push(nvmeStr);
				}
				return parts.join(' | ');
			}
		},

		{
			itemId: 'MHz',
			colspan: 2,
			printBar: false,
			title: gettext('CPU频率(GHz)'),
			textField: 'cpusensors',
			renderer: function(value) {
				// 提取核心频率（取第一个 CPU MHz 作为当前平均？原pve.sh中cpusensors包含每个核心的MHz，我们计算平均值）
				let freqMatches = value.match(/cpu MHz\s*:\s*([\d.]+)/g);
				let freqs = [];
				if (freqMatches) {
					for (let m of freqMatches) {
						let f = parseFloat(m.match(/[\d.]+/)[0]);
						freqs.push(f);
					}
				}
				let avgFreq = freqs.length ? Math.round(freqs.reduce((a,b)=>a+b,0)/freqs.length) : '?';
				
				// 提取最大最小频率
				let minMatch = value.match(/CPU min MHz\s*:\s*([\d.]+)/);
				let min = minMatch ? (parseFloat(minMatch[1])/1000).toFixed(1) : '?';
				let maxMatch = value.match(/CPU max MHz\s*:\s*([\d.]+)/);
				let max = maxMatch ? (parseFloat(maxMatch[1])/1000).toFixed(1) : '?';
				
				// 提取电源模式
				let govMatch = value.match(/Governor:\s*(\S+)/);
				let gov = govMatch ? govMatch[1].toLowerCase() : 'unknown';
				
				// 提取功耗
				let powerMatch = value.match(/Package Power:\s*([\d.]+)/);
				let power = powerMatch ? parseFloat(powerMatch[1]).toFixed(1) : null;
				let powerStr = power !== null ? ` | 功耗: ${power}W` : '';
				
				return `CPU实时: ${avgFreq} MHz | Max: ${max} GHz | Min: ${min} GHz${powerStr} | 电源模式: ${gov}`;
			}
		},
		
		/* 检测不到相关参数的可以注释掉---需要的注释本行即可
		// 风扇转速
		{
	          itemId: 'RPM',
	          colspan: 2,
	          printBar: false,
	          title: gettext('CPU风扇'),
	          textField: 'thermalstate',
	          renderer:function(value){
				  const fan1 = value.match(/fan1:.*?\ ([\d.]+) R/)[1];
				  const fan2 = value.match(/fan2:.*?\ ([\d.]+) R/)[1];
				  if (fan1 === "0") {
				    fan11 = "停转";
				  } else {
				    fan11 = fan1 + " RPM";
				  }
				  if (fan2 === "0") {
				    fan22 = "停转";
				  } else {
				    fan22 = fan2 + " RPM";
				  }
				  return `CPU风扇: ${fan11} | 系统风扇: ${fan22}`
	            }
		},
		检测不到相关参数的可以注释掉---需要的注释本行即可  */

EOF

# NVME硬盘温度

# NVME硬盘温度
for i in {0..9}; do
    for dev in "/dev/nvme${i}" "/dev/nvme${i}n1"; do
        if [ -b "$dev" ]; then
            echo "添加NVME磁盘: $dev" >&2
            cat >> $tmpf << EOF
		{
			itemId: 'nvme${i}-status',
			colspan: 2,
			printBar: false,
			title: gettext('NVME盘'),
			textField: 'nvme${i}_status',
			renderer: function(value) {
				if (!value || value.length === 0) return '未检测到 NVMe 硬盘';
				try {
					let modelMatch = value.match(/Model Number:\s*(.*?)(?:\n|$)/);
					let model = modelMatch ? modelMatch[1].trim() : '未知型号';
					let tempMatch = value.match(/Temperature:\s*(\d+)/);
					let temp = tempMatch ? tempMatch[1] : '?';
					let usedMatch = value.match(/Percentage Used:\s*(\d+)/);
					let health = usedMatch ? (100 - parseInt(usedMatch[1])) + '%' : '?';
					let mediaErrorsMatch = value.match(/Media and Data Integrity Errors:\s*(\d+)/);
					let mediaErrors = mediaErrorsMatch ? mediaErrorsMatch[1] : '0';
					let hoursMatch = value.match(/Power On Hours:\s*([\d,]+)/);
					let hours = hoursMatch ? parseInt(hoursMatch[1].replace(/,/g, '')) : 0;
					let days = Math.round(hours / 24);
					let cyclesMatch = value.match(/Power Cycles:\s*(\d+)/);
					let cycles = cyclesMatch ? cyclesMatch[1] : '0';
					// 匹配方括号内的数字，如 [13.1 TB]
					let readTBMatch = value.match(/\[([\d.]+)\s*TB\]/);
					let writeTBMatch = value.match(/\[([\d.]+)\s*TB\]/g);
					let readTB = '0', writeTB = '0';
					if (readTBMatch) readTB = readTBMatch[1];
					// 注意：需要分别匹配读写，因为有两个方括号。上面的正则默认取第一个，我们需要第二个。
					// 更好的方法：分别匹配 Data Units Read 和 Data Units Written 后的方括号
					let readMatchAll = value.match(/Data Units Read:.*?\[([\d.]+)\s*TB\]/);
					let writeMatchAll = value.match(/Data Units Written:.*?\[([\d.]+)\s*TB\]/);
					if (readMatchAll) readTB = readMatchAll[1];
					if (writeMatchAll) writeTB = writeMatchAll[1];
					let parts = [
						model,
						temp + '°C',
						'健康: ' + health + ',0E: ' + mediaErrors,
						'通电: ' + days + '天,次: ' + cycles,
						'R/W: ' + readTB + 'T/' + writeTB + 'T',
						'SMART: 正常'
					];
					return parts.join(' | ');
				} catch(e) {
					return '无法解析 NVMe 信息';
				}
			}
		},
EOF
            break
        fi
    done
done

# SATA硬盘温度

echo 找到关键字pveversion的行号
# 显示匹配的行
ln=$(sed -n '/pveversion/,+10{/},/{=;q}}' $pvemanagerlib)
echo "匹配的行号pveversion：" $ln

echo 修改结果：
sed -i "${ln}r $tmpf" $pvemanagerlib
# 显示修改结果
# sed -n '/pveversion/,+30p' $pvemanagerlib
rm $tmpf


echo 修改页面高度
disk_count=$(lsblk -d -o NAME | grep -cE 'sd[a-z]|nvme[0-9]')
# 高度变量，某些CPU核心过多，或者想显示那个PVE存储库那一行，导致高度不够，修改69为合适的数字，如80、100等。
height_increase=$((disk_count * 0))

node_status_new_height=$((400 + height_increase))
sed -i -r '/widget\.pveNodeStatus/,+5{/height/{s#[0-9]+#'$node_status_new_height'#}}' $pvemanagerlib
cpu_status_new_height=$((300 + height_increase))
sed -i -r '/widget\.pveCpuStatus/,+5{/height/{s#[0-9]+#'$cpu_status_new_height'#}}' $pvemanagerlib

echo "修改后的高度值："
sed -n -e '/widget\.pveNodeStatus/,+5{/height/{p}}' \
       -e '/widget\.pveCpuStatus/,+5{/height/{p}}' $pvemanagerlib

# 调整显示布局
ln=$(expr $(sed -n -e '/widget.pveDcGuests/=' $pvemanagerlib) + 10)
sed -i "${ln}a\ textAlign: 'right'," $pvemanagerlib
ln=$(expr $(sed -n -e '/widget.pveNodeStatus/=' $pvemanagerlib) + 10)
sed -i "${ln}a\ textAlign: 'right'," $pvemanagerlib

###################  修改proxmoxlib.js   ##########################


echo 加强去除订阅弹窗
# sed -r -i '/\/nodes\/localhost\/subscription/,+10{/^\s+if \(res === null /{N;s#.+#\t\t  if(false){#}}' $proxmoxlib
sed -r -i '/\/nodes\/localhost\/subscription/,+30 {
    /^\s+if\s*\(/ {
        :loop
        N
        /\s*\)\s*\{/!b loop
        s/(if\s*\([[:space:]]*res\s*===\s*null\s*(\|\|\s*res\s*===\s*undefined\s*)?(\|\|\s*!res\s*)?(\|\|\s*res\.data\.status\.toLowerCase\(\)\s*!==\s*['\''"]active['\''"]\s*)?[[:space:]]*\)\s*\{)/if(false){/
    }
}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

# 显示修改结果
sed -n '/\/nodes\/localhost\/subscription/,+10p' $proxmoxlib
systemctl restart pveproxy

echo "请刷新浏览器缓存shift+f5"


}

# 删除工具
cpu_del(){

nodes="/usr/share/perl5/PVE/API2/Nodes.pm"
pvemanagerlib="/usr/share/pve-manager/js/pvemanagerlib.js"
proxmoxlib="/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js"

pvever=$(pveversion | awk -F"/" '{print $2}')
echo pve版本$pvever
if [ -f "$nodes.$pvever.bak" ];then
rm -f $nodes $pvemanagerlib $proxmoxlib
mv $nodes.$pvever.bak $nodes
mv $pvemanagerlib.$pvever.bak $pvemanagerlib
mv $proxmoxlib.$pvever.bak $proxmoxlib

echo "已删除温度显示，请重新刷新浏览器缓存."
else
echo "你没有添加过温度显示，退出脚本."
fi


}

#--------------CPU、主板、硬盘温度显示----------------


#--------------一键卸载旧内核----------------
remove_kernel(){

YW="\033[33m"
GN="\033[1;92m"
RD="\033[01;31m"
CL="\033[m"

echo -e "${RD}此操作非常危险，风险自行承担！！！${CL}"
echo -e "${RD}操作不当会引起系统崩溃，请知悉！${CL}"

current_kernel=$(uname -r)
available_kernels=$(dpkg --list | grep 'kernel-.*-pve' | awk '{print $2}' | grep -v "$current_kernel" | sort -V)

if [ -z "$available_kernels" ]; then
  echo -e "${GN}未检测到旧内核，当前内核: ${current_kernel}${CL}"
  exit 0
fi

echo -e "${YW}可供移除的内核:${CL}"
echo "$available_kernels" | nl -w 2 -s '. '

echo -e "\n${YW}选择要删除的内核（以逗号分隔，例如 1,2）:${CL}"
read -r selected

# Parse selection
IFS=',' read -r -a selected_indices <<<"$selected"
kernels_to_remove=()

for index in "${selected_indices[@]}"; do
  kernel=$(echo "$available_kernels" | sed -n "${index}p")
  if [ -n "$kernel" ]; then
    kernels_to_remove+=("$kernel")
  fi
done

if [ ${#kernels_to_remove[@]} -eq 0 ]; then
  echo -e "${RD}未做出有效选择，退出。${CL}"
  exit 1
fi

# Confirm removal
echo -e "${YW}待移除的内核:${CL}"
printf "%s\n" "${kernels_to_remove[@]}"
read -rp "继续删除吗？(y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo -e "${RD}已中止${CL}"
  exit 1
fi

# Remove kernels
for kernel in "${kernels_to_remove[@]}"; do
  echo -e "${YW}移除 $kernel...${CL}"
  if apt-get purge -y "$kernel" >/dev/null 2>&1; then
    echo -e "${GN}已成功移除: $kernel${CL}"
  else
    echo -e "${RD}删除失败: $kernel ，检查依赖关系。${CL}"
  fi
done

# Clean up and update GRUB
echo -e "${YW}清理中...${CL}"
apt-get autoremove -y >/dev/null 2>&1 && update-grub >/dev/null 2>&1
echo -e "${GN}清理和 GRUB 更新完成。${CL}"


}

#--------------一键卸载旧内核----------------


# 主菜单
menu(){
	cat <<-EOF

`TIME y "    PVE优化脚本 - 2025 刀刀优化版    "`
┌──────────────────────────────────────────┐
    1. 一键优化PVE(换源、去订阅等)
    2. 配置PCI硬件直通
    3. 设置CPU电源模式
    4. 添加CPU、主板、硬盘温度显示
    5. 删除CPU、主板、硬盘温度显示
    6. PVE8/9添加ceph-squid源
    7. PVE7/8添加ceph-quincy源
    8. 一键卸载ceph
    9. 一键卸载旧内核(危险，谨慎操作！)
├──────────────────────────────────────────┤
    0. 退出
└──────────────────────────────────────────┘

EOF
	echo -ne " 请选择: [ ]\b\b"
	read -t 60 menuid
	menuid=${menuid:-0}
	case ${menuid} in
	1)
		pve_optimization
		echo
		pause
		menu
	;;
	2)
		hw_passth
		echo
		pause
		menu
	;;
	3)
		cpupower
		echo
		pause
		menu
	;;
	4)
		cpu_add
		echo
		pause
		menu
	;;
	5)
		cpu_del
		echo
		pause
		menu
	;;
	6)
		pve9_ceph
		echo
		pause
		menu
	;;
	7)
		pve8_ceph
		echo
		pause
		menu
	;;
	8)
		remove_ceph
		echo
		pause
		menu
	;;
	9)
		remove_kernel
		echo
		pause
		menu
	;;
	0)
		clear
		exit 0
	;;
	*)
		echo "你的输入无效 ,请重新输入 !!!"
		pause
		menu
	;;
	esac
}
menu
