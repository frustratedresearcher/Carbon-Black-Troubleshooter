@echo off
setlocal enabledelayedexpansion

echo ####################################
echo Carbon Black Troubleshooter
echo Author: Ravi Rajput (Frustrated Researcher)
echo ####################################
echo.

REM Check if the script is running with administrative rights
>nul 2>&1 "%SystemRoot%\system32\cacls.exe" "%SystemRoot%\system32\config\system" || (
    echo Script is not running with administrative rights.
    echo Please run the script as an administrator.
    pause
    exit
)

REM Check if the file exists
if not exist cb_urls.txt (
    echo File cb_urls.txt not found!
    exit /b 1
)

REM Initialize the log file
echo Carbon Black Troubleshooter Log > trouble_log.txt
echo Timestamp: %date% %time% >> trouble_log.txt
echo ==================================== >> trouble_log.txt

echo Hardware Config for Windows
REM Log system proxy settings
:: Check CPU Speed
for /f "tokens=2 delims==" %%i in ('wmic cpu get CurrentClockSpeed /value') do (
    set GHZ=%%i
    set /A GHZ=!GHZ!/1000
)
if %GHZ% geq 1.8 (
    echo CPU Speed is sufficient: %GHZ% GHz
) else (
    echo CPU Speed is below the required: %GHZ% GHz
)

:: Check Number of Cores
for /f "tokens=2 delims==" %%i in ('wmic cpu get NumberOfCores /value') do (
    set CORES=%%i
)
if %CORES% gtr 2 (
    echo CPU has more than 2 cores: %CORES% cores
) else (
    echo CPU does not have more than 2 cores: %CORES% cores
)

:: Check Available Memory
for /f "tokens=2 delims==" %%i in ('wmic OS get FreePhysicalMemory /value') do (
    set MEMORY=%%i
    set /A MEMORY=!MEMORY!/1048576
)
if %MEMORY% geq 1 (
    echo Free Memory is sufficient: %MEMORY% GB
) else (
    echo Free Memory is below the required: %MEMORY% GB
)

:: Use PowerShell to get Free Disk Space on Windows Installation Drive
for /f %%i in ('powershell -command "[math]::Round((Get-Volume %SystemDrive%).SizeRemaining / 1GB)"') do (
    set FREESPACE_GB=%%i
)

if %FREESPACE_GB% geq 1 (
    echo Free space on Windows installation disk is sufficient: %FREESPACE_GB% GB
) else (
    echo Free space on Windows installation disk is below the required: %FREESPACE_GB% GB
)

echo ==================================== >> trouble_log.txt
REM Log system proxy settings
echo System Proxy Settings >> trouble_log.txt
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable >> trouble_log.txt
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer >> trouble_log.txt
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride >> trouble_log.txt
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v AutoConfigURL >> trouble_log.txt
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v MigrateProxy >> trouble_log.txt
reg query "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyHttp1.1 >> trouble_log.txt
echo ==================================== >> trouble_log.txt

echo Listening ports for CB
REM Port Listening Check
set PORT1=443
set PORT2=5443

:: Check and display processes for Port 443
netstat -aon | findstr /R /C:"^  TCP .*:%PORT1% .*LISTENING" >nul
if !ERRORLEVEL! equ 0 (
    echo Processes listening on port %PORT1%: >> trouble_log.txt
    for /f "tokens=5" %%i in ('netstat -aon ^| findstr /R /C:"^  TCP .*:%PORT1% .*LISTENING"') do (
        tasklist | findstr "%%i" >> trouble_log.txt
    )
    echo. >> trouble_log.txt
) else (
    echo Port %PORT1% is NOT listening. >> trouble_log.txt
    echo. >> trouble_log.txt
)

:: Check and display processes for Port 5443
netstat -aon | findstr /R /C:"^  TCP .*:%PORT2% .*LISTENING" >nul
if !ERRORLEVEL! equ 0 (
    echo Processes listening on port %PORT2%: >> trouble_log.txt
    for /f "tokens=5" %%i in ('netstat -aon ^| findstr /R /C:"^  TCP .*:%PORT2% .*LISTENING"') do (
        tasklist | findstr "%%i" >> trouble_log.txt
    )
    echo. >> trouble_log.txt
) else (
    echo Port %PORT2% is NOT listening. >> trouble_log.txt
    echo. >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt
REM Loop through each URL and check connectivity
for /f "delims=" %%a in (cb_urls.txt) do (
    set url=%%a
    REM Attempt to fetch the URL using powershell
    powershell -command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $result = Invoke-WebRequest -Uri !url! -Method Head -UseBasicParsing -TimeoutSec 5; if ($result.StatusCode -eq 200 -or $result.StatusCode -eq 403 -or $result.StatusCode -eq 404) { 'Connected successfully to !url!' } else { 'Failed to connect to !url! with status code: ' + $result.StatusCode } } catch { 'Failed to connect to !url! due to error: ' + $_.Exception.Message }" >> trouble_log.txt 2>&1
)

