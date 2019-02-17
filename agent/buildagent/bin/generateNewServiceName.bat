@echo off
:: ---------------------------------------------------------------------
:: The script looking into Windows Registry for non-existent Service Name starting from <DEFAULT_SERVICE_NAME>
:: Set NEW_SERVICE_NAME environment variable with found one.
::
:: %1 Default service name
:: ---------------------------------------------------------------------

IF "%1"=="" (
  echo "Usage: generateNewServiceName.bat <DEFAULT_SERVICE_NAME>"
  exit /b 1
)

SET DEFAULT_SERVICE_NAME=%1
SET NEW_SERVICE_NAME=

:: Check deafult
SC QUERY %DEFAULT_SERVICE_NAME%|find "STATE" >NUL 2>&1 
IF ERRORLEVEL 1 (
  set NEW_SERVICE_NAME=%DEFAULT_SERVICE_NAME%
  ECHO %DEFAULT_SERVICE_NAME%
  GOTO found
)

:: Scan for an empty slot
FOR /L %%A IN (1,1,100) DO (
  SC QUERY %DEFAULT_SERVICE_NAME%-%%A|find "STATE" >NUL 2>&1 
  IF ERRORLEVEL 1 (
    SET NEW_SERVICE_NAME=%DEFAULT_SERVICE_NAME%-%%A
    ECHO %DEFAULT_SERVICE_NAME%-%%A
    GOTO found
  )
)
::No empty Service name found
exit /b 2

:found
exit /b 0


