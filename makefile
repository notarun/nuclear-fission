PKG_NAME = nuclear-fission
LUA_FILES := $(shell find . -name "*.lua" -not -path "./out/*")

.PHONY: all
all: out/$(PKG_NAME).love out/web

out/$(PKG_NAME).love: $(LUA_FILES)
	@mkdir -p out/
	@zip -9 -r $@ . -x "out/*" ".git/*" ".gitignore"

.PHONY: out/web
out/web: out/$(PKG_NAME).love
	@mkdir -p out/web
	@npx love.js $< $@ --title $(PKG_NAME) -c

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
