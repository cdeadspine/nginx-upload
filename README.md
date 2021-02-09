# nginx-upload
bitnami-docker-nginx with nginx_upload_module

as explained by https://github.com/bitnami/bitnami-docker-nginx#adding-custom-nginx-modules
    and https://www.nginx.com/resources/wiki/extending/converting/

(maintainer deploys with)
    docker build -t cdeadspine/nginx-upload:1.19.6-debian-10-r48 .
#quicktest
    docker run --name nginx -P cdeadspine/nginx-upload:1.19.6-debian-10-r48
    docker port nginx
    localhost:49154

    docker push cdeadspine/nginx-upload:1.19.6-debian-10-r48



(abaondoned since setting up php backend just to rename a file is much harder than just:)
server {
    listen 127.0.0.1:4000;
    location / {
      alias /opt/bitnami/nginx/html/;
      index success.html;      
    }
    error_page  405     =200 $uri;
  }
  server {
    listen 8080;
    client_max_body_size 15k;
    
    location /remote {
      alias /opt/bitnami/nginx/html/;
      try_files $uri $uri/index.html;        
    }
    location = /remote/submit {      
      client_body_temp_path /opt/bitnami/nginx/upload;        
      client_body_in_file_only on;
      client_body_buffer_size    15K;
      client_max_body_size       15K;
      client_body_timeout        3s;
      proxy_set_body             off;
      proxy_pass                 http://127.0.0.1:4000/;
    }
  }