VERSION := 0.1.2a8
STACK_TEMPLATES_DIRECTORY := infrastructure/templates
STACK_TEMPLATE_BUILD_TARGETS := $(shell find $(STACK_TEMPLATES_DIRECTORY) -type d -depth 1 -exec basename {} \; | sed 's/^/build-/' | sed 's/$$/-stack-template/')

.PHONY: default
default: build

.PHONY: clean
clean:
	rm -rf dist

.PHONY: build
build: clean build-infrastructure build-tools build-library

.PHONY: build-tools
build-tools:
	tar -czf dist/tools.tar.gz tools

.PHONY: build-infrastructure
build-infrastructure: build-stack-templates build-macros-template copy-installation-script
	tar -czf dist/infrastructure.tar.gz -C dist infrastructure && rm -rf dist/infrastructure

.PHONY: create-infrastructure-dist-directory
create-infrastructure-dist-directory:
	mkdir -p dist/infrastructure

.PHONY: build-macros-template
build-macros-template: create-infrastructure-dist-directory
	scripts/build-template.sh infrastructure/macros/template.yaml dist/infrastructure/macros.yaml

.PHONY: build-stack-templates
build-stack-templates: $(STACK_TEMPLATE_BUILD_TARGETS)

.PHONY: build-%-stack-template
build-%-stack-template: create-templates-dist-directory
	scripts/build-template.sh infrastructure/templates/$*/template.yaml dist/infrastructure/templates/$*.yaml

.PHONY: create-templates-dist-directory
create-templates-dist-directory:
	mkdir -p dist/infrastructure/templates

.PHONY: copy-installation-script
copy-installation-script: create-infrastructure-dist-directory
	cp infrastructure/scripts/install.sh dist/infrastructure

.PHONY: build-library
build-library:
	uv build -o dist/library

.PHONY: publish-non-library-assets
publish-non-library-assets:
	gh release create --prerelease --target spike --generate-notes "$(VERSION)" dist/*.tar.gz

.PHONY: publish-library
publish-library:
	uv publish --token "$(PYPI_TOKEN)" dist/library/*