HYPERFINE := $(shell command -v hyperfine 2> /dev/null)
CONTAINER_RUNTIME ?= $(shell command -v podman 2> /dev/null || shell command -v docker 2> /de/null)
CONTAINER_IMAGE := "ghcr.io/swiftwasm/swiftwasm-action:5.3"

.PHONY: deps
deps:
ifndef CONTAINER_RUNTIME 
	@printf "Please install either docker or podman"
	exit 1
endif


.PHONY: build
build: deps
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && swift build --triple wasm32-unknown-wasi"

.PHONY: release
release: deps
	@printf "Build release target"
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && swift build -c release --triple wasm32-unknown-wasi"
	@printf "Strip WASM binary"
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && wasm-strip .build/wasm32-unknown-wasi/release/policy.wasm"
	@printf "Optimize WASM binary, hold on..."
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && wasm-opt -Os .build/wasm32-unknown-wasi/release/policy.wasm -o policy.wasm"

.PHONY: clean
clean:
	rm -rf .build

.PHONY: test
test: deps
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && carton test"

.PHONY: bench
bench: release
ifndef HYPERFINE
	cargo install hyperfine
endif
	@printf "\nAccepting policy\n"
	hyperfine --warmup 10 "cat Tests/Examples/PodRequestWithRuncRuntime.json | wasmtime run --env RESERVED_RUNTIME=runC --env TRUSTED_USERS="alice,bob" --env TRUSTED_GROUPS="system:authenticated" policy.wasm"

	@printf "\nRejecting policy\n"
	hyperfine --warmup 10 "cat Tests/Examples/PodRequestWithRuncRuntime.json | wasmtime run --env RESERVED_RUNTIME=runC --env TRUSTED_USERS="alice,bob" --env TRUSTED_GROUPS="trusted-users" policy.wasm"

	@printf "\nOperation not relevant\n"
	hyperfine --warmup 10 "cat Tests/Examples/PodDeleteRequest.json | wasmtime run --env RESERVED_RUNTIME=runC --env TRUSTED_USERS="alice,bob" --env TRUSTED_GROUPS="trusted-users" policy.wasm"
