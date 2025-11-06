#!/bin/sh

#docker run -d --rm \
exec docker run -it --rm \
  --stop-signal SIGINT \
  --stop-timeout 30 \
  --security-opt seccomp=unconfined \
  --security-opt apparmor=unconfined \
  --cap-add=SYS_ADMIN \
  --cap-add=SYS_CHROOT \
  --cap-drop=MKNOD \
  --cap-add=LEASE \
  --cap-add=SETGID \
  --cap-add=SETUID \
  --cap-add=NET_ADMIN \
  --cap-add=NET_RAW \
  --cap-add=NET_BIND_SERVICE \
  -v /usr/share/shadowrt/container:/shadowrt:ro \
  --entrypoint /shadowrt/entrypoint.sh \
  --name istoreos-shadow0 \
  --hostname istoreos-shadow0 \
  --label creator=istoreos-shadow \
  --label com.istoreos.shadow.id=istoreos-shadow0 \
  --dns 172.17.0.1 \
  --dns 8.8.8.8 \
  -p 8080:80 \
  -p 17681:7681 \
  -v /dev/net:/dev/net \
  --device /dev/fuse:/dev/fuse \
  -v /rom:/rom:ro \
  -v /mnt:/mnt:rshared \
  -v /mnt/data/is-diff/0:/overlay:rw \
  alpine
