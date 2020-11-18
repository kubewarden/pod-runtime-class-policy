HYPERFINE := $(shell command -v hyperfine 2> /dev/null)
CONTAINER_RUNTIME ?= $(shell command -v podman 2> /dev/null || shell command -v docker 2> /de/null)

.PHONY: deps
deps:
ifndef CONTAINER_RUNTIME 
	@printf "Please install either docker or podman"
	exit 1
endif


.PHONY: build
build: deps
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code ghcr.io/swiftwasm/swift sh -c "cd /code && swift build --triple wasm32-unknown-wasi"

.PHONY: release
release: deps
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code ghcr.io/swiftwasm/swift sh -c "cd /code && swift build -c release --triple wasm32-unknown-wasi"
	cp .build/release/policy.wasm .

.PHONY: run
run: build
	wasmtime run --env RUNTIME_CLASS=kata .build/debug/policy.wasm

.PHONY: clean
clean:
	rm -rf .build

.PHONY: test
test: deps
	$(CONTAINER_RUNTIME) run --rm -v `pwd`:/code ghcr.io/swiftwasm/swift sh -c "cd /code && swift build --build-tests --triple wasm32-unknown-wasi"
	wasmtime .build/debug/pod-runtime-class-policyPackageTests.wasm

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
