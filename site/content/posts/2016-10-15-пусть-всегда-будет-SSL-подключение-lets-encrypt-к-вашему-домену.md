---
title: "Пусть всегда будет SSL (подключение let's encrypt к вашему домену)"
date: "2016-10-15"
aliases: ["/blog/2016/10/15/пусть-всегда-будет-ssl-подключение-lets-encrypt/"]
categories: ["DEVOPS"]
tags: [DOCKER, LETSENCRYPT, LINUX, NGINX, RIGHT WAY, ПАРАНОЙЯ]
---

![](/img/letsencrypt-docker/lets-encrypt-768x480.jpg)

Про то, что нужно поднимать nginx перед всем подрят для контроля трафика, это всем известно, а прикручивать ssl для шифрования трафика и для понижения уровня паранойи, то что доктор прописал. Ниже будет описан способ для подключения бесплатного сервиса Let’s encrypt и ваших доменов с автоматическим продлением сертификатов.

Это первая часть из цикла инструкций на тему [создание автоматического комплекса для анализа технического долга и качества проект](/posts/2016-10-15-автоматическая-проверка-кода-после-commit-или-merge-request).

Я использую Docker для всего подрят, так как с ним легко поднимать необходимое ПО и избавляться от этого ПО также легко без какиз либо последствий. Кстати есть небольшая [инструкция для поднятия php dev окружения при помощи docker](/posts/2015-11-08-развертывание-среды-разработки-с-помощью-docker).

Для паралельного поднятия нескольких сервисов я использую множественное подключение файлов конфигурации docker-compose. И поднятие сервисов выглядит примерно так:

```bash
docker-compose \
-f ./nginx/docker-compose.yml \
-f ./service1/docker-compose.yml \
-f ./service2/docker-compose.yml \
up -d
```

В основном файле nginx я прописываю динамическое подключение файлов с блоками server

```text
#...
http {
    include /etc/nginx/conf.d/*.conf;
}
#...
```

Далее в файле nginx/docker-compose.yml пробрасываю необходимые файлы конфигураций для nginx:

```yaml
version: '2'
services:
  nginx:
    build:
      context: ./../nginx
      dockerfile: dockerfile-nginx
    image: my/nginx
    ports:
      - 80:80
      - 443:443
    volumes:
      - ./../nginx/config/fastcgi_params:/etc/nginx/fastcgi_params
      - ./../nginx/config/koi-utf:/etc/nginx/koi-utf
      - ./../nginx/config/koi-win:/etc/nginx/koi-win
      - ./../nginx/config/mime.types:/etc/nginx/mime.types
      - ./../nginx/config/nginx.conf:/etc/nginx/nginx.conf
      - ./../nginx/config/scgi_params:/etc/nginx/scgi_params
      - ./../nginx/config/uwsgi_params:/etc/nginx/uwsgi_params
      - ./../nginx/config/win-utf:/etc/nginx/win-utf

      - ./../nginx/config/conf.d/type.conf:/etc/nginx/conf.d/type.conf
      - ./../nginx/config/conf.d/log.conf:/etc/nginx/conf.d/log.conf
      - ./../nginx/config/conf.d/default-http-config.conf:/etc/nginx/conf.d/default-http-config.conf
      - ./../nginx/config/conf.d/_.conf:/etc/nginx/conf.d/_.conf

      - ./../nginx/log/nginx/:/var/www/log/nginx
    #Проброс папки с letsencrypt файлами
      - ./../letsencrypt/ssl:/etc/letsencrypt
      - ./../letsencrypt/nginx/letsencript-location.conf:/etc/nginx/letsenctypt.conf
      - ./../letsencrypt/webroot:/var/www/letsencrypt
    # Подключаем настройки от других сервисов для проксирования через nginx
      - ./../service1/nginx/conf.d/service1.net.conf:/etc/nginx/conf.d/service1.net.conf
      - ./../service2/nginx/service2.net.conf:/etc/nginx/conf.d/service2.net.conf
      - ./../service3/nginx/service3.net.conf:/etc/nginx/conf.d/service3.net.conf

      - ./../service4/nginx/service4.net:/etc/nginx/conf.d/service4.net.conf
      - ./../service4/data:/var/www/service4

    # Подключение хостов для использования в fastcgi_pass и proxy_pass
    links:
      - service1.net
      - service2.net
```

