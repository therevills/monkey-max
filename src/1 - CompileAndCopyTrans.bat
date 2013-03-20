set OLDDIR=%CD%

%OLDDIR%\..\bin\transcc_winnt.exe -build -config=release -target=C++_Tool %OLDDIR%\transcc\transcc.monkey
@echo off
if errorlevel 1 goto FAIL
if errorlevel 0 goto CONTINUE
goto END
:CONTINUE

for /f "tokens=1-4 delims=/ " %%a in ('date /t') do (
 set dd=%%b
 set mo=%%c
 set yy=%%d
)

for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
 set hh=%%a
 set mm=%%b
 set ss=%%c
)

echo.
echo Backing up old transcc_winnt.exe (if its there) to transcc_winnt.exe.bak_%yy%_%mo%_%dd%_%hh%_%mm%_%ss%
ren "%OLDDIR%\transcc\transcc.build\cpptool\transcc_winnt.exe" "transcc_winnt.exe.bak_%yy%_%mo%_%dd%_%hh%_%mm%_%ss%"
echo.
echo Renaming main_winnt.exe to transcc_winnt.exe
ren "%OLDDIR%\transcc\transcc.build\cpptool\main_winnt.exe" "transcc_winnt.exe"
echo.
echo Copying to the bin folder...
ren "%OLDDIR%\..\bin\transcc_winnt.exe" "transcc_winnt.exe.bak_%yy%_%mo%_%dd%_%hh%_%mm%_%ss%"
COPY "%OLDDIR%\transcc\transcc.build\cpptool\transcc_winnt.exe" "%OLDDIR%\..\bin\"
echo.
echo.
echo DONE!
goto END
:FAIL
echo: Error!
goto END
:END
pause