echo ==================================== >> trouble_log.txt

echo Copy Proxy Configuration files to current directory if they exist >> trouble_log.txt
REM Copy Proxy Configuration files to current directory if they exist
set "FILE1=%ProgramFiles%\Confer\cfg.ini"
set "FILE2=%ProgramData%\CarbonBlack\DataFiles\cfg.ini"

if exist "%FILE1%" (
    copy "%FILE1%" ".\cfg.ini" >nul
    if !ERRORLEVEL! equ 0 (
        echo Copied "%FILE1%" to current directory. >> trouble_log.txt
    ) else (
        echo Failed to copy "%FILE1%". >> trouble_log.txt
    )
) else (
    echo "%FILE1%" not found. >> trouble_log.txt
)

if exist "%FILE2%" (
    copy "%FILE2%" ".\cfg_from_datafiles.ini" >nul
    if !ERRORLEVEL! equ 0 (
        echo Copied "%FILE2%" to current directory as cfg_from_datafiles.ini. >> trouble_log.txt
    ) else (
        echo Failed to copy "%FILE2%". >> trouble_log.txt
    )
) else (
    echo "%FILE2%" not found. >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt

echo Logging All Environment variable especially CURL SSL

REM Log all environment variables
echo Logging all environment variables... >> trouble_log.txt
set >> trouble_log.txt

REM Retrieve the value of the CURL_SSL_OPTIONS environment variable
set CURL_CHECK=
for /f "tokens=2 delims==" %%a in ('set CURL_SSL_OPTIONS 2^>nul') do (
    set CURL_CHECK=%%a
)

REM Check if CURL_SSL_OPTIONS is set to disable CRL check
if "%CURL_CHECK%"=="no-check-certificate" (
    echo CURL CRL check is disabled on this machine. >> trouble_log.txt
) else (
    echo CURL CRL check is NOT disabled on this machine. >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt

echo Execute repcli.exe status and append the output to the log
REM Execute repcli.exe and append the output to the log
if exist "%ProgramFiles%\Confer\repcli.exe" (
    echo ==================================== >> trouble_log.txt
    echo Output from %ProgramFiles%\Confer\repcli.exe status: >> trouble_log.txt
    "%ProgramFiles%\Confer\repcli.exe" status >> trouble_log.txt 2>&1
    echo ==================================== >> trouble_log.txt
) else (
    echo ==================================== >> trouble_log.txt
    echo %ProgramFiles%\Confer\repcli.exe not found. >> trouble_log.txt
    echo ==================================== >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt

echo Checking if CB Sensor required services are running
REM Check if specified executables are running
set "allProcessesRunning=true"
set "processList=RepMgr64.exe RepMgr32.exe Scanhost.exe RepUtils32.exe RepWmiUtils32.exe RepUx.exe"

for %%p in (%processList%) do (
    tasklist /FI "IMAGENAME eq %%p" | find /I "%%p" >nul
    if !ERRORLEVEL! neq 0 (
        echo %%p is NOT running. >> trouble_log.txt
        set "allProcessesRunning=false"
    )
)

if "%allProcessesRunning%"=="true" (
    echo All processes are running successfully. >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt

echo Checking for Certificate installation issue

REM Check if Go Daddy signing certificates are present in the local machine certificate store
set "certFound=false"

for /f "delims=" %%a in ('certutil -store My ^| findstr /I "Go Daddy"') do (
    echo %%a >> trouble_log.txt
    set "certFound=true"
)

if "%certFound%"=="false" (
    echo No Go Daddy signing certificates found in the local machine certificate store. >> trouble_log.txt
) else (
    echo Go Daddy signing certificates found in the local machine certificate store. >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt

:: Create the 'confer_logs' directory
if not exist ".\confer_logs" (
    mkdir ".\confer_logs"
)

:: Use PowerShell to copy files. Stop copying once the logs are found in a directory.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$foundLogs = $false; $dirs = @('"%ProgramFiles%\Confer\Logs"', '"%ProgramData%\CarbonBlack\Logs"', '"%LocalAppData%\Temp"', '"%SystemRoot%\Temp"'); foreach ($dir in $dirs) { if (-not $foundLogs -and (Test-Path $dir)) { robocopy $dir '.\confer_logs' /S /NJH /NJS /NDL /NS /NC /NP; if ($LASTEXITCODE -eq 1) { $foundLogs = $true; } } }"


echo ==================================== >> trouble_log.txt

echo Executing repcli capture which will take nearly sixty minutes
echo Executing repcli capture >> trouble_log.txt
REM 1. Make a directory in C:\
if not exist "C:\temp" (
    mkdir "C:\temp"
)

REM 2. Run the repcli.exe capture command
echo Running repcli.exe capture command...
"%ProgramFiles%\Confer\repcli.exe" capture "C:\temp"

REM 3. Wait for the command to finish. The batch script inherently waits for a command to complete before proceeding.

REM 4. Copy the psc_sensor.zip file from C:\temp to the current script directory
if exist "C:\temp\psc_sensor.zip" (
    echo Copying psc_sensor.zip to current directory...
    copy "C:\temp\psc_sensor.zip" ".\" >nul 2>&1
    if !ERRORLEVEL! neq 0 (
        echo Error copying psc_sensor.zip from C:\temp to current directory. >> trouble_log.txt
    )
) else (
    echo psc_sensor.zip not found in C:\temp. >> trouble_log.txt
)

echo ==================================== >> trouble_log.txt

echo Copy Proxy Configuration files to current directory if they exist >> trouble_log.txt

REM Copy Proxy Configuration files to current directory if they exist
set "FILE1=%ProgramFiles%\Confer\cfg.ini"
set "FILE2=%ProgramData%\CarbonBlack\DataFiles\cfg.ini"
set "filesToCompress="

REM Check if trouble_log.txt exists before attempting to copy
if exist trouble_log.txt (
    copy trouble_log.txt troubleshoot_log.txt
    set "filesToCompress=.\troubleshoot_log.txt"
)

REM Check and copy FILE1
if exist "%FILE1%" (
    copy "%FILE1%" ".\cfg.ini" >nul
    if !ERRORLEVEL! equ 0 (
        echo Copied "%FILE1%" to current directory. >> trouble_log.txt
        set "filesToCompress=!filesToCompress!,.\cfg.ini"
    ) else (
        echo Failed to copy "%FILE1%". >> trouble_log.txt
    )
) else (
    echo "%FILE1%" not found. >> trouble_log.txt
)

REM Check and copy FILE2
if exist "%FILE2%" (
    copy "%FILE2%" ".\cfg_from_datafiles.ini" >nul
    if !ERRORLEVEL! equ 0 (
        echo Copied "%FILE2%" to current directory as cfg_from_datafiles.ini. >> trouble_log.txt
        set "filesToCompress=!filesToCompress!,.\cfg_from_datafiles.ini"
    ) else (
        echo Failed to copy "%FILE2%". >> trouble_log.txt
    )
) else (
    echo "%FILE2%" not found. >> trouble_log.txt
)

REM Add confer_logs and psc_sensor.zip to filesToCompress if they exist
if exist ".\confer_logs\" set "filesToCompress=!filesToCompress!,.\confer_logs"
if exist ".\psc_sensor.zip" set "filesToCompress=!filesToCompress!,.\psc_sensor.zip"

REM Compress the files if there are any files to compress
if not "!filesToCompress!"=="" (
    echo Compressing the files into output.zip... >> trouble_log.txt
    powershell -Command "Try { Compress-Archive -Path !filesToCompress! -DestinationPath .\output.zip; } Catch { Write-Output $_.Exception.Message; exit 1 }"
    if !ERRORLEVEL! equ 1 (
        echo Error occurred during the zipping process. >> trouble_log.txt
    )
)

REM Cleanup: Remove the temporary troubleshoot_log.txt if it exists
if exist troubleshoot_log.txt (
    del troubleshoot_log.txt
)

echo ==================================== >> trouble_log.txt

echo Troubleshooting Complete!
echo Troubleshooting Complete! >> trouble_log.txt
endlocal
