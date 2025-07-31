@echo off
cls
setlocal enabledelayedexpansion

call :setESC

echo rtl simulation ...!ESC![90m

echo RTL simulation in Questa...!ESC![90m
  pushd "./scripts"
  bash run_tb_questa.sh
  popd

  if ERRORLEVEL 1 (
    echo !ESC![91mERROR Simulation not completed!ESC![0m
    exit /b
  ) else (
    echo !ESC![92mSimulation done!ESC![0m
  )

echo !ESC![92mTestbenches passed successfully!ESC![0m

:: Sets up the ESC string for use later in this script
:setESC
    for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
      set ESC=%%b
      exit /B 0
    )
    exit /B 0
