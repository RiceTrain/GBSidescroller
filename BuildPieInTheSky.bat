@echo on
RGBDS\rgbasm -oProjectOutput\PieInTheSky\PieInTheSky.obj Projects\PieInTheSky\PieInTheSky.asm
if %errorlevel% neq 0 call :exit 1
RGBDS\rgblink -t -nProjectOutput\PieInTheSky\PieInTheSky.sym -mProjectOutput\PieInTheSky\PieInTheSky.map -oProjectOutput\PieInTheSky\PieInTheSky.gb ProjectOutput\PieInTheSky\PieInTheSky.obj
if %errorlevel% neq 0 call :exit 1
RGBDS\rgbfix -v ProjectOutput\PieInTheSky\PieInTheSky.gb
if %errorlevel% neq 0 call :exit 1
call :exit 0

:exit
pause
exit