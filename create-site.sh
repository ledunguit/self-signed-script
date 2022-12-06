#!/bin/bash
read -p "Enter the name of the site you want to create (example: mydomain.com): " site
echo "You enter sitename: $site"
read -p "Enter the document root of the site (example: /var/www/mydomain.com): " docroot
echo "You enter document root: $docroot"
read -p "Enable SSL (y/n)? " ssl
if [ $ssl=="y" ] ; then
read -p "Create rootCA certificate first (y/n)? " rootca
if [ $rootca == "y" ]; then
    echo "Please enter the name of the rootCA (example: rootCA): "
    read rootca_name
    if [ $rootca_name == "" ] ; then
        rootca_name = "rootCA"
    fi
    openssl genrsa -des3 -out $rootca_name.key 2048
else
    read -p "Please enter the name of the old rootCA you have (example: rootCA): " rootca_name
fi
echo "Generating private key for site $site..."
sleep 1
openssl genrsa -out $site.key 2048
echo "Generating CSR for site $site..."
sleep 1
openssl req -new -key $site.key -out $site.csr
echo "Generating subjectAltName for site $site..."
sleep 1
cat << EOF > $site.ext
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $site
EOF
echo "Generating certificate for site $site..."
sleep 1
openssl x509 -req -in $site.csr -CA $rootca_name.pem -CAkey $rootca_name.key -CAcreateserial \
-out $site.crt -days 1825 -sha256 -extfile $site.ext
mkdir $site
mv $site.key $site.crt $site.ext $site.csr $site/
echo "Generating vhost for site $site..."
sleep 1
cat << EOF > /etc/apache2/sites-available/$site.conf
<VirtualHost *:80>
        ServerName $site
        DocumentRoot $docroot
        Redirect / https://$site/
</VirtualHost>
<VirtualHost *:443>
        ServerName $site
        DocumentRoot $docroot
        SSLEngine on
        SSLCertificateFile /home/$USER/selfsigned/$site/$site.crt
        SSLCertificateKeyFile /home/$USER/selfsigned/$site/$site.key
        <Directory $docroot>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
        <FilesMatch ".php$">
            SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost/"
        </FilesMatch>
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
a2ensite $site
service apache2 reload
else
echo "Generating vhost for site $site..."
sleep 1
cat << EOF > /etc/apache2/sites-available/$site.conf
<VirtualHost *:80>
        ServerName $site
        DocumentRoot $docroot
        <Directory $docroot>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
        <FilesMatch ".php$">
            SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost/"
        </FilesMatch>
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
<VirtualHost *:443>
        ServerName $site
        DocumentRoot $docroot
        <Directory $docroot>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
        </Directory>
        <FilesMatch ".php$">
            SetHandler "proxy:unix:/var/run/php/php7.4-fpm.sock|fcgi://localhost/"
        </FilesMatch>
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF
a2ensite $site
service apache2 reload
fi
echo "Site $site is created!"

echo "Done!"