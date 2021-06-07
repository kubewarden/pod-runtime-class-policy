CONTAINER_RUNTIME ?= docker
CONTAINER_IMAGE := "ghcr.io/swiftwasm/swiftwasm-action:5.3"

build:
ifndef CONTAINER_RUNTIME
	@printf "Please install either docker or podman"
	exit 1
endif
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && swift build --triple wasm32-unknown-wasi"

shell:
ifndef CONTAINER_RUNTIME
	@printf "Please install either docker or podman"
	exit 1
endif
	$(CONTAINER_RUNTIME) run --rm -ti -v $(PWD):/code --entrypoint /bin/bash $(CONTAINER_IMAGE)

test:
ifndef CONTAINER_RUNTIME
	@printf "Please install either docker or podman"
	exit 1
endif
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && carton test"

clean:
	sudo rm -rf .build
	rm -rf policy.wasm

release:
ifndef CONTAINER_RUNTIME
	@printf "Please install either docker or podman"
	exit 1
endif
	@printf "Build WebAssembly module"
	$(CONTAINER_RUNTIME) run --rm -v $(PWD):/code --entrypoint /bin/bash $(CONTAINER_IMAGE) -c "cd /code && swift build -c release --triple wasm32-unknown-wasi"

	@printf "Strip Wasm binary\n"
	sudo chmod 777 .build/wasm32-unknown-wasi/release/Policy.wasm
	wasm-strip .build/wasm32-unknown-wasi/release/Policy.wasm

	@printf "Optimize Wasm binary, hold on...\n"
	wasm-opt -Os .build/wasm32-unknown-wasi/release/Policy.wasm -o policy.wasm

annotate:
	kwctl annotate -m metadata.yml -o policy-annotated.wasm policy.wasm
