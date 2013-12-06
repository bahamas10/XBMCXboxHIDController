prog = XBMCXboxHIDController
all:
	xcodebuild
	@echo "./build/Release/$(prog)"

install:
	cp build/Release/$(prog) /usr/bin

uninstall:
	rm /usr/bin/$(prog)

clean:
	rm -rf build
