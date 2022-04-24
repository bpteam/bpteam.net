---
title: "Автоматическое скачивание torrent из dropbox в ubuntu server"
date: "2015-05-24"
aliases: ["/blog/2015/05/24/автоматическое-скачивание-torrent-из-dropbox-в-ubuntu-server/"]
categories: [АВТОМАТИЗАЦИЯ]
tags: [DROPBOX, LINUX, PIRATES, SERVER, UBUNTU, UTORRENT]
---

![img0](/img/Dropbox-uTorrent.png)

Иногда когда отключают интернет или ведутся технические работы и заняться нечем встает вопрос: «а закачал ли я фильм/сериал/передачу?». За частую ответ: «Нет!» :(. Для того чтоб не возникало подобных ситуаций я хочу развернуть на своем локальном сервере хранилище для офлайновой загрузки контента и не перегружать WiFi сеть постоянно работающими торрентами. В качестве ОС я выбрал Ubuntu server, потому что потому.

__Установка торрента__

[Источник](http://habrahabr.ru/post/145585/)

Устанавливаем torrent клиент «transmission». Он обладает удобным Web интерфейсом, который позволит нам останавливать или добавлять торренты в ручную.

```bash
sudo apt-get install transmission-daemon
```

После установки остановим сервис и внесем необходимые конфигурации:

```bash
sudo service transmission-daemon stop
sudo nano /etc/transmission-daemon/settings.json
```

Указываем папку для загрузки:

```text
'download-dir': '/mnt/myhdd/torrent'
```

Данные для доступа по веб интерфейсу:

```text
'rpc-password': 'local'
'rpc-username': 'local'
```

Требовать аутентификацию для удаленного управления:

```text
'rpc-authentication-required': true
```

Включаем белый список для доступа к интерфейсу:

```text
'rpc-whitelist': '192.168.*.*'
```

Папка для не загруженных файлов:

```text
'incomplete-dir': '/arc/Incomplete'
```

Включение предыдущей опции:

```text
'incomplete-dir-enabled': true
```

Выставляем лимит на загрузку торрентов:

```text
'download-limit': 1024
'download-limit-enabled': true
'upload-limit': 100
'upload-limit-enabled': true
```

Добавляем папки для слежения за ними и автоматической загрузки торрентов(эта папка должна быть доступна для чтения пользователю под которым запущен transmission):

```text
'watch-dir': '/path/to/watch/dir'
'watch-dir-enabled': true
```

Сохраняем настройки и запускаем сервис:

```bash
sudo service transmission-daemon start
```

Доступ к интерфейсу предоставляется через 9091 порт.

http://192.168.1.180:9091/

Добавляем в крон задание при загрузке:

```bash
@reboot /etc/init.d/transmission-daemon start
```

__Установка DropBox__


[Источник](http://ubuntovod.ru/instructions/dropbox-ubuntu-server.html)

Скачиваем DropBox

```bash
wget -O dropbox.tar.gz ‘http://www.dropbox.com/download/?plat=lnx.x86’ #32 разрядная ОС
wget -O dropbox.tar.gz ‘http://www.dropbox.com/download/?plat=lnx.x86_64’ #64 разрядная ОС
```

Распаковываем архив

```bash
tar -xvzf dropbox.tar.gz
```

Запускаем

```bash
.dropbox-dist/dropboxd
```

DropBox нам выдаст ссылку для верификации компьютера. Переходим по ссылке и входим в свою учетную запись для верификации сервера. После подтверждения начнется синхронизация, прервем ее и настроим демона.

Создадим файл /etc/init.d/dropbox со следующим содержимым:

```bash
#!/bin/sh
#dropbox service
DBU='user_name' #Ваш пользователь в системе под которым будет работать DropBox
 
DAEMON='/path/to/.dropbox-dist/dropboxd' #адрес к исполняемому файлу

HOMEDIR='/home/'$DBU'/Dropbox' #Папка для синхронизации

 
start() {
   echo 'Starting dropbox...'
       if [ -x $DAEMON ]; then
           HOME=$HOMEDIR start-stop-daemon -b -o -c $DBU -S -u $DBU -x $DAEMON
       fi
}
 


stop() {
   echo 'Stopping dropbox...'
       if [ -x $DAEMON ]; then
           start-stop-daemon -o -c $DBU -K -u $DBU -x $DAEMON
       fi
}

 
status() {
       dbpid=`pgrep -u $DBU dropbox`
       if [ -z $dbpid ] ; then
           echo 'dropboxd for USER '$DBU': not running.'
       else
           echo 'dropboxd for USER '$DBU': running (pid '$dbpid')'
       fi
}
 
case $1 in
 
   start)
       start
       ;;
   stop)
       stop
       ;;
   restart|reload|force-reload)
       stop
       start
       ;;
   status)
       status
       ;;
   *)
       echo 'Usage: /etc/init.d/dropbox {start|stop|reload|force-reload|restart|status}'
       exit 1
 
esac
 
exit 0
```

Добавляем права на запуск


```bash
sudo chmod +x /etc/init.d/dropbox && sudo update-rc.d dropbox defaults
```

Далее можно управлять DropBox командами:

```bash
sudo service dropbox start # Запуск Dropbox
sudo service dropbox stop # Остановка Dropbox
sudo service dropbox restart # Перезапуск Dropbox
sudo service dropbox status # Состояние Dropbox
```

Добавим команду в крон

```bash
@reboot /etc/init.d/dropbox start
```

Все готово, теперь transmission будет ставить в очередь для закачки все torrent файлы из папки установленной в опции watch-dir. Можно из любого места добавить torrent в DropBox и он вас будет ждать дома.

__Просмотр файлов__

Для удобного потребления контента можно воспользоваться проигрователем который поддерживает просмотр файлов по сети. Изначально я остановился на веб ориентированом менеджере Ampache, он позволяет скачивать файлы, просматривать их в потоке и смотреть через Web плеер, но к сажелению своей функциональностью он меня не зацепил ибо был избыточен в использовании и прямое его назначение стрим музыки. По этому было решено использовать родной XBMC(ныне Kodi).

Подключаться к серверу мы будем через SFTP, он идет по умолчанию с OpenSSH и как мне кажется очень удобен, так как Kodi поддерживает его из коробки. Перейдем к делу.

Скачаем и установим Kodi с официального сайта. В основном меню выберем Video ->Add video->Browse->Add network location.
В предложеном списке найдем SFTP, введем наши настройки сервера и сохраним.

![img1](/img/Screenshot_021015_053038_AM.jpg)

В разделе Video появится наша папку с фильмами и названием которое вы введете.

![img2](/img/Screenshot_021015_053302_AM.jpg)

Единственно что теперь вас может остановить, это отключение электричества.