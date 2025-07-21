VERSION := $(shell cat version)
PKG_NAME := nuclear-fission-$(VERSION)

RES_FILES := $(shell find res -type f)
LUA_FILES := $(shell find . -name "*.lua" -not -path "./out/*")

LOVE_ANDROID_VERSION := 11.5a
LOVE_ANDROID_DIR := out/love-android

GIT_HASH = $(shell git rev-parse HEAD)
GIT_USER = $(shell git config user.name)
GIT_EMAIL = $(shell git config user.email)
GIT_REPO = $(shell git config remote.origin.url)

-include makefile.inc

#       _      _    __
#  _ __| |__ _| |_ / _|___ _ _ _ __  ___
# | '_ \ / _` |  _|  _/ _ \ '_| '  \(_-<
# | .__/_\__,_|\__|_| \___/_| |_|_|_/__/
# |_|
.PHONY: zip web apk apk-debug apk aab

all: zip web apk-debug apk aab
zip: out/$(PKG_NAME).love
web: out/$(PKG_NAME)-web/love.wasm
apk-debug: out/$(PKG_NAME)-debug.apk
apk: out/$(PKG_NAME)-release.apk
aab: out/$(PKG_NAME)-release.aab

#     _          _
#  __| |___ _ __| |___ _  _
# / _` / -_) '_ \ / _ \ || |
# \__,_\___| .__/_\___/\_, |
#          |_|         |__/
gh-pages:
	@echo "Deploying: $(GIT_HASH)"
	@rm -rf out/$(PKG_NAME)-web
	@make web
	@echo "nf.nullvoid.art" > out/$(PKG_NAME)-web/CNAME
	@cd out/$(PKG_NAME)-web \
		&& git init \
		&& git config user.name "$(GIT_USER)" \
		&& git config user.email "$(GIT_EMAIL)" \
		&& git add -A \
		&& git commit -m "Deploy to gh-pages @ $(GIT_HASH)" \
		&& git remote add origin $(GIT_REPO) \
		&& git push --force origin master:gh-pages

#     _
#  __| |_  ___ _ _ ___ ___
# / _| ' \/ _ \ '_/ -_|_-<
# \__|_||_\___/_| \___/__/
.PHONY: tidy clean

tidy:
	@luacheck *.lua
	@stylua .

clean:
	@rm -rf out

#  _                     _
# | |_ __ _ _ _ __ _ ___| |_ ___
# |  _/ _` | '_/ _` / -_)  _(_-<
#  \__\__,_|_| \__, \___|\__/__/
#              |___/
out/$(PKG_NAME).love: $(LUA_FILES) $(RES_FILES) version
	@mkdir -p out/
	@zip -9 -r $@ . -x "out/*" "etc" ".*" "**/.*"

out/$(PKG_NAME)-web/love.wasm: out/$(PKG_NAME).love etc/love.css
	@mkdir -p out/$(PKG_NAME)-web
	@npx love.js $< out/$(PKG_NAME)-web --title $(PKG_NAME) -c
	@cp etc/love.css out/$(PKG_NAME)-web/theme/love.css

out/$(PKG_NAME)-debug.apk: out/$(PKG_NAME).love etc/gradle.properties
	@make configure-android-project
	@cd $(LOVE_ANDROID_DIR) && ./gradlew assembleEmbedNoRecordDebug
	@cp $(LOVE_ANDROID_DIR)/app/build/outputs/apk/embedNoRecord/debug/app-embed-noRecord-debug.apk $@

out/$(PKG_NAME)-release.apk: out/$(PKG_NAME).love etc/gradle.properties
	@make configure-android-project
	@cd $(LOVE_ANDROID_DIR) && ./gradlew assembleEmbedNoRecordRelease
	@make keystore-env
	@rm -f $@
	@zipalign -v 4 $(LOVE_ANDROID_DIR)/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk $@
	@apksigner sign --ks $(KEYSTORE_PATH) --ks-pass "pass:$(KEYSTORE_PASSWORD)" $@
	@apksigner verify --min-sdk-version 24 $@

out/$(PKG_NAME)-release.aab: out/$(PKG_NAME).love etc/gradle.properties
	@make configure-android-project
	@cd $(LOVE_ANDROID_DIR) && ./gradlew bundleEmbedNoRecordRelease
	@make keystore-env
	@cp $(LOVE_ANDROID_DIR)/app/build/outputs/bundle/embedNoRecordRelease/app-embed-noRecord-release.aab $@
	@jarsigner -keystore $(KEYSTORE_PATH) -storepass $(KEYSTORE_PASSWORD) $@ app
	@jarsigner -verify -certs $@

#  _        _
# | |_  ___| |_ __  ___ _ _ ___
# | ' \/ -_) | '_ \/ -_) '_(_-<
# |_||_\___|_| .__/\___|_| /__/
#            |_|
.PHONY: configure-android-project resize-icon keystore-env

configure-android-project: $(LOVE_ANDROID_DIR)/.git/index
	@cp etc/AndroidManifest.xml $(LOVE_ANDROID_DIR)/app/src/main/AndroidManifest.xml
	@cp etc/gradle.properties $(LOVE_ANDROID_DIR)/gradle.properties
	@sed -i 's/\(app.version_name=\).*/\1$(VERSION)/' $(LOVE_ANDROID_DIR)/gradle.properties
	@sed -i 's/\(app.version_code=\).*/\1$(shell echo $(VERSION) | sed 's/\.//g')/' $(LOVE_ANDROID_DIR)/gradle.properties
	@make resize-icon
	@cp out/$(PKG_NAME).love $(LOVE_ANDROID_DIR)/app/src/embed/assets/game.love

$(LOVE_ANDROID_DIR)/.git/index:
	@git clone \
		--recurse-submodules \
		--depth 1 \
		-b $(LOVE_ANDROID_VERSION) \
		https://github.com/love2d/love-android  \
		$(LOVE_ANDROID_DIR)

keystore-env:
ifndef KEYSTORE_PATH
	$(error KEYSTORE_PATH variable is not set)
endif
ifndef KEYSTORE_PASSWORD
	$(error KEYSTORE_PASSWORD variable is not set)
endif

resize-icon: res/icon.png
	@magick $< -resize 72x72 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-hdpi/love.png
	@magick $< -resize 48x48 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-mdpi/love.png
	@magick $< -resize 96x96 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-xhdpi/love.png
	@magick $< -resize 144x144 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-xxhdpi/love.png
	@magick $< -resize 192x192 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-xxxhdpi/love.png
