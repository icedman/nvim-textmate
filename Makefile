all: build install

.PHONY: build install

build:
	mkdir -p build
	cd build && cmake ../ && make

install:
	mkdir -p ~/.config/nvim/lua/nvim-textmate
	cp -R ./lua/nvim-textmate ~/.config/nvim/lua/
	cp build/textmate.so ~/.config/nvim/lua/nvim-textmate

clean:
	rm -rf build

