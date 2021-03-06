#!/bin/bash

# initialisasi var
OS=`uname -p`;

# go to root
cd

# disable se linux
echo 0 > /selinux/enforce
sed -i 's/SELINUX=enforcing/SELINUX=disable/g'  /etc/sysconfig/selinux

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service sshd restart

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.d/rc.local

# install wget and curl
yum -y install wget curl

# setting repo
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/epel-release-6-8.noarch.rpm
wget http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
rpm -Uvh epel-release-6-8.noarch.rpm
rpm -Uvh remi-release-6.rpm

if [ "$OS" == "x86_64" ]; then
  wget http://ftp.tu-chemnitz.de/pub/linux/dag/redhat/el6/en/x86_64/rpmforge/RPMS/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
  rpm -Uvh rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm
else
  wget http://downloads.naulinux.ru/pub/SLCE/6x/i386/CyrEd/RPMS//rpmforge-release-0.5.2-2.1.el6.i686.rpm
  rpm -Uvh rpmforge-release-0.5.2-2.1.el6.i686.rpm
fi

sed -i 's/enabled = 1/enabled = 0/g' /etc/yum.repos.d/rpmforge.repo
sed -i -e "/^\[remi\]/,/^\[.*\]/ s|^\(enabled[ \t]*=[ \t]*0\\)|enabled=1|" /etc/yum.repos.d/remi.repo
rm -f *.rpm

# remove unused
yum -y remove sendmail;
yum -y remove httpd;
yum -y remove cyrus-sasl

# update
yum -y update

# install webserver
yum -y install nginx php-fpm php-cli
service nginx restart
service php-fpm restart
chkconfig nginx on
chkconfig php-fpm on

# install essential package
yum -y install rrdtool screen iftop htop nmap bc nethogs openvpn vnstat ngrep mtr git zsh mrtg unrar rsyslog rkhunter mrtg net-snmp net-snmp-utils expect nano bind-utils
yum -y groupinstall 'Development Tools'
yum -y install cmake

yum -y --enablerepo=rpmforge install axel sslh ptunnel unrar

# matiin exim
service exim stop
chkconfig exim off

# setting vnstat
vnstat -u -i eth0
echo "MAILTO=root" > /etc/cron.d/vnstat
echo "*/5 * * * * root /usr/sbin/vnstat.cron" >> /etc/cron.d/vnstat
service vnstat restart
chkconfig vnstat on

# install screenfetch
cd
wget https://github.com/KittyKatt/screenFetch/raw/master/screenfetch-dev
mv screenfetch-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .bash_profile
echo "screenfetch" >> .bash_profile

