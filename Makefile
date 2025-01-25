PROJECT_NAME := workflows

GO = go
OPERATING_SYSTEM := $(shell uname -s)

TOOLS_CACHE_DIR := tools/cache
TOOLS_BIN_DIR = tools/bin
TOOLS_GO_LINT_VERSION = 1.63.4

## GO LINT
ifeq ($(OPERATING_SYSTEM),Linux)
	GO_LINT_DIST_NAME = golangci-lint-$(TOOLS_GO_LINT_VERSION)-linux-amd64.tar.gz
endif
ifeq ($(OPERATING_SYSTEM),Windows_NT)
	GO_LINT_DIST_NAME = golangci-lint-$(TOOLS_GO_LINT_VERSION)-windows-amd64.tar.gz
endif
ifeq ($(OPERATING_SYSTEM),Darwin)
	GO_LINT_DIST_NAME = golangci-lint-$(TOOLS_GO_LINT_VERSION)-darwin-amd64.tar.gz
endif

GO_LINT_DIST := $(TOOLS_CACHE_DIR)/$(GO_LINT_DIST_NAME)
GO_LINT_DIST_DIR := $(TOOLS_CACHE_DIR)/$(patsubst %.tar.gz,%,$(GO_LINT_DIST_NAME))
GO_LINT_DIST_URL := https://github.com/golangci/golangci-lint/releases/download/v$(TOOLS_GO_LINT_VERSION)/$(GO_LINT_DIST_NAME)

$(GO_LINT_DIST_DIR):
	mkdir -p "$(GO_LINT_DIST_DIR)"

$(GO_LINT_DIST):
	curl -L --fail --output "$(GO_LINT_DIST)" "$(GO_LINT_DIST_URL)"


GO_LINT_DIST_BIN := $(GO_LINT_DIST_DIR)/$(patsubst %.tar.gz,%,$(GO_LINT_DIST_NAME))/golangci-lint
$(GO_LINT_DIST_BIN): | $(GO_LINT_DIST) $(GO_LINT_DIST_DIR)
	tar -xf "$(GO_LINT_DIST)" -C "$(GO_LINT_DIST_DIR)"

$(TOOLS_BIN_DIR):
	mkdir -p "$(TOOLS_BIN_DIR)"

GO_LINT_TOOL = $(TOOLS_BIN_DIR)/golangci-lint
GO_LINT_EXE_PATH = $(GO_LINT_DIST_DIR)/$(patsubst %.tar.gz,%,$(GO_LINT_DIST_NAME))/golangci-lint

$(GO_LINT_TOOL): $(GO_LINT_EXE_PATH) $(TOOLS_BIN_DIR)
	cp -f $(GO_LINT_EXE_PATH) $(GO_LINT_TOOL)

.PHOHY: lint-install
lint-install: | $(GO_LINT_DIST_DIR) $(GO_LINT_DIST) $(GO_LINT_DIST_BIN) $(GO_LINT_TOOL)
	rm -rf $(TOOLS_CACHE_DIR) ## clean tools/cache

.PHOHY: lint
lint:
	$(GO_LINT_TOOL) run cmd/workflows/main.go --sort-results

# .PHONY: build
# build:
# 	$(GO) build -o ./bin/$(PROJECT_NAME)  **/*.go

.PHONY: run
run:
	$(GO) run cmd/$(PROJECT_NAME)/main.go

.PHONY: help
help:
	@echo "command       | description"
	@echo "=============================================="
	@echo "help          | info for project make commands"
	@echo "run           | run project"
	@echo "lint-install  | install go lint tool"
	@echo "lint          | run go lint tool"
