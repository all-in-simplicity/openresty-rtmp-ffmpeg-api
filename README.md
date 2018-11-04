# Example of a Docker based Media Streaming Server powered by nginx-rtmp and a Go API

<img src="https://thiago-dev.github.io/nginx-streaming-example.gif"></img>
## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
	* [Configure OBS](#configure-obs)
	* [Docker Compose](#docker-compose)
	* [Customize nginx configuration](#customize-nginx-configuration)
- [FFmpeg Compile Options](#ffmpeg-compile-options)
- [Built With](#built-with)
- [License](#license)

## Overview
This Repository contains a sample implementation of a Docker based Media Streaming Server which is powered by **OpenResty** with the **nginx-rtmp module**, **ffmpeg**, a very simple **Go API** and an example HTML page using **video.js** for playback.

Target audience are mainly beginners, who want to get an impression on how nginx-rtmp powered by Docker can be combined with an API in Go as a simple authentication layer.


nginx-rtmp is configured to transcode for adaptive streaming and create 4 different streams with different bitrates and quality once receiving stream.

## Prerequisites
-  [Docker](https://docs.docker.com/install/linux/docker-ce/ubuntu/)
-  [OBS Studio (optional)](https://obsproject.com/)

## Usage
To run the image:
```bash
$ docker run -d -p 80:80 -p 1935:1935 -e STREAM_KEY=yourKey thiagodev/openresty-rtmp-ffmpeg-api
```
_Note: If you dont set the environment variable **STREAM_KEY**, the API will always return 200, thus disabling the check functionality._
### Configure OBS
```
URL.......:    rtmp://localhost/live?key=yourKey
Stream Key:    test
```
The Setting **"Stream Key"** is what later gets the stream's name.
Eg. If _Stream Key_ is **_test_**, a **_test.m3u8_** will be generated.

_Note: If you change this don't forget to point video.js to the new location_
```html
# index.html
<script>
	var player = videojs('example-video');
	player.src({
  		src: 'http://localhost:80/hls/test.m3u8',
  		type: 'application/x-mpegURL'
	});
</script>
```
### Docker Compose
```yaml
version: '2'
services:
  rtmp:
    image: thiagodev/openresty-rtmp-ffmpeg-api
    ports:
      - "80:80"
      - "1935:1935"
    environment:
      - STREAM_KEY=yourKey
```
## Customize nginx configuration
_See [nginx.conf](etc/nginx/nginx.conf) for an example config._
To provide your own config start the container with a volume.
```bash
$ docker run -d -p 80:80 -p 1935:1935 -e STREAM_KEY=yourKey -v /path/to/your/nginx.conf:/usr/local/openresty/nginx/conf/nginx.conf:ro thiagodev/openresty-rtmp-ffmpeg-api
```
## FFmpeg Compile Options
```
ffmpeg version 4.0.2 Copyright (c) 2000-2018 the FFmpeg developers
  built with gcc 6.4.0 (Alpine 6.4.0)
  configuration:
  	--bindir=/usr/bin
  	--disable-debug
  	--disable-doc
  	--disable-ffplay
  	--enable-avresample
  	--enable-gnutls
  	--enable-gpl
  	--enable-libass
  	--enable-libfreetype
  	--enable-libmp3lame
  	--enable-libopus
  	--enable-librtmp
  	--enable-libtheora
  	--enable-libfdk-aac
      --enable-libvorbis
      --enable-libvpx
      --enable-libwebp
      --enable-libx264
      --enable-libx265
      --enable-nonfree
      --enable-postproc
      --enable-small
      --enable-version3
```

## Built With

* [OpenResty](https://openresty.org/en/) - Dynamic web platform based on NGINX and LuaJIT
* [nginx-rtmp](https://github.com/arut/nginx-rtmp-module) - NGINX-based Media Streaming Server
* [Gin](https://github.com/gin-gonic/gin) - HTTP web framework written in Go (Golang)
* [FFmpeg](https://ffmpeg.org) - Cross-platform solution to record, convert and stream audio and video
* [video.js](https://videojs.com/) - The Player Framework

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

