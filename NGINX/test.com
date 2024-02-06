limit_conn_zone $binary_remote_addr zone=perip:10m;


	map $remote_addr $office_ip {
	91.150.127.92 yes;
	default no;
	}


server {
	listen 80;
	server_name test.com;

	limit_conn perip 5;

	
	location / {
	rewrite ^ https://$host$request_uri? permanent;
	}
}


server {
	listen 443 ssl;
	server_name test.com;

	ssl_certificate /etc/nginx/ssl/test.com.crt;
	ssl_certificate_key /etc/nginx/ssl/test.com.key;

	limit_conn perip 5;

	location /{
		root /var/www/html;
		index index.html index.php index.html;


		if ($office_ip = no) {
			return 403;
		}
	}

	location ~ \.php$ {
		include snippets/fastcgi-php.conf;
		fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
	} 
}