Windows COMM API wrapper
========================
:Author:	Ross Berteig
:Email:		ross@cheshireeng.com
:Revision:	v0.01
:Date:		June, 2008

Introduction 
------------ 
This is a low-level wrapping of the Windows (specifically Win32)
Communications Port API. The goal is to provide access to
communications resources from scripting environments. The only
targeted environment is Lua (http://www.lua.org/[]), but since SWIG
(http://www.swig.org/[]) is used to construct the wrapper, support for
other scripting languages is possible with only moderate effort.

The wrapper can be easily built for Lua version 5.1 and later. It is
probably usable with Lua 5.0 if a suitable adapter is provided to
simulate the modern module system. At runtime it depends only on
lua5.1.dll, either msvcr80.dll or msvcrt.dll, and various Windows
system components.


TODO
----
The following is a sketchy list of things to do presented in no
particular order:

* Test cases for the remaining simple wrappers.
* Finish Documentation
* Lua module to clean up interface and make it more OO?
* Or just make it more OO directly?
* Alpha release at LuaForge
* Add support for overlapped read/write
* Test under some lua thread support kit?
* Test under LuaWindowsService?
* Test under IUP
* Send/Expect support?
* Package for LforW
* Demo application... port HexTerm?


Build Dependancies
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
