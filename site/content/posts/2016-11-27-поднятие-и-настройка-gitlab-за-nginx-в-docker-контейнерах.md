---
title: "Поднятие и настройка Gitlab за Nginx в Docker контейнерах"
date: "2016-11-27"
aliases: ["/blog/2016/11/27/поднятие-и-настройка-gitlab-nginx-docker-контейнер/"]
categories: [DEVOPS, АВТОМАТИЗАЦИЯ]
tags: [BITBUCKET, DOCKER, GITHUB, GITLAB, NGINX, OPEN SOURCE, PULL REQUEST, RIGHT WAY, SERVER, ОПОВЕЩЕНИЯ]
---

![](/img/gitlab-nginx/c29716049a4fba84170901e80ffae117.jpg)

Удобных, открытых и приватных облачных хранилищ на текущий момент существует множество. 
Одни из популярных это Github и Bitbacket. Github предоставляет большое сообщество OS разработчиков, 
Bitbacket бесплатные приватные репозитории, но бывают прецеденты когда эти сервисы не доступны по 
техническим причинам или заблокированы на уровне вашего интернет провайдера. Именно после таких 
прецедентов начинаешь задумываться о поднятии локального хранилища с GUI.

И тогда нам на помощь приходит gitlab ce. Это удобный инструмент для просмотра в браузере кода, 
информирования об изменениях на почту, дискуссиях о коде в PullMergeRequest и много, много, много 
чего еще в этом инструменте есть. Так давайте развернем его у себя и сконфигурируем часто используемые фичи.

Контейнеризация

Как говориться: «В любой не понятной ситуации ставь на фронт nGinx!». Мы последуем этому совету.
Делается это просто через директиву proxy_pass.

```text
server {
    listen       443 ssl;
    server_name  gitlab.server.my;

    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2; # SSLv3 исключить CVE-2014-3566
    ssl_certificate    /etc/letsencrypt/live/gitlab.bpteam.net/fullchain.pem;
    ssl_certificate_key    /etc/letsencrypt/live/gitlab.bpteam.net/privkey.pem;
    ssl_ciphers "EECDH+ECDSA+AESGCM EECDH+aRSA+AESGCM EECDH+ECDSA+SHA384 EECDH+ECDSA+SHA256 EECDH+aRSA+SHA384 EECDH+aRSA+SHA256 EECDH+aRSA+RC4 EECDH EDH+aRSA RC4 !aNULL !eNULL !LOW !3DES !MD5 !EXP !PSK !SRP !DSS";

    #charset koi8-r;
    access_log  /var/www/log/nginx/access.log;
    error_log   /var/www/log/nginx/error.log;

    # Я подкрутил время ожидания и размеры запросов ибо иногда не влазил в лимиты

    client_max_body_size 300M;

    root        /var/www;

    proxy_connect_timeout       600;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;

    location / {
        proxy_pass http://gitlab.localhost:80/;
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

[О том как подключить бесплатный сертификат от Let’s Encrypt можно прочитать в соответствующей заметке (тут)](/posts/2016-10-15-пусть-всегда-будет-SSL-подключение-lets-encrypt-к-вашему-домену).

Чем хорош nGinx лично для меня, я знаю как в нем настроить доступ по ip, http логин пароль, 
и тд и тп. Не нужно разбираться в сторонних программах, и как в них это реализовано.

docker-compose-nginx.yml

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
      - ./../gitlab/nginx/gitlab.server.my.conf:/etc/nginx/conf.d/gitlab.erver.my.conf
    links:
      - gitlab.localhost
```

Следующий по плану у нас сам инструмент, GitLab, у него есть много механизмов установки

— omnibus
— из исходников
— Docker контейнер

Естественно мы выберем самый простой и быстрый способ без лишних зависимостей, 
это Docker container. Кстати он есть в [DockerHub](https://hub.docker.com/r/gitlab/gitlab-ce/).

Для удобной настройки и запуска всего этого добра асинхронно и одной командой(короткой командой) нам понадобится Docker compose.

docker-compose-gitlab.yml

```yaml
version: '2'
services:
  gitlab.server.my:
    build:
      context: ./../gitlab
      dockerfile: Dockerfile
    hostname: 'gitlab.server.my'
    image: gitlab.server.my
    expose:
      - "443"
      - "80"
      - "822"
      - "22"
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'https://gitlab.server.my'
        gitlab_rails['gitlab_shell_ssh_port'] = 822 #открытый ssh порт
        gitlab_rails['smtp_enable'] = true # настройка почтового клиента, я просто подключил gmail и не стал заморачиваться с локальным сервером
        gitlab_rails['smtp_address'] = "smtp.gmail.com"
        gitlab_rails['smtp_port'] = 587
        gitlab_rails['smtp_user_name'] = "your@gmail.com"
        gitlab_rails['smtp_password'] = "supersecretpassword"
        gitlab_rails['smtp_domain'] = "smtp.gmail.com"
        gitlab_rails['smtp_authentication'] = "login"
        gitlab_rails['smtp_tls'] = false
        gitlab_rails['smtp_enable_starttls_auto'] = true
        gitlab_rails['smtp_openssl_verify_mode'] = 'peer'
        gitlab_rails['git_timeout'] = 600
        nginx['keepalive_timeout'] = 300
        nginx['listen_port'] = 80 #Порт который слушает gitlab
        nginx['listen_https'] = false
        unicorn['worker_timeout'] = 300
        gitlab_rails['omniauth_providers'] = [ # подключаем github аккаунт для удобного управления репозиториями github в gitlab :)
            {
              "name" => "github",
              "app_id" => "secret_id",
              "app_secret" => "secret_secret",
              "url" => "https://github.com/",
              "args" => { "scope" => "githubusername:githubemail@my.com" }
            }
          ]

    volumes: # Пробросим все необходимые файлы которые мы не хотим потерять при остановке контейнера
     - ./../gitlab/gitlab-files/config:/etc/gitlab  # настройки
     - ./../gitlab/gitlab-files/logs/:/var/log/gitlab/
     - ./../gitlab/gitlab-files/data/:/var/opt/gitlab/ # git и wiki файлы всех пользователей и проектков
     - ./../gitlab/gitlab-files/logs/reconfigure/:/var/log/gitlab/reconfigure/
     - ./../gitlab/gitlab-files/home/git:/home/git # папка для пользователя под которым мы будем пушить наш код на другие сервера
     - ./../gitlab/gitlab-files/backups:/var/opt/gitlab/backups # резервные копии
```

Теперь сложив все файлы в одно место мы можем простым движением запусить наш gitlab.

```bash
docker-compose -f docker/docker-compose-nginx.yml -f docker/docker-compose-gitlab.yml up -d
```

Кстати о том [как настроить бекап своих репозиториев в разные места (gitlab, github, bitbacket, remote git)](/posts/2016-03-21-GIT-push-во-все-зеркала-репозитория) можно почитать в этой заметке.