PKG_NAME = nuclear-fission
LUA_FILES := $(shell find . -name "*.lua" -not -path "./out/*")

.PHONY: all
all: out/$(PKG_NAME).love out/web out/android

out/$(PKG_NAME).love: $(LUA_FILES)
	@mkdir -p out/
	@zip -9 -r $@ . -x "out/*" ".git/*" ".gitignore"

.PHONY: out/web
out/web: out/$(PKG_NAME).love
	@mkdir -p out/web
	@npx love.js $< $@ --title $(PKG_NAME) -c
	@cp etc/love.css $@/theme/love.css

.PHONY: out/android
out/android: out/$(PKG_NAME).love
	@mkdir -p out/android/app/src/embed/assets
	@if [ ! -d out/android/.git ]; then \
		echo "Cloning love-android..."; \
		git clone --recurse-submodules --depth 1 -b 11.5a https://github.com/love2d/love-android out/android; \
	fi
	@cp etc/gradle.properties $@/gradle.properties
	@cp res/icon_72x72.png $@/app/src/main/res/drawable-hdpi/love.png
	@cp res/icon_96x96.png $@/app/src/main/res/drawable-mdpi/love.png
	@cp res/icon_96x96.png $@/app/src/main/res/drawable-xhdpi/love.png
	@cp res/icon_144x144.png $@/app/src/main/res/drawable-xxhdpi/love.png
	@cp res/icon_192x192.png $@/app/src/main/res/drawable-xxxhdpi/love.png
	@cp $< $@/app/src/embed/assets/game.love
	@cd $@ && ./gradlew assembleEmbedNoRecord

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
