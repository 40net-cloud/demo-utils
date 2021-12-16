Simple branded web page, which constantly pings itself and graphs RTT. Good for tracking delays during failover.

To install simply download the contents into the root directory of your web server:
```
apt update
apt install wget unzip nginx -y
cd /var/www/html
wget -N https://raw.githubusercontent.com/40net-cloud/demo-utils/main/www-ping/html.zip
unzip html.zip
```
