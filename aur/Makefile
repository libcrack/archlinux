MP= makepkg
FLAGS= --clean 
USER= borja
CF:=../burp.cookie
PKG=$(shell grep pkgname= PKGBUILD | cut -f2 -d=)

all:	build clean

build:
	$(MP) $(FLAGS)

source:
	$(MP) $(FLAGS) --source

install: build
	$(MP) $(FLAGS) --install

upload: source
	echo burp -k --cookies $(CF) --user $(USER) $(shell ls $$PKG*.tar.gz)

clean:
	rm -rf pkg src $(PKG)
cleandist:
	rm -rf *.tar.xz *.tar.gz

mrclean: clean cleandist
