:: ---------------------------------------------------------------------
:: TeamCity build agent automatic installation script
:: ---------------------------------------------------------------------
:: Usage: install.bat <TC_Server_URL> <path_to_install_into> (authorization_token|-1) [<Service_running_account> [<Account_password>]]
::
:: %1 required: TeamCity Server root URL
:: %2 required: Agent Install location 
:: %3 required: Authorization token. Must be "-1" if no auto registration required
:: %4 optional: Windows Service account
:: %5 optional: Account password
:: ---------------------------------------------------------------------
@ECHO OFF

:: Check second parameter and set target to folder if exists
SET SERVER_URL=%1%
SET AGENT_INSTALLATION_HOME=%2%

:: Remove superfluous quotations if exists
FOR /F "tokens=*" %%i in ("%AGENT_INSTALLATION_HOME%") do set AGENT_INSTALLATION_HOME=%%~i

ECHO Agent installation is executing on '%COMPUTERNAME%'...
ECHO Current directory: '%cd%'
systeminfo | find /I "System type"

SET TEAMCITY_JAVA_INSTALL_PATH=%AGENT_INSTALLATION_HOME%\jre
:: Check there is an installed JRE and break installation if not so
:checking_java
  ECHO Looking for installed JRE...
  set FJ_MIN_UNSUPPORTED_JAVA_VERSION=12
  CALL "%cd%\bin\findJava.bat" "1.6" "%TEAMCITY_JAVA_INSTALL_PATH%"
  IF NOT ERRORLEVEL 0 (
    ECHO Warning: No installed JRE found.
    goto download_jre
  )
  ECHO Installed JRE found.
  GOTO perform_install

:download_jre
  SET ERRORLEVEL=
  CALL "%cd%\bin\installJava.bat" "%SERVER_URL%/update" "%TEAMCITY_JAVA_INSTALL_PATH%"
  IF "%ERRORLEVEL%"=="0" GOTO checking_java 
  ECHO Could not install neither JDK nor JRE. Terminating[%ERRORLEVEL%] 
  SET ERRORLEVEL=1
  GOTO end

:perform_install
SET ERRORLEVEL=
::%TEAMCITY_LAUNCHER_OPTS_ACTUAL%
"%FJ_JAVA_EXEC%" -Xmx128m -jar lib\agent-configurator.jar install %*

:end
  EXIT /B %ERRORLEVEL%
 
