#!/bin/bash

CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -a -ldflags '-s -w -extldflags "-static"' -o forkapp
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -trimpath -a -ldflags '-s -w -extldflags "-static"' -o forkapp.exe
CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -trimpath -a -ldflags '-s -w -extldflags "-static"' -o forkapp_mac