Как видно выше из конфигурации docker-compose для nginx мы пробрасываем индивидуальные файлы конфигурации веб сервера. В большенстве случаев они выглядят примерно так:

```text
server {
    listen       443 ssl;
    server_name  service1.net;

    Пока мы не сгенерировали ssl сертификаты, закомментируем эту часть конфигурации
    #ssl_protocols       TLSv1 TLSv1.1 TLSv1.2; # SSLv3 исключить CVE-2014-3566
    #ssl_certificate	/etc/letsencrypt/live/service1.net/fullchain.pem;
    #ssl_certificate_key	/etc/letsencrypt/live/service1.net/privkey.pem;
    #ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";

    #charset koi8-r;
    access_log  /var/www/log/nginx/access.log;
    error_log   /var/www/log/nginx/error.log;

    client_max_body_size 300M;

    root        /var/www;
    index       index.html;

    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;

    location / {
        proxy_pass http://service1.net:123456/;
    }

    include /etc/nginx/letsenctypt.conf;

    error_page  404              /404.html;

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }

    location ~ /\.(ht|svn|git) {
        deny all;
    }
}
```

Содержание файла letsenctypt.conf:

```text
location ~* /.well-known/acme-challenge.* {
        root /var/www/letsencrypt;
}
```

этот локейшен нужен для подтверждения вашего права на владение доменом, let’s encrypt заходит к вам по спец ссылке для верификации прав.

Конфигурация файла docker-compose service1.yml выглядит из настроек окружения для запуска контейнера генератора сертификатов:

```yaml
version: '2'
services:
  letsencrypt:
    build:
      context: ./../letsencrypt
      dockerfile: Dockerfile
    environment:
        DOMAIN: 'service1.net'
        EMAIL: 'bpteam22@gmail.com'
    image: letsencrypt/myletsencrypt
    container_name: service1.net
    volumes:
      - ./../letsencrypt/ssl:/etc/letsencrypt
      - ./../letsencrypt/webroot:/var/www/letsencrypt  
```

И файл Dockerfile имеет формат генерации запроса к letsencypt с использованием этих переменных окружения:

```Dockerfile
FROM debian:jessie

RUN apt-get update
RUN apt-get install -y git
RUN git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt

WORKDIR /opt/letsencrypt

COPY entrypoint.sh /opt/letsencrypt

RUN chmod 755 ./letsencrypt-auto
RUN chmod 755 ./entrypoint.sh

CMD ["/opt/letsencrypt/entrypoint.sh"]
```

Файл entrypoint.sh

```bash
#!/bin/bash

CONF_FILE=/var/letsencrypt/configs/$DOMAIN.conf

mkdir -p /var/letsencrypt/configs/

echo "domains = "$DOMAIN > $CONF_FILE
echo "rsa-key-size = 4096" >> $CONF_FILE
echo "email = "$EMAIL >> $CONF_FILE
echo "text = True" >> $CONF_FILE
echo "agree-tos = True" >> $CONF_FILE
echo "renew-by-default = True" >> $CONF_FILE
echo "authenticator = webroot" >> $CONF_FILE
echo "webroot-path = /var/www/letsencrypt/" >> $CONF_FILE

./letsencrypt-auto --config $CONF_FILE certonly
```

После запуска контейнеров с нашими сервисами нужно зарегестрировать сертификат. Для этого нужно запустить контейнер с конфигурациями для нужного домена:

```bash
docker-compose -f ./letsencrypt/service1.net.yml up
```

Мы увидем после выполнения сообщение о том что сертификат успешно получен и нам нужно раскоментировать строчки в nginx конфиге для блока server в service1.net конфига ssl сертификата

```text
ssl_protocols       TLSv1 TLSv1.1 TLSv1.2; # SSLv3 исключить CVE-2014-3566
ssl_certificate	/etc/letsencrypt/live/service1.net/fullchain.pem;
ssl_certificate_key	/etc/letsencrypt/live/service1.net/privkey.pem;
ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";
```

Не забудьте перезагрузить конфигурацию в nginx контейнере

```bash
docker exec -it myNginxContainerName nginx -s reload
```