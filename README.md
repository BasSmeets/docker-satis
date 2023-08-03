# Docker-satis
# Introduction
Docker satis private package repository

A docker image with configuration to run [Satis](https://github.com/composer/satis)
* php8.1
* nginx
* composer 2

Based on the work done [here](https://github.com/ypereirareis/docker-satis)\
This image bundles nginx and php into 1 container.

# Install

## Building the container
```
docker build .
```

## Setup
Make sure the appropiate files are mounted into the container.

```
<your_satis.json_file> -> /satisfy/satis.json
<your_parameters.json_file> -> /satisfy/app/config/parameters.yml
<your_private_key> -> /tmp/id_rsa
<your_nginx_config> -> /etc/nginx/http.d/satis.conf (OPTIONAL AS BASE CONFIG PROVIDED)
```

## Run using docker-compose

```
cp ./config/parameters.yml.dist ./config/parameters.yml
cp ./config/satis.json.dist ./config/satis.json
cp <your_private_key> ./ssh/id_rsa
```

Or create a parameters.yml and a satis.json based on your project needs.
For more information check the [satisfy project](https://github.com/project-satisfy/satisfy)

Run
```
docker-compose up
```
Application will be available under http://localhost:8080
