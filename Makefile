# Dockspace Makefile
#
# Convenience entry points around the SPM build and our packaging
# scripts. Run `make` with no target for a list of available commands.

# Pin Swift toolchain assumptions. Bump when minimum macOS moves.
SWIFT ?= swift
CONFIG ?= release

.DEFAULT_GOAL := help

.PHONY: help build test run dev clean release icon format

help: ## Show this help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the executable (debug).
	$(SWIFT) build

build-release: ## Build the executable (release).
	$(SWIFT) build -c release

test: ## Run unit tests.
	$(SWIFT) test

run: ## Launch the app in dev mode (NOTE: use `make dev` for a real menu bar test).
	$(SWIFT) run Dockspace

dev: build-release ## Build a real .app bundle and open it. This is the right way to test the menu bar UX.
	./Scripts/build-app.sh release
	open ./build/Dockspace.app

app: build-release ## Build a real .app bundle (release) into build/Dockspace.app.
	./Scripts/build-app.sh release

release: ## Build + sign + notarize + DMG. Set DOCKSPACE_SIGN_IDENTITY and DOCKSPACE_NOTARY_PROFILE for full distribution.
	./Scripts/release.sh

icon: ## Regenerate the placeholder app icons via PIL.
	python3 Scripts/generate-icon.py

format: ## Check that all Swift sources match swift-format (CI uses this).
	@set -e; for f in $$(find Sources Tests -name '*.swift'); do \
		echo "lint $$f"; \
		xcrun swift-format lint --strict "$$f" || exit 1; \
	done

clean: ## Remove all build artifacts.
	$(SWIFT) package clean
	rm -rf build
