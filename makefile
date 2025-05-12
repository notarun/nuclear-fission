LUA_FILES := $(shell find . -name "*.lua" -not -path "./out/*")

out/nuclear-fission.love: $(LUA_FILES)
	@mkdir -p out/
	@zip -9 -r $@ . -x "out/*" ".git/*" ".gitignore"

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
