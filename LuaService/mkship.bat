@echo off
mkdir ship
del /Q ship\*.*
copy Readme.txt ship
copy Release\LuaService.exe ship
copy doc\html\LuaService.chm ship
copy Samples\Ticker\*.lua ship
zip ship%1.zip ship\*.*
