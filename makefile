VERSION := $(shell cat version)
PKG_NAME := nuclear-fission-$(VERSION)

RES_FILES := $(shell find res -type f)
LUA_FILES := $(shell find . -name "*.lua" -not -path "./out/*")

LOVE_ANDROID_VERSION := 11.5a
LOVE_ANDROID_DIR := out/love-android

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
	@cp $(LOVE_ANDROID_DIR)/app/build/outputs/apk/embedNoRecord/debug/app-embed-noRecord-debug.apk $@
	@cd $(LOVE_ANDROID_DIR) && ./gradlew assembleEmbedNoRecordDebug

out/$(PKG_NAME)-release.apk: out/$(PKG_NAME).love etc/gradle.properties
	@make configure-android-project
	@cd $(LOVE_ANDROID_DIR) && ./gradlew assembleEmbedNoRecordRelease
	# FIXME: sign apk
	@cp $(LOVE_ANDROID_DIR)/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk $@

out/$(PKG_NAME)-release.aab: out/$(PKG_NAME).love etc/gradle.properties
	@make configure-android-project
	@cd $(LOVE_ANDROID_DIR) && ./gradlew bundleEmbedNoRecordRelease
	# FIXME: sign aab
	@cp $(LOVE_ANDROID_DIR)/app/build/outputs/bundle/embedNoRecordRelease/app-embed-noRecord-release.aab $@

#  _        _
# | |_  ___| |_ __  ___ _ _ ___
# | ' \/ -_) | '_ \/ -_) '_(_-<
# |_||_\___|_| .__/\___|_| /__/
#            |_|
.PHONY: configure-android-project resize-icon

configure-android-project: $(LOVE_ANDROID_DIR)/.git/index
	@make $(LOVE_ANDROID_DIR)/gradle.properties
	@make resize-icon
	@cp out/$(PKG_NAME).love $(LOVE_ANDROID_DIR)/app/src/embed/assets/game.love

$(LOVE_ANDROID_DIR)/.git/index:
	@git clone \
		--recurse-submodules \
		--depth 1 \
		-b $(LOVE_ANDROID_VERSION) \
		https://github.com/love2d/love-android  \
		$(LOVE_ANDROID_DIR)

$(LOVE_ANDROID_DIR)/gradle.properties: etc/gradle.properties
	@cp $< $@
	@sed -i 's/\(app.version_name=\).*/\1$(VERSION)/' $@

resize-icon: res/icon.png
	@magick $< -resize 72x72 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-hdpi/love.png
	@magick $< -resize 48x48 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-mdpi/love.png
	@magick $< -resize 96x96 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-xhdpi/love.png
	@magick $< -resize 144x144 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-xxhdpi/love.png
	@magick $< -resize 192x192 $(LOVE_ANDROID_DIR)/app/src/main/res/drawable-xxxhdpi/love.png

# .PHONY: deploy/android
# deploy/android: out/android
# ifndef KEYSTORE
# 	$(error KEYSTORE variable is not set)
# endif
# 	@rm -f out/*.apk*
# 	@zipalign -v 4 out/android/app/build/outputs/apk/embedNoRecord/release/app-embed-noRecord-release-unsigned.apk out/$(PKG_NAME).apk
# 	@apksigner sign --ks $(KEYSTORE) out/$(PKG_NAME).apk
# 	@apksigner verify out/$(PKG_NAME).apk
