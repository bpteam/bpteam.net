---
title: "Настройка docker registry с ограничением доступа"
date: "2018-10-07"
aliases: ["/blog/2017/02/01/Войти-в-it/"]
categories: [IT, ПРОГРАММИРОВАНИЕ]
tags: [DEVELOPMENT, DOCKER, DOCKER REGISTRY, DEVOPS, IT, WHALES CAN FLY]
---

![registry](/img/docker-registry/Screenshot%20from%202018-10-07%2019-00-02.png)

На днях выяснилось, что у одной крупной компании, которая обслуживала миллионы людей и их данные,
торчал на ружу Docker registry без ограничения на чтение и запись образов с рабочими программами
на интерпритируемых языказ(исходный код доступен).

В этой заметке я постараюсь не повторить их опыт и поднять docker реестр с ограниченный доступом
и подписаным сертификатом.

## Docker GUI

Для того чтоб можно было легко оперировать данными из Docker Registry мы развернем графическую оболочку.
Я выбрал для себя [Portainer](https://portainer.io/) - выглядит вменяемо и обладает большим набором для 
работы с api docker, registry, swarm.

![portainer](/img/docker-registry/portainer-docker-containers.jpg)