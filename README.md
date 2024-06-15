# fuckwm
pronounced (fuckum)  
i got frustrated that my wm wasn't working properly so i rewrote it in zig (bar not included)

## Building
dependencies: zig 0.12.x, Xorg and libc

compile with:
```sh
$ make
```

## Installing
**make sure to edit src/config.zig before building**
```sh
$ make install
```

add this to /usr/share/xsessions/fuckwm.desktop:
```config
[Desktop Entry]
Encoding=UTF-8
Name=fuckwm
Exec=fuckwm
Type=Application
X-LightDM-DesktopName=fuckwm
X-GNOME_WMName=fuckwm
DesktopNames=fuckwm
```

## Images
because of course i need to show it off
![sample_0](https://i.imgur.com/g21ayWY.png)
![sample_1](https://i.imgur.com/4Ur53EE.png)
