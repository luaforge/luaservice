Readme.txt
==========
Ross Berteig <ross@cheshireeng.com>
v0.02, July 2008

This is the file readme.txt describing the win32ser module for
use from Lua scripts.

This module is a low-level wrapping of the Windows Communications Port
API. The goal is to provide access to communications resources from
scripting environments. The only targeted environment is Lua, but
since SWIG is used to construct the wrapper, support for other
scripting languages is possible with only moderate effort.

The wrapper can be easily built for Lua version 5.1 and later. It is
probably usable with Lua 5.0 if a suitable adapter is provided to
simulate the modern module system. At runtime it depends only on
lua5.1.dll, either msvcr80.dll or msvcrt.dll, and various Windows
system components.


TODO
----
The following is a sketchy list of things to do presented in rough
priority order:

* Finish Documentation
* More luaunit cases to cover edges.
* More useful constants and/or bitfield to/from sets mechanism
* Test under IUP
* Alpha release at LuaForge
* Test under some lua thread support kit?
* Test under LuaWindowsService?
* Demo application... port HexTerm?
* Package for LforW... anything special to do?
* Add support for overlapped read/write and waiting for completion
* Support Send/Expect funcitonality with a lua module?


Build Dependencies
------------------
The following is a sketchy list of tools I used to build this
project from source. There may well be other ways to approach building
it, this is merely what I did and what the Makefile assumes is
available. Also, most of the tool versions are not at the bleeding
edge. This is partly because Cygwin doesn't seem to pick up revisions
swiftly, but in the case of FOP, it is due to asciidoc being
incompatible with the modern versions of FOP.

* Cygwin
  - GCC Version 3.4.4
  - SWIG Version 1.3.29
  - Gnu make
  - asciidoc
  - DocBook
  - zip
* Apache FOP Version 0.20.5
* Sun Java Runtime Version JRE1.6
* GNU source-highlight 2.1.2 packaged by GnuWin32
* Lua Scripting for Windows
  - lua 5.1.3
  - luaunit

References
----------
* http://msdn.microsoft.com/
* http://www.cygwin.com/
* http://www.lua.org/
* http://www.swig.org/
