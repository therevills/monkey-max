@echo off
set OLDDIR=%CD%

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

echo Backing up old build executable (if its there)...
@echo off
ren "%OLDDIR%\cpptool\transcc.build\cpptool\main_winnt.exe" "main_winnt.exe.bak_%yy%_%mo%_%dd%_%hh%_%mm%_%ss%"

echo Building new transcc (using old transcc, chicken and egg!)...
@echo off
%OLDDIR%\..\bin\transcc_winnt.exe -build -config=release -target=C++_Tool %OLDDIR%\transcc\transcc.monkey

@echo off
if errorlevel 1 goto FAIL
if errorlevel 0 goto CONTINUE
goto END
:CONTINUE

echo Backing up old transcc in bin folder (the official one)...
@echo off
ren "%OLDDIR%\..\bin\transcc_winnt.exe" "transcc_winnt.exe.bak_%yy%_%mo%_%dd%_%hh%_%mm%_%ss%"

echo Copying new transcc to bin folder (the monkeymax one)...
@echo off
COPY "%OLDDIR%\transcc\transcc.build\cpptool\main_winnt.exe" "%OLDDIR%\..\bin\transcc_winnt.exe"

echo DONE!
goto END
:FAIL
echo: Error!
goto END
:END
pause