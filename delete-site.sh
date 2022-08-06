#!/bin/bash
read -p "Enter the name of the site to disable (example: mydomain.com): " site
echo "You enter sitename: $site"
echo "Disabling site $site..."
a2dissite $site
rm /etc/apache2/sites-available/$site.conf
service apache2 reload
read -p "Do you want to delete the site's document root? (y/n): " delete
if [ $delete == "y" ]; then
if [ -d "/var/www/$site" ]; then
echo "Removing /var/www/$site..."
rm -rf /var/www/$site
fi
fi
read -p "Do you want to delete SSL Certificate and Key? (y/n): " delete
if [ $delete == "y" ]; then
if [ -d "/home/selfsigned/$site" ]; then
echo "Removing /home/selfsigned/$site..."
rm -rf /home/selfsigned/$site
fi
fi

echo "Done!"
