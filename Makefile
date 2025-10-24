BINPATH = /usr/local/bin/
ENTRYPATH = /usr/share/xsessions/

all:
	zig build --release=fast

install: all
	mkdir -p $(BINPATH)
	mkdir -p $(ENTRYPATH)
	install zig-out/bin/fuckwm $(BINPATH)
	install fuckwm.desktop $(ENTRYPATH)

uninstall:
	rm $(BINPATH)/fuckwm
	rm $(ENTRYPATH)/fuckwm.desktop

.PHONY: all install uninstall
