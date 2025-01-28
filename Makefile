PROJECT_NAME := workflows

.DEFAULT_GOAL := help

GO = go
OPERATING_SYSTEM := $(shell uname -s)

TOOLS_MODFILE = tools/go.mod
TOOLS_BIN_DIR = tools/bin
TOOLS_CACHE_DIR = tools/cache
TOOLS_GO_LINT_VERSION = 1.63.4
TOOLS_PROTOC_VERSION = 24.3

PROTO_DIR_V1=proto/$(PROJECT_NAME)/v1

# INIT VARS DEPENDING ON THE OS
ifeq ($(OPERATING_SYSTEM),Linux)
	GO_LINT_DIST_NAME = golangci-lint-$(TOOLS_GO_LINT_VERSION)-linux-amd64.tar.gz
	PROTOC_DIST_LINK = https://github.com/protocolbuffers/protobuf/releases/download/v$(TOOLS_PROTOC_VERSION)/protoc-$(TOOLS_PROTOC_VERSION)-linux-x86_64.zip
endif
ifeq ($(OPERATING_SYSTEM),Windows_NT)
	GO_LINT_DIST_NAME = golangci-lint-$(TOOLS_GO_LINT_VERSION)-windows-amd64.tar.gz
	PROTOC_DIST_LINK = https://github.com/protocolbuffers/protobuf/releases/download/v$(TOOLS_PROTOC_VERSION)/protoc-$(TOOLS_PROTOC_VERSION)-win64.zip
endif
ifeq ($(OPERATING_SYSTEM),Darwin)
	GO_LINT_DIST_NAME = golangci-lint-$(TOOLS_GO_LINT_VERSION)-darwin-amd64.tar.gz
	PROTOC_DIST_LINK = https://github.com/protocolbuffers/protobuf/releases/download/v$(TOOLS_PROTOC_VERSION)/protoc-$(TOOLS_PROTOC_VERSION)-osx-x86_64.zip
endif

# GO LINT
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

## PROTOC
PROTOC_DIST_ARCHIVE = $(TOOLS_CACHE_DIR)/protoc-$(TOOLS_PROTOC_VERSION).zip
PROTOC_DIST = $(TOOLS_CACHE_DIR)/protoc-$(TOOLS_PROTOC_VERSION)

$(PROTOC_DIST_ARCHIVE):
	curl --fail --output "$@" -L "$(PROTOC_DIST_LINK)"

$(PROTOC_DIST): | $(PROTOC_DIST_ARCHIVE)
	unzip -d "$@" -o $|

PROTOC_TOOL = $(TOOLS_BIN_DIR)/protoc

$(PROTOC_TOOL): | $(PROTOC_DIST)
	cp -f $(PROTOC_DIST)/bin/protoc $@

# TOOLS
define install-go-tool =
	$(GO) build \
		-o $(TOOLS_BIN_DIR) \
		-ldflags "-s -w" \
		-modfile $(TOOLS_MODFILE)
endef

PROTOC_GEN_GO_TOOL = $(TOOLS_BIN_DIR)/protoc-gen-go
GRPC_TOOLS = $(PROTOC_GEN_GO_TOOL)
$(PROTOC_GEN_GO_TOOL):
	$(install-go-tool) google.golang.org/protobuf/cmd/protoc-gen-go

PROTOC_GEN_GO_GRPC_TOOL = $(TOOLS_BIN_DIR)/protoc-gen-go-grpc
GRPC_TOOLS += $(PROTOC_GEN_GO_GRPC_TOOL)
$(PROTOC_GEN_GO_GRPC_TOOL):
	$(install-go-tool) google.golang.org/grpc/cmd/protoc-gen-go-grpc

PROTOC_GEN_GO_GRPC_GATEWAY = $(TOOLS_BIN_DIR)/protoc-gen-grpc-gateway
GRPC_TOOLS += $(PROTOC_GEN_GO_GRPC_GATEWAY)
$(PROTOC_GEN_GO_GRPC_GATEWAY):
	$(install-go-tool) github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway

PROTOC_GEN_GO_OPENAPIV2_TOOL = $(TOOLS_BIN_DIR)/protoc-gen-openapiv2
GRPC_TOOLS += $(PROTOC_GEN_GO_OPENAPIV2_TOOL)
$(PROTOC_GEN_GO_OPENAPIV2_TOOL):
	$(install-go-tool) github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2

## COMMANDS
.PHONY: proto
proto:
	@$(PROTOC_TOOL) -I$(PROTO_DIR_V1) \
		--plugin=protoc-gen-go=$(PROTOC_GEN_GO_TOOL) \
		--go_out=$(PROTO_DIR_V1) \
		--go_opt=paths=source_relative \
		--plugin=protoc-gen-go-grpc=$(PROTOC_GEN_GO_GRPC_TOOL) \
		--go-grpc_out=$(PROTO_DIR_V1) \
		--go-grpc_opt=paths=source_relative \
		--plugin=protoc-gen-grpc-gateway=$(PROTOC_GEN_GO_GRPC_GATEWAY) \
		--grpc-gateway_out=$(PROTO_DIR_V1) \
		--grpc-gateway_opt=paths=source_relative \
		--plugin=protoc-gen-openapiv2=$(PROTOC_GEN_GO_OPENAPIV2_TOOL) \
		./$(PROTO_DIR_V1)/**/*.proto

.PHOHY: create-cache-dir
create-cache-dir:
	$(shell mkdir -p $(TOOLS_CACHE_DIR))

.PHOHY: install-lint
install-lint: create-cache-dir | $(GO_LINT_TOOL)

.PHOHY: install-protoc
install-protoc: create-cache-dir | $(PROTOC_TOOL)

.PHOHY: install-tools
# install-tools: install-lint install-protoc clean-tools-cache
install-tools: $(GRPC_TOOLS)

.PHOHY: lint
lint:
	$(GO_LINT_TOOL) run cmd/workflows/main.go --sort-results

.PHONY: build
build:
	$(GO) build -o bin/$(PROJECT_NAME) cmd/$(PROJECT_NAME)/main.go

.PHONY: run
run:
	$(GO) run cmd/$(PROJECT_NAME)/main.go

.PHONY: clean-tools-cache
clean-tools-cache:
	@echo $(TOOLS_CACHE_DIR)
	rm -rf $(TOOLS_CACHE_DIR) ## clean tools/cache

.PHONY: help
help:
	@echo "command           | description"
	@echo "=============================================="
	@echo "help              | info for project make commands"
	@echo "run               | run project"
	@echo "build               | build project"
	@echo "install-lint      | install go lint tool"
	@echo "install-protoc    | install porto compiler"
	@echo "lint              | run go lint tool"
	@echo "install-tools     | install all tools"
	@echo "clean-tools-cache | clean tools cache folder"
