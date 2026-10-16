@echo off
title Scramix Terminal
setlocal EnableExtensions EnableDelayedExpansion

set "baseDir=%~dp0"
set "textColor="
set "backgroundColor="
set "windowWidth="
set "windowHeight="
set "historyCount=0"

echo Type 'help' for a list of commands.
echo.

:main
set "cmd="
set /p "cmd=> " || exit /b
if not defined cmd goto main
set /a historyCount+=1
set "history!historyCount!=!cmd!"

if /i "!cmd!"=="help" (
    echo.
    echo Available commands:
    echo   help
    echo   clear
    echo   clear -cfg
    echo   restart
    echo   restart -force
    echo   execute terminalv2.ps1
    echo   config
    echo   history
    echo   history -clear
    echo   exit
    echo.
    goto main
)
if /i "!cmd!"=="clear" (cls & goto main)
if /i "!cmd!"=="clear -cfg" (
    set "textColor="
    set "backgroundColor="
    set "windowWidth="
    set "windowHeight="
    cls
    echo Terminal configuration cleared.
    echo.
    goto main
)
if /i "!cmd!"=="restart" goto restart
if /i "!cmd!"=="restart -force" goto restart
if /i "!cmd!"=="execute terminalv2.ps1" (
    if exist "%baseDir%v2\launcherps1.vbe" (
        wscript.exe "%baseDir%v2\launcherps1.vbe" "execute terminalv2.ps1"
    ) else if exist "%baseDir%launcherps1.vbe" (
        rem Compatibility with the current checkout, where the encoded launcher is at the root.
        wscript.exe "%baseDir%launcherps1.vbe" "execute terminalv2.ps1"
    ) else (
        echo ^> Launcher not found: v2\launcherps1.vbe
    )
    goto main
)
if /i "!cmd!"=="config" goto config
if /i "!cmd!"=="history" goto show_history
if /i "!cmd!"=="history -clear" (
    for /l %%N in (1,1,!historyCount!) do set "history%%N="
    set "historyCount=0"
    echo Command history cleared.
    goto main
)
if /i "!cmd!"=="exit" exit /b
echo ^> Unknown command. Type 'help' for a list of commands.
goto main

:restart
start "" "%~f0"
exit /b

:show_history
echo.
if "!historyCount!"=="0" (
    echo No command history.
) else (
    for /l %%N in (1,1,!historyCount!) do echo %%N^) !history%%N!
)
echo.
goto main

:config
cls
echo Terminal Configuration
echo ----------------------
echo.
echo 1^) Resize window
echo 2^) Change text color
echo 3^) Change background color
echo 4^) Exit
echo.
set "configChoice="
set /p "configChoice=> " || exit /b
if "!configChoice!"=="1" goto config_resize
if "!configChoice!"=="2" goto config_textcolor
if "!configChoice!"=="3" goto config_background
if "!configChoice!"=="4" goto main
echo.
echo ^> Invalid option.
pause
goto config

:config_resize
cls
echo How do you want to resize the window?
echo Type an aspect ratio or columns x lines.
echo Spaces are not supported.
echo.
echo Examples:
echo   16:9
echo   100x30
echo.
set "sizeInput="
set /p "sizeInput=> " || exit /b

for /f "tokens=1,2 delims=xX" %%A in ("!sizeInput!") do if not "%%B"=="" (
    set "windowWidth=%%A"
    set "windowHeight=%%B"
    call :validateDimensions "!windowWidth!" "!windowHeight!"
    if errorlevel 1 goto invalid_size
    goto resize_apply
)
for /f "tokens=1,2 delims=:" %%A in ("!sizeInput!") do if not "%%B"=="" (
    set "ratioWidth=%%A"
    set "ratioHeight=%%B"
    call :calculate_ratio
    if errorlevel 1 goto invalid_size
    goto resize_apply
)

:invalid_size
echo.
echo ^> Invalid window size or unavailable screen information.
pause
goto config_resize

:resize_apply
call :applyConfig
echo.
echo Window size changed to !windowWidth!x!windowHeight!.
pause
goto config

:config_textcolor
cls
echo Enter the text color:
echo.
set "newTextColor="
set /p "newTextColor=> " || exit /b
call :validateColor "!newTextColor!"
if errorlevel 1 (
    echo.
    echo ^> Invalid color.
    pause
    goto config_textcolor
)
if /i "!newTextColor!"=="!backgroundColor!" if defined backgroundColor (
    echo.
    echo ^> Text color cannot match the background color.
    pause
    goto config_textcolor
)
set "textColor=!newTextColor!"
call :applyColor
echo.
echo Text color changed to !textColor!.
pause
goto config

:config_background
cls
echo Enter the background color:
echo.
set "newBackgroundColor="
set /p "newBackgroundColor=> " || exit /b
call :validateColor "!newBackgroundColor!"
if errorlevel 1 (
    echo.
    echo ^> Invalid color.
    pause
    goto config_background
)
if /i "!newBackgroundColor!"=="!textColor!" if defined textColor (
    echo.
    echo ^> Background color cannot match the text color.
    pause
    goto config_background
)
set "backgroundColor=!newBackgroundColor!"
call :applyColor
echo.
echo Background color changed to !backgroundColor!.
pause
goto config

