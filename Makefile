ZIP     := DAoC-Mac-Installer.zip
VERSION ?= v1.0.0

.PHONY: install zip release clean

install:            ## run the installer from this checkout
	zsh ./install.sh

zip: $(ZIP)         ## build the double-click package
$(ZIP): install.sh Install\ DAoC.command INSTALL.txt payload/camelot.exe payload/patch.cfg payload/daoc.icns
	rm -f $(ZIP)
	mkdir -p build/DAoC-Mac-Installer
	cp install.sh 'Install DAoC.command' INSTALL.txt build/DAoC-Mac-Installer/
	cp -R payload build/DAoC-Mac-Installer/
	cd build && zip -qr ../$(ZIP) DAoC-Mac-Installer -x '*.DS_Store'
	rm -rf build

release: zip        ## tag and publish the zip on GitHub Releases
	git tag -f $(VERSION)
	git push -f origin $(VERSION)
	gh release create $(VERSION) $(ZIP) --title "$(VERSION)" --notes "Download DAoC-Mac-Installer.zip, unzip, double-click Install DAoC.command. See README." || \
	gh release upload $(VERSION) $(ZIP) --clobber

clean:              ## remove scratch Wine install and prefix (several GB)
	rm -rf wine prefix build $(ZIP)
