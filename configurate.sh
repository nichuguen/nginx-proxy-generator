#!/bin/bash


crt=/etc/nginx/default.pem
key=/etc/nginx/default.key
code=403

create_key=false

if [ -f $crt ] && [ -f $key ];
then
    echo "Key existing, check validity"
    if openssl x509 -checkend 86400 -noout -in $crt
    then
        echo "Certificate is good for another day!"
    else
        echo "Certificate has expired or will do so within 24 hours!"
        create_key=true 
    fi
else
    create_key=true   
fi

if [ "$create_key" = true ] ; then
    echo "creating keys"
    openssl req -x509 -newkey rsa:2048 -nodes -keyout $key -out $crt -days 365 -subj '/CN=localhost'
    echo "done"
fi

http=/etc/nginx/sites-available/http.default
ehttp=/etc/nginx/sites-enabled/http.default
https=/etc/nginx/sites-available/https.default
ehttps=/etc/nginx/sites-enabled/https.default

echo "cleaning existing files"
rm /etc/nginx/sites-enabled/default 2> /dev/null
rm $ehttp 2> /dev/null
rm $ehttps 2> /dev/null

echo "creating http file"
cat << EOF > $http
server {
    listen 80 default_server;
    server_name _;
    return $code;
}
EOF

echo "creating https file"
cat << EOF > $https
server {
    server_name _;
    listen 443 ssl default_server;

    ssl_certificate $crt;
    ssl_certificate_key $key;
    
    return $code;
}
EOF

echo "activating websites"
ln -s $http $ehttp
ln -s $https $ehttps
service nginx reload
echo "done"
