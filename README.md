# bpt22.tech

## Serve

```
docker-compose run --rm blog sh
cd bpt22.tech
hugo server --baseURL http://127.0.0.1:1313 --bind=0.0.0.0
```

## Build

```
docker-compose run --rm blog sh
cd bpt22.tech
hugo --minify --destination /usr/share/html/bpt22.tech 
```