:calculate_ratio
call :validateDimensions "!ratioWidth!" "!ratioHeight!"
if errorlevel 1 exit /b 1
if not exist "%baseDir%scrn.exe" exit /b 1
set "screenWidth="
set "screenHeight="
set "cellWidth="
set "cellHeight="
for /f "tokens=1,2 delims=:" %%A in ('"%baseDir%scrn.exe"') do (
    if /i "%%A"=="Reported screen size" (
        for /f "tokens=1,2 delims=x" %%C in ("%%B") do (
            set "screenWidth=%%C"
            set "screenHeight=%%D"
        )
    )
    if /i "%%A"=="Console cell size" (
        for /f "tokens=1,2 delims=x" %%C in ("%%B") do (
            set "cellWidth=%%C"
            set "cellHeight=%%D"
        )
    )
)
call :validateDimensions "!screenWidth!" "!screenHeight!"
if errorlevel 1 exit /b 1
call :validateDimensions "!cellWidth!" "!cellHeight!"
if errorlevel 1 exit /b 1
set /a "maxLines=screenHeight/cellHeight"
set /a "maxColumns=screenWidth/cellWidth"
if !maxLines! LEQ 0 exit /b 1
if !maxColumns! LEQ 0 exit /b 1
set "bestArea=0"
set "bestErrorNumerator=0"
set "bestErrorDenominator=1"
for /l %%L in (1,1,!maxLines!) do (
    set /a "candidateColumns=(%%L*ratioWidth*cellHeight+(ratioHeight*cellWidth/2))/(ratioHeight*cellWidth)"
    if !candidateColumns! GTR 0 if !candidateColumns! LEQ !maxColumns! (
        set /a "errorValue=candidateColumns*cellWidth*ratioHeight-%%L*cellHeight*ratioWidth"
        if !errorValue! LSS 0 set /a "errorValue=0-errorValue"
        set /a "errorDenominator=%%L*cellHeight*ratioWidth"
        set /a "candidateArea=candidateColumns*%%L"
        if "!bestArea!"=="0" (
            set "bestArea=!candidateArea!"
            set "bestErrorNumerator=!errorValue!"
            set "bestErrorDenominator=!errorDenominator!"
            set "windowWidth=!candidateColumns!"
            set "windowHeight=%%L"
        ) else (
            set /a "candidateErrorScaled=errorValue*bestErrorDenominator"
            set /a "bestErrorScaled=bestErrorNumerator*errorDenominator"
            if !candidateErrorScaled! LSS !bestErrorScaled! (
                set "bestArea=!candidateArea!"
                set "bestErrorNumerator=!errorValue!"
                set "bestErrorDenominator=!errorDenominator!"
                set "windowWidth=!candidateColumns!"
                set "windowHeight=%%L"
            ) else if !candidateErrorScaled! EQU !bestErrorScaled! if !candidateArea! GTR !bestArea! (
                set "bestArea=!candidateArea!"
                set "bestErrorNumerator=!errorValue!"
                set "bestErrorDenominator=!errorDenominator!"
                set "windowWidth=!candidateColumns!"
                set "windowHeight=%%L"
            )
        )
    )
)
if "!bestArea!"=="0" exit /b 1
exit /b 0

:validateDimensions
set "dimA=%~1"
set "dimB=%~2"
if not defined dimA exit /b 1
if not defined dimB exit /b 1
for /f "delims=0123456789" %%A in ("!dimA!!dimB!") do exit /b 1
if !dimA! LEQ 0 exit /b 1
if !dimB! LEQ 0 exit /b 1
exit /b 0

:applyConfig
if defined windowWidth if defined windowHeight mode con: cols=!windowWidth! lines=!windowHeight! >nul 2>&1
call :applyColor
exit /b

:applyColor
if not defined textColor exit /b
if not defined backgroundColor exit /b
call :colorCode "!textColor!"
set "textCode=!colorResult!"
call :colorCode "!backgroundColor!"
set "backgroundCode=!colorResult!"
color !backgroundCode!!textCode!
exit /b

:validateColor
set "colorInput=%~1"
for %%C in (black blue green cyan red magenta yellow white gray lightblue lightgreen lightcyan lightred lightmagenta lightyellow brightwhite) do if /i "!colorInput!"=="%%C" exit /b 0
exit /b 1

:colorCode
set "colorResult="
if /i "%~1"=="black" set "colorResult=0"
if /i "%~1"=="blue" set "colorResult=1"
if /i "%~1"=="green" set "colorResult=2"
if /i "%~1"=="cyan" set "colorResult=3"
if /i "%~1"=="red" set "colorResult=4"
if /i "%~1"=="magenta" set "colorResult=5"
if /i "%~1"=="yellow" set "colorResult=6"
if /i "%~1"=="white" set "colorResult=7"
if /i "%~1"=="gray" set "colorResult=8"
if /i "%~1"=="lightblue" set "colorResult=9"
if /i "%~1"=="lightgreen" set "colorResult=A"
if /i "%~1"=="lightcyan" set "colorResult=B"
if /i "%~1"=="lightred" set "colorResult=C"
if /i "%~1"=="lightmagenta" set "colorResult=D"
if /i "%~1"=="lightyellow" set "colorResult=E"
if /i "%~1"=="brightwhite" set "colorResult=F"
exit /b
