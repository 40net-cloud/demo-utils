Simple branded web page, which constantly pings itself and graphs RTT. Good for tracking delays during failover.

To install simply download the contents into the root directory of your web server:
```
apt update
apt install wget nginx -y
cd /var/www/html
wget -N https://raw.githubusercontent.com/40net-cloud/demo-utils/master/www-ping/1.html
wget -N https://raw.githubusercontent.com/40net-cloud/demo-utils/master/www-ping/mark-blue.png
wget -N https://raw.githubusercontent.com/40net-cloud/demo-utils/master/www-ping/mark-purple.png
wget -N https://raw.githubusercontent.com/40net-cloud/demo-utils/master/www-ping/top-right.png
wget -N https://raw.githubusercontent.com/40net-cloud/demo-utils/master/www-ping/xperts-logo.png
```
