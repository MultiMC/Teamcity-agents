:: ---------------------------------------------------------------------
:: TeamCity build agent automatic uninstallation script
:: ---------------------------------------------------------------------
:: %1 path to Agent folder
:: ---------------------------------------------------------------------
@ECHO OFF

FOR /F "tokens=*" %%i in ("%1") DO SET AGENT_UNINSTALLATION_HOME=%%~i
IF "%AGENT_UNINSTALLATION_HOME%"=="" GOTO print_usage

SET LEFT_JRE=FALSE
IF /i "%2%" EQU "LEFT_JRE" (
  SET LEFT_JRE=TRUE
) 

SET ERRORLEVEL=

:: Check the folder exist
IF NOT EXIST "%AGENT_UNINSTALLATION_HOME%" (
  ECHO Could not find "%AGENT_UNINSTALLATION_HOME%". Skip the operation.
  SET ERRORLEVEL=
  GOTO end
)

PUSHD .
IF EXIST "%AGENT_UNINSTALLATION_HOME%\bin" (
  CD /d "%AGENT_UNINSTALLATION_HOME%\bin"
  ECHO Stopping the Agent...
  IF EXIST "%AGENT_UNINSTALLATION_HOME%\bin\agent.bat" (
    CALL agent.bat stop force
    ECHO Waiting the Agent is shutdown completely...
    :: timeout is implemented using ping because standard timeout utility does not work in non interactive mode
    ping 127.0.0.1 -n 15 >NUL
  ) ELSE (
    ECHO Could not find "%AGENT_UNINSTALLATION_HOME%\bin\agent.bat". Skip Agent shutdown
  )
  
  ECHO Uninstalling TeamCity Build Agent Service...
  IF EXIST "%AGENT_UNINSTALLATION_HOME%\bin\service.uninstall.bat" (
    CALL service.uninstall.bat
  ) ELSE (  
    ECHO Could not find "%AGENT_UNINSTALLATION_HOME%\bin\service.uninstall.bat". Skip the Service uninstalling
  )
  POPD
  GOTO remove_agent_files
)
ECHO Could not find "%AGENT_UNINSTALLATION_HOME%\bin". Skip the Agent shutdown and Windows Service uninstalling.

:remove_agent_files
ECHO Cleaning TeamCity Build Agent directory...
::do not touch 'JRE' if exists
IF EXIST "%AGENT_UNINSTALLATION_HOME%\jre" (
  IF "%LEFT_JRE%"=="TRUE" (
    SET ERRORLEVEL=
    ::Directories
    FOR /F "tokens=*" %%i in ('dir "%AGENT_UNINSTALLATION_HOME%" /X /B /a:d') DO (
      IF /i "%%i" NEQ "JRE" (
        RMDIR /S /Q "%AGENT_UNINSTALLATION_HOME%\%%i">NUL 2>&1
      )
    )
    ::Files
    FOR /F "tokens=*" %%i in ('dir "%AGENT_UNINSTALLATION_HOME%" /X /B /a:-d') DO (
      DEL "%AGENT_UNINSTALLATION_HOME%\%%i" /F /Q>NUL 2>&1
    )
  ) ELSE (
    SET ERRORLEVEL=
    RMDIR /S /Q "%AGENT_UNINSTALLATION_HOME%"  
  )
) ELSE (
  SET ERRORLEVEL=
  RMDIR /S /Q "%AGENT_UNINSTALLATION_HOME%"
)
::IF "%ERRORLEVEL%"=="0" GOTO end 
::ECHO Could not remove the Agent's folder[%ERRORLEVEL%].
GOTO end

:print_usage
  ECHO "Usage: uninstall.bat <path_to_agent_folder>"
  SET ERRORLEVEL=1
  
:end
SET ERRORLEVEL=0