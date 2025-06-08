PKG_NAME = nuclear-fission
LUA_FILES := $(shell find . -name "*.lua" -not -path "./out/*")

.PHONY: all
all: out/$(PKG_NAME).love out/web out/android

out/$(PKG_NAME).love: $(LUA_FILES)
	@mkdir -p out/
	@zip -9 -r $@ . -x "out/*" "etc" "art" ".*" "**/.*"

.PHONY: out/web
out/web: out/$(PKG_NAME).love
	@mkdir -p out/web
	@npx love.js $< $@ --title $(PKG_NAME) -c
	@cp etc/love.css $@/theme/love.css

.PHONY: out/android
out/android: out/$(PKG_NAME).love
	@if [ ! -d out/android/.git ]; then \
		git clone --recurse-submodules --depth 1 -b 11.5a https://github.com/love2d/love-android out/android; \
	fi
	@cp etc/gradle.properties $@/gradle.properties
	@magick res/icon.png -resize 72x72 $@/app/src/main/res/drawable-hdpi/love.png
	@magick res/icon.png -resize 48x48 $@/app/src/main/res/drawable-mdpi/love.png
	@magick res/icon.png -resize 96x96 $@/app/src/main/res/drawable-xhdpi/love.png
	@magick res/icon.png -resize 144x144 $@/app/src/main/res/drawable-xxhdpi/love.png
	@magick res/icon.png -resize 192x192 $@/app/src/main/res/drawable-xxxhdpi/love.png
	@cp $< $@/app/src/embed/assets/game.love
	@cd $@ && ./gradlew assembleEmbedNoRecord

.PHONY: deploy
deploy: deploy/web deploy/android

.PHONY: deploy/web
deploy/web: out/web
ifndef REMOTE
	$(error REMOTE variable is not set)
endif
	@rsync -r out/web/ $(REMOTE):~/www/g/nf

.PHONY: deploy/android
deploy/android: out/android
ifndef KEYSTORE
	$(error KEYSTORE variable is not set)
endif
	@rm -f out/*.apk*
	@zipalign -v 4 out/android/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk out/$(PKG_NAME).apk
	@apksigner sign --ks $(KEYSTORE) out/$(PKG_NAME).apk
	@apksigner verify out/$(PKG_NAME).apk

.PHONY: clean
clean:
	@rm -rf out

.PHONY: dev
dev:
	@love .

.PHONY: lint
lint:
	@luacheck *.lua

.PHONY: fmt
fmt:
	@stylua .

.PHONY: tidy
tidy: lint fmt
