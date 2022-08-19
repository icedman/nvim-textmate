all: build install

.PHONY: build install

build:
	cd libs/jsoncpp && ./amalgamate.py
	cd libs/Onigmo && ./autogen.sh && ./configure
	mkdir -p build
	cd build && cmake ../ && make
	cp build/textmate.so ./lua/nvim-textmate/

install:
	mkdir -p ~/.config/nvim/lua/
	cp -R ./lua/nvim-textmate ~/.config/nvim/lua/

uninstall:
	rm -rf ~/.config/nvim/lua/nvim-textmate

clean:
	rm -rf build