# install webserver
cd
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/nginx.conf"
sed -i 's/www-data/nginx/g' /etc/nginx/nginx.conf
mkdir -p /home/vps/public_html
echo "<pre>Setup by Ibnu Fachrizal<pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
rm /etc/nginx/conf.d/*
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/vps.conf"
sed -i 's/apache/nginx/g' /etc/php-fpm.d/www.conf
chmod -R +rx /home/vps
service php-fpm restart
service nginx restart

# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/openvpn-debian.tar"
cd /etc/openvpn/
tar xf openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/1194-centos.conf"
if [ "$OS" == "x86_64" ]; then
  wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/1194-centos64.conf"
fi
wget -O /etc/iptables.up.rules "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/iptables.up.rules"
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.local
sed -i '$ i\iptables-restore < /etc/iptables.up.rules' /etc/rc.d/rc.local
MYIP=`curl -s ifconfig.me`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
sed -i $MYIP2 /etc/iptables.up.rules;
sed -i 's/venet0/eth0/g' /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
sysctl -w net.ipv4.ip_forward=1
sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
service openvpn restart
chkconfig openvpn on
cd

# configure openvpn client config
cd /etc/openvpn/
wget -O /etc/openvpn/1194-client.ovpn "http://sshaiopremium.ga/script/centos6/1194-client.conf"
sed -i $MYIP2 /etc/openvpn/1194-client.ovpn;
PASS=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1`;
useradd -M -s /bin/false admin_ibnu
echo "admin_ibnu:$PASS" | chpasswd
tar cf client.tar 1194-client.ovpn
cp client.tar /home/vps/public_html/
cd

# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.d/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# install mrtg
cd /etc/snmp/
wget -O /etc/snmp/snmpd.conf "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/snmpd.conf"
wget -O /root/mrtg-mem.sh "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
service snmpd restart
chkconfig snmpd on
snmpwalk -v 1 -c public localhost | tail
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg/mrtg.cfg public@localhost
curl "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/mrtg.conf" >> /etc/mrtg/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg/mrtg.cfg
echo "0-59/5 * * * * root env LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg" > /etc/cron.d/mrtg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
LANG=C /usr/bin/mrtg /etc/mrtg/mrtg.cfg
cd

# setting port ssh
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port  22/g' /etc/ssh/sshd_config
service sshd restart
chkconfig sshd on

# install dropbear
yum -y install dropbear
echo "OPTIONS=\"-b /issue.net.txt -p 80 -p 109 -p 110 -p 443\"" > /etc/sysconfig/dropbear
echo "/bin/false" >> /etc/shells
service dropbear restart
chkconfig dropbear on

# install vnstat gui
cd /home/vps/public_html/
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i "s/\$iface_list = array('eth0', 'sixxs');/\$iface_list = array('eth0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd

# install fail2ban
yum -y install fail2ban
service fail2ban restart
chkconfig fail2ban on

# install squid
yum -y install squid
wget -O /etc/squid/squid.conf "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/squid-centos.conf"
sed -i $MYIP2 /etc/squid/squid.conf;
service squid restart
chkconfig squid on

# install webmin
cd
wget http://prdownloads.sourceforge.net/webadmin/webmin-1.670-1.noarch.rpm
rpm -i webmin-1.670-1.noarch.rpm;
rm webmin-1.670-1.noarch.rpm
service webmin restart
chkconfig webmin on

# pasang bmon
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/bmon "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/bmon64"
else
  wget -O /usr/bin/bmon "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/bmon"
fi
chmod +x /usr/bin/bmon

# User Status
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/user-list
mv ./user-list /usr/local/bin/user-list
chmod +x /usr/local/bin/user-list

# Install Dos Deflate
apt-get -y install dnsutils dsniff
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/ddos-deflate-master.zip
unzip ddos-deflate-master.zip
cd ddos-deflate-master
./install.sh
cd

# instal UPDATE SCRIPT
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/update
mv ./update /usr/bin/update
chmod +x /usr/bin/update

# instal Buat Akun SSH/OpenVPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/buatakun
mv ./buatakun /usr/bin/buatakun
chmod +x /usr/bin/buatakun

# instal Generate Akun SSH/OpenVPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/generate
mv ./generate /usr/bin/generate
chmod +x /usr/bin/generate

# instal Generate Akun Trial
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/trial
mv ./trial /usr/bin/trial
chmod +x /usr/bin/trial

# instal  Ganti Password Akun SSH/VPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userpass
mv ./userpass /usr/bin/userpass
chmod +x /usr/bin/userpass

# instal Generate Akun SSH/OpenVPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userrenew
mv ./userrenew /usr/bin/userrenew
chmod +x /usr/bin/userrenew

# instal Hapus Akun SSH/OpenVPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userdelete
mv ./userdelete /usr/bin/userdelete
chmod +x /usr/bin/userdelete

# instal Cek Login Dropbear & OpenSSH
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userlogin
mv ./userlogin /usr/bin/userlogin
chmod +x /usr/bin/userlogin

# instal Cek Login Dropbear, OpenSSH & OpenVPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userlogin
mv ./userlogin /usr/bin/userlogin
chmod +x /usr/bin/userlogin

# instal Auto Limit Multi Login
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/autolimit
mv ./autolimit /usr/bin/autolimit
chmod +x /usr/bin/autolimit

# instal Auto Limit Script Multi Login
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/auto-limit-script
mv ./auto-limit-script /usr/bin/auto-limit-script
chmod +x /usr/bin/auto-limit-script

# instal Melihat detail user SSH & OpenVPN 
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userdetail
mv ./userdetail /usr/bin/userdetail
chmod +x /usr/bin/userdetail

# instal Delete Akun Expire
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/deleteuserexpire
mv ./deleteuserexpire /usr/bin/deleteuserexpire
chmod +x /usr/bin/deleteuserexpire

# instal  Kill Multi Login
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/autokilluser
mv ./autokilluser /usr/bin/autokilluser
chmod +x /usr/bin/autokilluser

# instal Auto Banned Akun
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userban
mv ./userban /usr/bin/userban
chmod +x /usr/bin/userban

# instal Unbanned Akun
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userunban
mv ./userunban /usr/bin/userunban
chmod +x /usr/bin/userunban

# instal Mengunci Akun SSH & OpenVPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userlock
mv ./userlock /usr/bin/userlock
chmod +x /usr/bin/userlock

# instal Membuka user SSH & OpenVPN yang terkunci
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userunlock
mv ./userunlock /usr/bin/userunlock
chmod +x /usr/bin/userunlock

# instal Melihat daftar user yang terkick oleh perintah user-limit
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/loglimit
mv ./loglimit /usr/bin/loglimit
chmod +x /usr/bin/loglimit

# instal Melihat daftar user yang terbanned oleh perintah user-ban
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/logban
mv ./logban /usr/bin/logban
chmod +x /usr/bin/logban

# instal Buat Akun PPTP VPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/useraddpptp
mv ./useraddpptp /usr/bin/useraddpptp
chmod +x /usr/bin/useraddpptp

# instal Hapus Akun PPTP VPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userdeletepptp
mv ./userdeletepptp /usr/bin/userdeletepptp
chmod +x /usr/bin/userdeletepptp

# instal Lihat Detail Akun PPTP VPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/detailpptp
mv ./detailpptp /usr/bin/detailpptp
chmod +x /usr/bin/detailpptp

# instal Cek login PPTP VPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userloginpptp
mv ./userloginpptp /usr/bin/userloginpptp
chmod +x /usr/bin/userloginpptp

# instal Lihat Daftar User PPTP VPN
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/alluserpptp
mv ./alluserpptp /usr/bin/alluserpptp
chmod +x /usr/bin/alluserpptp

# instal Set Auto Reboot
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/autoreboot
mv ./autoreboot /usr/bin/autoreboot
chmod +x /usr/bin/autoreboot

# Install SPEED tES
apt-get install python
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/speedtest.py
chmod +x speedtest.py

# instal autolimitscript
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/auto-limit-script
mv ./auto-limit-script /usr/bin/auto-limit-script
chmod +x /usr/bin/auto-limit-script

# instal userdelete
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/userdelete
mv ./userdelete /usr/bin/userdelete
chmod +x /usr/bin/userdelete

# Install Menu
cd
wget https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/menu
mv ./menu /usr/local/bin/menu
chmod +x /usr/local/bin/menu

# download script
cd
wget -O /issue.net.txt "https://raw.githubusercontent.com/galihkontlo/sshinjector2/master/config/banner"
echo "0 0 * * * root /root/user-expired.sh" > /etc/cron.d/user-expired
echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "* * * * * service dropbear restart" > /etc/cron.d/dropbear
chmod +x user-expired.sh

# Restart Service
chown -R www-data:www-data /home/vps/public_html
service cron restart
service nginx start
service php-fpm start
service vnstat restart
service openvpn restart
service snmpd restart
service dropbear restart
service fail2ban restart
service webmin restart

# info
clear
echo "Setup by Ibnu Fachrizal"  | tee -a log-install.txt
echo "OpenVPN  : TCP 1194 (client config : http://$MYIP:81/client.tar)"  | tee -a log-install.txt
echo "OpenSSH  : 22, 143"  | tee -a log-install.txt
echo "Dropbear : 80, 109, 110, 443"  | tee -a log-install.txt
echo "Squid3   : 8080, 8000, 3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "axel"    | tee -a log-install.txt
echo "bmon"    | tee -a log-install.txt
echo "htop"    | tee -a log-install.txt
echo "iftop"    | tee -a log-install.txt
echo "mtr"    | tee -a log-install.txt
echo "rkhunter"    | tee -a log-install.txt
echo "nethogs: nethogs venet0"    | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "Webmin   : http://$MYIP:10000/"  | tee -a log-install.txt
echo "vnstat   : http://$MYIP:81/vnstat/"  | tee -a log-install.txt
echo "MRTG     : http://$MYIP:81/mrtg/"  | tee -a log-install.txt
echo "Timezone : Asia/Jakarta"  | tee -a log-install.txt
echo "Fail2Ban : [on]"  | tee -a log-install.txt
echo "IPv6     : [off]"  | tee -a log-install.txt
echo "Status   : please type ./status to check user status"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "VPS REBOOT TIAP JAM 24.00 !"  | tee -a log-install.txt
echo""  | tee -a log-install.txt
echo "Please Reboot your VPS !"  | tee -a log-install.txt
echo "================================================"  | tee -a log-install.txt
echo "Script Created By Ibnu Fachrizal"  | tee -a log-install.txt
echo "Terimakasih telah berlangganan di www.sshinjector.net"  | tee -a log-install.txt
