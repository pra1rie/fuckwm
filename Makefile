
all: release

release:
	zig build -Doptimize=ReleaseFast

debug:
	zig build -Doptimize=Debug

install:
	install zig-out/bin/fuckwm /usr/local/bin/

