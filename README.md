# bpt22.tech

## Serve

```
docker-compose run --rm blog sh
cd bpt22.tech
hugo server -b http://localhost:1313 --bind=0.0.0.0
```

## Build

```
docker-compose run --rm blog sh
cd bpt22.tech
hugo -d /usr/share/html/bpt22.tech
```