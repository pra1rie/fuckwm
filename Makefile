
all:
	zig build --release=fast

install: all
	install zig-out/bin/fuckwm /usr/local/bin/

