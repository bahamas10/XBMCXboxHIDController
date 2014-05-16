NAME = XBMCXboxHIDController
OUT = ./build/Release/$(NAME)
PROG = /usr/bin/$(NAME)

OUT:
	xcodebuild
	@echo $(OUT)

install:
	cp $(OUT) $(PROG)

uninstall:
	rm -f $(PROG)

clean:
	rm -rf build

.PHONY: install uninstall clean
