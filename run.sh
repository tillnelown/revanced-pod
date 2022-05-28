#!/bin/bash
if [ ! -d cache ]; then
	mkdir cache
fi
exec podman run --net=host -it --rm -v ~/Android/:/android -v $(pwd)/shared:/volume -v $(pwd)/cache:/root/.gradle revanced:latest

