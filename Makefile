USER_GROUP := $(shell id -u):$(shell id -g)

ifeq ($(OS),Windows_NT)
  detected_OS := Windows
else
  detected_OS := $(shell uname -s)
endif

.PHONY: format
format: image
	docker run --rm -u ${USER_GROUP} -v "$(CURDIR):/app" -w /app interuss/geospatial-utils uv run ruff format
	docker run --rm -u ${USER_GROUP} -v "$(CURDIR):/app" -w /app interuss/geospatial-utils uv run ruff check --fix
	docker run --rm -u ${USER_GROUP} -v "$(CURDIR):/app" -w /app interuss/geospatial-utils uv run basedpyright


.PHONY: lint
lint: shell-lint python-lint


.PHONY: python-lint
python-lint: image
	docker run --rm -u ${USER_GROUP} -v "$(CURDIR):/app" -w /app interuss/geospatial-utils uv run ruff format --check || (echo "Linter didn't succeed. You can use the following command to fix python linter issues: make format" && exit 1)
	docker run --rm -u ${USER_GROUP} -v "$(CURDIR):/app" -w /app interuss/geospatial-utils uv run ruff check || (echo "Linter didn't succeed. You can use the following command to fix python linter issues: make format" && exit 1)
	shasum -b -a 256 .basedpyright/baseline.json > /tmp/baseline-before.hash
	docker run --rm -u ${USER_GROUP} -v "$(CURDIR):/app" -w /app interuss/geospatial-utils uv run basedpyright || (echo "Typing check didn't succeed. Please fix issue and run make format to validate changes." && exit 1)
	shasum -b -a 256 .basedpyright/baseline.json > /tmp/baseline-after.hash
	diff /tmp/baseline-before.hash /tmp/baseline-after.hash || (echo "Basedpyright baseline changed, probably dues to issues that have been cleanup. Use the following command to update baseline: make format" && exit 1)


.PHONY: shell-lint
shell-lint:
	find . -type f -name '*.sh' ! -path './.*' | xargs docker run --rm -v "$(CURDIR):/geospatial-utils" -w /geospatial-utils koalaman/shellcheck


.PHONY: image
image:
	cd geospatial-utils && make image