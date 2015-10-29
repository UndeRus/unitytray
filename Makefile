all: unity_tray.c
	gcc unity_tray.c `pkg-config gtk+-2.0 appindicator-0.1 --cflags --libs`  -o unity_tray
