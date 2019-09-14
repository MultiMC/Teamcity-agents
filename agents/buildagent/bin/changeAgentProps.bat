:: ---------------------------------------------------------------------
:: TeamCity build agent configuration script
:: ---------------------------------------------------------------------
:: Usage: changeAgentProps.bat <parameter_name> <new_parameter_value> <properties_file> 
:: %1 parameter name
:: %2 new parameter value
:: %3 properties file
:: ---------------------------------------------------------------------

FOR /F "tokens=*" %%i in ("%1") DO SET PARAMETER_NAME=%%~i
FOR /F "tokens=*" %%i in ("%2") DO SET PARAMETER_VALUE=%%~i
FOR /F "tokens=*" %%i in ("%3") DO SET AGENT_PROPERTIES_FILE=%%~i

IF "%AGENT_PROPERTIES_FILE%"=="" GOTO print_usage

ECHO Setting '%PARAMETER_NAME%' with '%PARAMETER_VALUE%' in '%AGENT_PROPERTIES_FILE%'...
:: Use existing as template if so
IF EXIST "%AGENT_PROPERTIES_FILE%" SET TEMPLATE_PROPERTIES_FILE=%AGENT_PROPERTIES_FILE%
:: Check template exists
IF NOT EXIST "%TEMPLATE_PROPERTIES_FILE%" (
  ECHO Could not find Agent's property file '%TEMPLATE_PROPERTIES_FILE%'. Terminating[2] 
  SET ERRORLEVEL=2
  GOTO end  
)
:: Use temporary file for replacing  
SET TMP_PROPERTIES_FILE=%AGENT_PROPERTIES_FILE%.tmp
:: Replace...    
SET PARAMETER_FOUND="NO"  
FOR /F "tokens=*" %%i IN ('type "%TEMPLATE_PROPERTIES_FILE%"') DO (
  FOR /F "tokens=1 delims==" %%j IN ("%%i") DO (
    if "%%j"=="%PARAMETER_NAME%" (
      ECHO %PARAMETER_NAME%=%PARAMETER_VALUE%>>"%TMP_PROPERTIES_FILE%"
      SET PARAMETER_FOUND="YES"
      ECHO Parameter set successfully.
    ) ELSE (
      ECHO %%i>>"%TMP_PROPERTIES_FILE%"
    )
  )
)
IF %PARAMETER_FOUND%=="NO" (
  ECHO Could not find '%PARAMETER_NAME%' parameter in the file. Terminating[%ERRORLEVEL%] 
  set ERRORLEVEL=2
  GOTO end
)
SET ERRORLEVEL=
move>NUL /Y "%TMP_PROPERTIES_FILE%" "%AGENT_PROPERTIES_FILE%"
IF "%ERRORLEVEL%"=="0" GOTO end
ECHO Could not override the Agent's property file '%AGENT_PROPERTIES_FILE%'. Terminating[%ERRORLEVEL%] 
SET ERRORLEVEL=2
GOTO end  

:print_usage
  ECHO "Usage: changeAgentProps.bat <parameter_name> <new_parameter_value> <properties_file>"
  
:end
 