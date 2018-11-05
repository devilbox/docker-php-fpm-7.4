# PHP-FPM 7.4

[![Build Status](https://travis-ci.org/devilbox/docker-php-fpm-7.4.svg?branch=master)](https://travis-ci.org/devilbox/docker-php-fpm-7.4)
![Tag](https://img.shields.io/github/tag/devilbox/docker-php-fpm-7.4.svg)
[![Join the chat at https://gitter.im/devilbox/Lobby](https://badges.gitter.im/devilbox/Lobby.svg)](https://gitter.im/devilbox/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![](https://images.microbadger.com/badges/version/devilbox/php-fpm-7.4.svg)](https://microbadger.com/images/devilbox/php-fpm-7.4 "php-fpm-7.4")
[![](https://images.microbadger.com/badges/image/devilbox/php-fpm-7.4.svg)](https://microbadger.com/images/devilbox/php-fpm-7.4 "php-fpm-7.4")
[![](https://images.microbadger.com/badges/license/devilbox/php-fpm-7.4.svg)](https://microbadger.com/images/devilbox/php-fpm-7.4 "php-fpm-7.4")

This repository will provide you a fully functional PHP-FPM 7.4 Docker image built from [official sources](https://github.com/php/php-src) nightly. It provides the base for [Devilbox PHP-FPM Docker images](https://github.com/devilbox/docker-php-fpm).


| Docker Hub | Upstream Project |
|------------|------------------|
| <a href="https://hub.docker.com/r/devilbox/php-fpm-7.4"><img height="82px" src="http://dockeri.co/image/devilbox/php-fpm-7.4" /></a> | <a href="https://github.com/cytopia/devilbox" ><img height="82px" src="https://raw.githubusercontent.com/devilbox/artwork/master/submissions_banner/cytopia/01/png/banner_256_trans.png" /></a> |

## Similar Base Images

* [PHP-FPM 5.2](https://github.com/devilbox/docker-php-fpm-5.2)
* [PHP-FPM 5.3](https://github.com/devilbox/docker-php-fpm-5.3)


## Usage

Add the following `FROM` line into your Dockerfile:

```dockerfile
FROM devilbox/php-fpm-7.4:latest
```

## License

**[MIT License](LICENSE)**

Copyright (c) 2018 [cytopia](https://github.com/cytopia)
