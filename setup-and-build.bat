@echo off
REM X10SRL OpenBMC WSL2 Setup and Build Script
REM Run this script in Windows Command Prompt or PowerShell

echo ========================================
echo X10SRL OpenBMC WSL2 Setup and Build
echo ========================================
echo.

REM Check if WSL is installed
wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [1/5] Installing WSL2...
    echo This requires administrator privileges.
    wsl --install -d Ubuntu-22.04
    echo.
    echo WSL2 installation started. Please:
    echo 1. Wait for installation to complete
    echo 2. Restart your computer if prompted
    echo 3. Set up Ubuntu username and password
    echo 4. Run this script again after setup
    pause
    exit /b
)

echo [1/5] WSL2 is installed
echo.

REM Check if Ubuntu is installed
wsl -d Ubuntu-22.04 -- echo "Ubuntu ready" >nul 2>&1
if %errorlevel% neq 0 (
    echo Installing Ubuntu 22.04...
    wsl --install -d Ubuntu-22.04
    echo Please complete Ubuntu setup and run this script again.
    pause
    exit /b
)

echo [2/5] Ubuntu 22.04 is ready
echo.

echo [3/5] Installing build dependencies in WSL2...
wsl -d Ubuntu-22.04 -- bash -c "sudo apt update && sudo apt install -y git build-essential python3 python3-distutils gawk wget diffstat unzip texinfo chrpath socat cpio python3-pip python3-pexpect xz-utils debianutils iputils-ping libsdl1.2-dev xterm liblz4-tool zstd liblz4-dev libssl-dev gcc-multilib g++-multilib"

echo.
echo [4/5] Copying OpenBMC source to WSL2...
wsl -d Ubuntu-22.04 -- bash -c "mkdir -p ~/openbmc-build && cp -r /mnt/c/Users/%USERNAME%/Downloads/openbmc ~/openbmc-build/ 2>/dev/null || echo 'Source already exists'"

echo.
echo [5/5] Starting OpenBMC build...
echo This will take 2-4 hours for the first build.
echo.

wsl -d Ubuntu-22.04 -- bash -c "cd ~/openbmc-build/openbmc && . setup x10srl && bitbake obmc-phosphor-image"

echo.
echo ========================================
echo Build complete!
echo ========================================
echo.
echo Images are located in WSL2 at:
echo ~/openbmc-build/openbmc/build/tmp/deploy/images/x10srl/
echo.
echo To copy to Windows:
wsl -d Ubuntu-22.04 -- bash -c "cp ~/openbmc-build/openbmc/build/tmp/deploy/images/x10srl/*.mtd /mnt/c/Users/%USERNAME%/Downloads/ 2>/dev/null"
echo Copied to: C:\Users\%USERNAME%\Downloads\
echo.
pause
