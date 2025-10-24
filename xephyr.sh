#!/bin/bash

zig build || exit 1

Xephyr -screen 1280x700 +xinerama :80 &
sleep 0.1

export DISPLAY=:80

./zig-out/bin/fuckwm
