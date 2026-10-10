# Shortcuts for building Hyperkey. Type `make help` to see them.

BUILD = xcodebuild -project Hyperkey.xcodeproj -scheme Hyperkey -derivedDataPath build -quiet

.PHONY: help project run install clean

help:
	@echo "make run      build a test version and open it"
	@echo "make install  build the real version and put it in /Applications"
	@echo "make clean    delete everything that building creates"

# Recreate Hyperkey.xcodeproj from project.yml (picks up new or renamed files).
project:
	xcodegen --quiet

run: project
	$(BUILD) -configuration Debug build
	-pkill -x Hyperkey
	open build/Build/Products/Debug/Hyperkey.app

install: project
	$(BUILD) -configuration Release build
	-pkill -x Hyperkey
	ditto build/Build/Products/Release/Hyperkey.app /Applications/Hyperkey.app
	open /Applications/Hyperkey.app

clean:
	rm -rf build Hyperkey.xcodeproj
