all: dirs dlls

clean:
	-rm *.o
	-rm sermod_wrap*.c
	-rm -rf serial_msvcrt
	-rm -rf serial_msvcr80
	-rm *.fo *.xml

shiny:	clean
	-rm ~*.bak
	-rm readme.pdf

.PHONY: all clean ship dirs dlls docs

# locate tecgraf resources in the windows folder
# %SYSTEMDRIVE%\programs\tecgraf We assume something resembling the
# LuaBinaries folder tree is in ...\tecgraf\lua5.1
TECGRAF=`cygpath $(SYSTEMDRIVE)`/programs/tecgraf
LUABASE=$(TECGRAF)/lua5.1
LUAINC=$(LUABASE)/include
LUADLL=$(LUABASE)/lib/dll/lua5.1.dll

sermod_wrap_lua.c: sermod.i msgbox.i
	swig -lua -o $@ sermod.i

sermod_wrap_lua.o: sermod_wrap_lua.c
	gcc -c -mno-cygwin -I$(LUAINC) sermod_wrap_lua.c

win32ser.dll: sermod_wrap_lua.o Makefile
	gcc -o $@ -shared -mno-cygwin -I$(LUAINC) sermod_wrap_lua.o $(LUADLL)  -lmsvcr80

tests: dlls
	LUA_CPATH="./serial_msvcr80/?.dll;$(LUA_CPATH)" lua t/runall.lua

dirs: serial_msvcrt serial_msvcr80
dlls: dirs serial_msvcrt/win32ser.dll serial_msvcr80/win32ser.dll

serial_msvcrt:
	[ ! -e  serial_msvcrt ] && mkdir serial_msvcrt

serial_msvcr80:
	[ ! -e  serial_msvcr80 ] && mkdir serial_msvcr80

serial_msvcrt/win32ser.dll: sermod_wrap_lua.o Makefile
	gcc -o $@ -shared -mno-cygwin -I$(LUAINC) sermod_wrap_lua.o $(LUADLL) -lmsvcrt

serial_msvcr80/win32ser.dll: sermod_wrap_lua.o Makefile
	gcc -o $@ -shared -mno-cygwin -I$(LUAINC) sermod_wrap_lua.o $(LUADLL) -lmsvcr80


ship: shipsrc shipbin

shipsrc:
	zip -8 serial-src readme.txt sermod.i msgbox.i Makefile t/*.lua samples/*.lua -x '*.bak'

shipbin: all docs
	zip -8 -j serial-win32-vc8 readme.txt doc/reference.pdf serial_msvcr80/ser.dll
	zip -8 -j serial-win32-vc6 readme.txt doc/reference.pdf serial_msvcrt/ser.dll

docs: readme.pdf doc/reference.pdf

readme.pdf: readme.txt
	a2x -f pdf --xsltproc-opts='--stringparam paper.type USletter' readme.txt

doc/reference.pdf: doc/reference.txt
	cd doc && a2x -f pdf --asciidoc-opts=--unsafe --xsltproc-opts='--stringparam paper.type USletter' reference.txt


inst-lfw: all
	strip -p serial_msvcr80/win32ser.dll -o /cygdrive/e/progra~1/Lua/5.1/clibs/win32ser.dll
