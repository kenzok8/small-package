#!/bin/sh
mkdir -p bin
# macOS no need to change the owner
# change the owner of bin to 1000:1000 when running on linux
sudo chown -R 1000:1000 bin
docker-compose up

ls -R bin