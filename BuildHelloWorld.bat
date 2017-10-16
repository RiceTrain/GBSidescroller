@echo off
RGBDS\rgbasm -oProjectOutput\HelloWorld\HelloWorld.obj Projects\HelloWorld.asm
if %errorlevel% neq 0 call :exit 1
RGBDS\rgblink -mProjectOutput\HelloWorld\HelloWorld.map -nProjectOutput\HelloWorld\HelloWorld.sym -oProjectOutput\HelloWorld\HelloWorld.gb ProjectOutput\HelloWorld\HelloWorld.obj
if %errorlevel% neq 0 call :exit 1
RGBDS\rgbfix -p0 -v ProjectOutput\HelloWorld\HelloWorld.gb
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
pause
exit