:: ---------------------------------------------------------------------
:: Downloads and install/unzip JDK/JRE from a TeamCity Server/Sun
:: %1 TeamCity Server download url
:: %2 Installation directory 
:: ---------------------------------------------------------------------

IF "%2%"=="" (
  ECHO "Usage: installJava.bat <TeamCity Server download url> <Installation directory>"  
  SET ERRORLEVEL=2
  GOTO end
)

SET TEAMCITY_DOWNLOAD_URL=%1%
SET TEAMCITY_JDK_WIN_ZIP=%TEAMCITY_DOWNLOAD_URL%/agent-jdk-win.zip
SET TEAMCITY_JRE_WIN_ZIP=%TEAMCITY_DOWNLOAD_URL%/agent-jre-win.zip
SET SUN_JRE_WIN_INSTALLER=http://javadl.sun.com/webapps/download/AutoDL?BundleId=48344

SET TEAMCITY_JAVA_INSTALL_PATH=%2%
FOR /F "tokens=*" %%i in ("%TEAMCITY_JAVA_INSTALL_PATH%") DO SET TEAMCITY_JAVA_INSTALL_PATH=%%~i

:: check bootsrapper's functionality available
IF "%TEAMCITY_BOOTSRAPPER_WIN%"=="" SET TEAMCITY_BOOTSRAPPER_WIN=bootstrapper.exe
"%TEAMCITY_BOOTSRAPPER_WIN%">NUL 2>&1
IF ERRORLEVEL 251 (
  SET ERRORLEVEL=2
  ECHO Could not find '%TEAMCITY_BOOTSRAPPER_WIN%'. 
  GOTO end
)

:: clean target if exist
IF EXIST "%TEAMCITY_JAVA_INSTALL_PATH%" (
  ECHO Cleaning "%TEAMCITY_JAVA_INSTALL_PATH%"...
  RMDIR /S /Q "%TEAMCITY_JAVA_INSTALL_PATH%"
)
 
:: try JDK
ECHO Attempt to download JDK from '%TEAMCITY_JDK_WIN_ZIP%'...
"%TEAMCITY_BOOTSRAPPER_WIN%" unzip -progress -u %TEAMCITY_JDK_WIN_ZIP% -d "%TEAMCITY_JAVA_INSTALL_PATH%"
IF NOT ERRORLEVEL 1 (
  ECHO JDK unpacked into '%TEAMCITY_JAVA_INSTALL_PATH%'
  GOTO end
)

:: try JRE
ECHO Attempt to download JRE from '%TEAMCITY_JRE_WIN_ZIP%'
"%TEAMCITY_BOOTSRAPPER_WIN%" unzip -progress -u %TEAMCITY_JRE_WIN_ZIP% -d "%TEAMCITY_JAVA_INSTALL_PATH%"
IF NOT ERRORLEVEL 1 (
  ECHO JRE unpacked into '%TEAMCITY_JAVA_INSTALL_PATH%'
  GOTO end
)

:: try JRE from SUN
ECHO Attempt to download JDK from Sun...
"%TEAMCITY_BOOTSRAPPER_WIN%" get -progress -u %SUN_JRE_WIN_INSTALLER% -d "sun-jre-win.exe"
IF NOT ERRORLEVEL 1 (
  ECHO Installing JRE...
  sun-jre-win.exe /s /v/qn
  IF NOT ERRORLEVEL 1 (
     DEL /F sun-jre-win.exe
     ECHO JRE successfully installed
     GOTO end
  )
)
SET ERRORLEVEL=2
GOTO end

:end
