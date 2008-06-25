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


TODO
----
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

