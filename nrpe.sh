<pre>
#!/bin/bash

echo "yum install nrpe and utils"
yum -y update
yum -y install epel-release
yum -y install nrpe nagios-plugins-load nagios-plugins-uptime smartmontools
mv /etc/nagios/nrpe.cfg /etc/nagios/nrpe.cfg_old

echo "RAID Megacli installation and configuration"
rpm -Uvh http://mirror.cogentco.com/pub/misc/MegaCli-8.07.14-1.noarch.rpm

echo "Nagios RAID checks installation and configuration"
wget https://github.com/glensc/nagios-plugin-check_raid/releases/download/4.0.10/check_raid.pl -P /usr/lib64/nagios/plugins/
chmod +x /usr/lib64/nagios/plugins/check_raid.pl
cat >> /etc/sudoers.d/check_raid << DELIM
# Lines matching CHECK_RAID added by ./check_raid.pl -S
User_Alias CHECK_RAID=nrpe
Defaults:CHECK_RAID !requiretty
CHECK_RAID ALL=(root) NOPASSWD: /opt/MegaRAID/MegaCli/MegaCli64 -PDList -aALL -NoLog
CHECK_RAID ALL=(root) NOPASSWD: /opt/MegaRAID/MegaCli/MegaCli64 -LdInfo -Lall -aALL -NoLog
CHECK_RAID ALL=(root) NOPASSWD: /opt/MegaRAID/MegaCli/MegaCli64 -AdpBbuCmd -GetBbuStatus -aALL -NoLog
DELIM

echo "S.M.A.R.T checks configuration"
wget https://raw.githubusercontent.com/Napsty/check_smart/master/check_smart.pl -P /usr/lib64/nagios/plugins/
chmod +x /usr/lib64/nagios/plugins/check_smart.pl

cat >>  /etc/sudoers.d/check_smart << DELIM
nrpe   ALL = NOPASSWD: /usr/lib64/nagios/plugins/check_smart.pl
nrpe   ALL = NOPASSWD: /usr/sbin/smartctl
DELIM

echo "NRPE configuration"
cat >> /etc/nagios/nrpe.cfg << DELIM
log_facility=daemon
debug=0
pid_file=/run/nrpe/nrpe.pid
server_port=5666
nrpe_user=nrpe
nrpe_group=nrpe
allowed_hosts=127.0.0.1,::1
dont_blame_nrpe=0
allow_bash_command_substitution=0
command_timeout=60
connection_timeout=300
disable_syslog=0
command[check_load]=/usr/lib64/nagios/plugins/check_load -r -w 30,30,30 -c 35,35,35
command[check_smart0]=/usr/lib64/nagios/plugins/check_smart.pl -d /dev/sdb -i megaraid,0
command[check_smart1]=/usr/lib64/nagios/plugins/check_smart.pl -d /dev/sdb -i megaraid,1
command[check_smart2]=/usr/lib64/nagios/plugins/check_smart.pl -d /dev/sda -i megaraid,2
command[check_raid]=/usr/lib64/nagios/plugins/check_raid.pl -p megacli --cache-fail=OK
command[check_uptime]=/usr/lib64/nagios/plugins/check_uptime
include_dir=/etc/nrpe.d/
DELIM

echo "Service nrpe autostart"
systemctl enable nrpe
systemctl restart nrpe

echo "Open nrpe 5666 port in Firewalld"
firewall-cmd --zone=public --permanent --add-port=5666/tcp
firewall-cmd --reload
</pre>