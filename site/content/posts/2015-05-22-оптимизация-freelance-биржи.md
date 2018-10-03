---
title: "Оптимизация freelance биржи"
date: "2015-05-22"
tags: [ЛЕНЬ, ОПОВЕЩЕНИЯ, ПАРСИНГ, СКОРОСТЬ]
---

![img0](/img/big.jpeg)

Одна из главных моих болезней это все автоматизировать и реализовывать универсальные решения даже там где это не нужно. Но некоторые идеи могут оказаться полезными и облегчают жизнь. Один из таких проектов это оповещение о новых и интересных проектах на фриланс биржах.

Удобство заключается в том, что пользователю не нужно постоянно просматривать сайт на наличие интересующих его проектов. Выбрав интересующею категорию проектов и вводит перечень ключевых слов через пробел и в последствии скрипт с выбранной периодичностью заходит на сайт и проверяет проекты и сканирует текст на наличие ключевых слов. Если находит совпадение то шлет оповещение на Email текст и ссылку на проект. Интерфейс сервиса будет состоять из поля для ввода Email, select с категориями, text для ключевых слов, и checkbox для сайтов бирж.
Ниже приведен прототип проекта который уже работает и оповещает меня о новых проектах. Реализован сканер RSS ленты одной из русской freelance биржи в категории Веб-программирование.

```php
<?php
ini_set('display_errors',1);
require_once dirname(__FILE__).'/../_coolLib/loader-curl-phantomjs-proxy/include.php';
require_once dirname(__FILE__).'/cfg.php';
$url = 'https://www.fl.ru/rss/all.xml?subcategory=37&category=5';
$gc = new \GetContent\cSingleCurl();
$content = $gc->load($url);
$feed = array();
if(preg_match('%\(Все проекты:\s(?<category>((?!\s-\s).)*)((?:\s-\s)(?<subcategory>[^<]+))?\)</title>%ims', $content, $match)){
	$feed['category'] = $match['category'];
	if(isset($match['subcategory'])){
		$feed['subcategory'] = $match['subcategory'];
	}
}
if(preg_match_all('%<item>\s*<title><\!\[CDATA\[(?<title>.*)\]\]></title>\s*<link>(?<link>.*)</link>\s*<description><\!\[CDATA\[(?<description>.*)\]\]></description>\s*<guid>(?<guid>.*)</guid>\s*<category>(?<category>.*)</category>\s*<pubDate>(?<pubdate>.*)</pubDate>\s*</item>%imsU',$content,$matches)){
	foreach($matches['title'] as $keyRow => $valRow){
		$row['title'] = $matches['title'][$keyRow];
		$row['link'] = $matches['link'][$keyRow];
		$row['id'] = preg_replace('%^.*/(\d+)/.*$%ims','$1',$row['link']);
		$row['description'] = $matches['description'][$keyRow];
		$row['guid'] = $matches['guid'][$keyRow];
		$category = $matches['category'][$keyRow];
		$category = explode( '<br/>', $category);
		$row['category'] = $category;
		$row['pubdate'] = strtotime($matches['pubdate'][$keyRow]);
		$feed['row'][] = $row;
	}
}
$reg = '%(парсер|собрать|парс|parser|pars|сбор|парсинг|скачать|загрузить|наполнить|слить)%imsu';
foreach($feed['row'] as $project){
	preg_match('%https://www.fl.ru/projects/(?<id>\d+)/%', $project['link'], $match);
	$project['id'] = $match['id'];
	if((preg_match($reg,$project['title']) || preg_match($reg,$project['description'])) && isUnique($project)){
		$query = "INSERT INTO `flboost` (`id`, `title`, `description`, `date`, `category`, `url`)
			VALUES ({$project['id']}, '".$mysqli->escape_string($project['title'])."', '".$mysqli->escape_string($project['description'])."', '". $project['pubdate'] ."', '".implode("|",$project['category'])."', '{$project['link']}')";
		$mysqli->query($query);
		echo 'SEND!';
		mail('zking.nothingz@gmail.com','ALERT ' . $project['title'], $project['title'] . "\n" . date('c',$project['pubdate']) . "\n" . $project['link'] . "\n" . $project['description']);
	} else {
		//echo 'NOT!';
	}
}
echo 'done!';
function isUnique($data){
	global $mysqli;
	$query = "SELECT url FROM `flboost` WHERE `id` = {$data['id']}";
	$result = $mysqli->query($query);
	return !$result->num_rows;
}
```

Свежую версию скрипта можно скачать на [github](https://github.com/bpteam/flboost/), там-же можно помочь прокачать идею до полноценного сервиса. Для большей оперативности можно настроить SMS оповещение на телефон. Для пользователей Gmail поможет статья на [Habrahabr](http://habrahabr.ru/post/145447/).

__UPD__: 27 июня 2016 Google прикрыл рассылку SMS из календаря.