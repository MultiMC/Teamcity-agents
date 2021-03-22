@echo off
rem --------------------------------------------------------------------------------------
rem DO NOT CHANGE THIS FILE! ALL YOUR CHANGES WILL BE ELIMINATED AFTER AUTOMATIC UPGRADE.
rem --------------------------------------------------------------------------------------
rem Searches for Java executable
rem Usage: findJava.bat <Minimal required Java version> [<Additional search directory> <Additional search directory> ...]
rem E.g.: findJava.bat 1.8
rem Set FJ_LOOK_FOR_SERVER_JAVA environment variable to look for server Java only
rem Set FJ_LOOK_FOR_X64_JAVA environment variable to look for x64 Java only
rem Set FJ_LOOK_FOR_X86_JAVA environment variable to look for x86 Java only
rem Set FJ_MIN_UNSUPPORTED_JAVA_VERSION environment variable to ignore Java starting from the specified version
rem --------------------------------------------------------------------------------------

rem workaround for the case if ERRORLEVEL was set by parent process
set ERRORLEVEL=

setlocal disabledelayedexpansion
set "FJ_SCRIPT=%~df0"
setlocal enabledelayedexpansion

rem **************************************************************************************
rem --------------------------------------------------------------------------------------
rem Function declarations
rem --------------------------------------------------------------------------------------
rem **************************************************************************************

if "%~1" == "fun" (
  endlocal
  set "FUN_NAME=%~2"
  set "FUN_ARG_PATH=%~df3"
  set "FUN_ARG1=%~3"
  set "FUN_ARG2=%~4"
  setlocal enabledelayedexpansion

  rem --------------------------------------------------------------------------------------
  rem "detect_version" function
  rem --------------------------------------------------------------------------------------
  rem Determines version of Java executable located at #3.
  rem Returns exit code 0 and sets determined version to FJ_JAVA_VERSION variable on success, returns exit code -1 otherwise.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "detect_version" (
    if "!FUN_ARG1!" == "" goto exit_fail

    call "!FUN_ARG_PATH!" -version 1>nul 2>nul <nul
    if not "!ERRORLEVEL!" == "0" goto exit_fail

    for /f "tokens=3" %%i in ('call "!FUN_ARG_PATH!" -version 2^>^&1 ^| findstr /i "version"') do (
      endlocal
      set "FJ_JAVA_VERSION=%%~i"
      setlocal enabledelayedexpansion
    )

    if "!FJ_JAVA_VERSION!" == "" goto exit_fail

    goto exit_ok
  )

  rem --------------------------------------------------------------------------------------
  rem "version_ge" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if Java version #3 is greater than or equal to #4, -1 otherwise.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "version_ge" (
    for /f "tokens=1 delims=-_+" %%a in ("!FUN_ARG1!") do (
      for /f "tokens=1 delims=-_+" %%b in ("!FUN_ARG2!") do (
        endlocal
        set "V1=%%a"
        set "V2=%%b"
        setlocal enabledelayedexpansion

        for /f "tokens=1,2,3 delims=." %%i in ("!V1!") do (
          for /f "tokens=1,2,3 delims=." %%x in ("!V2!") do (
            endlocal
            set "MAJOR1=%%i"
            set "MINOR1=%%j"
            set "SECURITY1=%%k"
            set "MAJOR2=%%x"
            set "MINOR2=%%y"
            set "SECURITY2=%%z"
            setlocal enabledelayedexpansion

            if "!MAJOR1!" == "1" if not "!MINOR1!" == "" (
              set "MAJOR1=!MINOR1!"
              set "MINOR1=!SECURITY1!"
            )

            if "!MAJOR2!" == "1" if not "!MINOR2!" == "" (
              set "MAJOR2=!MINOR2!"
              set "MINOR2=!SECURITY2!"
            )

            if "!MINOR1!" == "" (
              set "MINOR1=0"
            )

            if "!MINOR2!" == "" (
              set "MINOR2=0"
            )

            if !MAJOR1! equ !MAJOR2! (
              if !MINOR1! geq !MINOR2! (
                exit /b 0
              ) else (
                exit /b -1
              )
            ) else (
              if !MAJOR1! gtr !MAJOR2! (
                exit /b 0
              ) else (
                exit /b -1
              )
            )
          )
        )
      )
    )
  )

  rem --------------------------------------------------------------------------------------
  rem "check_java" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if the specified Java executable #3 exists, has proper version and is server/x64 if needed; -1 otherwise.
  rem Sets FJ_JAVA_EXEC and FJ_JAVA_VERSION variables on success.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "check_java" (
    if "!FUN_ARG1!" == "" goto exit_fail
    if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!  Checking Java: !FUN_ARG_PATH! 1>&2
    if not exist "!FUN_ARG_PATH!" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Java executable does not exist 1>&2
      goto exit_fail
    )

    call "!FJ_SCRIPT!" fun detect_version "!FUN_ARG_PATH!" <nul
    if "!ERRORLEVEL!" == "-1" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Failed to detect Java version 1>&2
      goto exit_fail
    )

    call "!FJ_SCRIPT!" fun check_java_internal "!FUN_ARG_PATH!" <nul
    if not "!ERRORLEVEL!" == "0" goto exit_fail

    for /f "delims=" %%x in ("!FJ_JAVA_VERSION!") do (
      endlocal
      set "FJ_JAVA_VERSION=%%x"
      setlocal enabledelayedexpansion
    )

    for /f "delims=" %%x in ("!FUN_ARG_PATH!") do (
      endlocal
      set "FJ_JAVA_EXEC=%%x"
      setlocal enabledelayedexpansion
    )

    goto exit_ok
  )

  rem --------------------------------------------------------------------------------------
  rem "check_java_internal" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if the specified Java executable #3 has proper version and is server/x64 if needed; -1 otherwise.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "check_java_internal" (
    if "!FUN_ARG1!" == "" goto exit_fail
    if not exist "!FUN_ARG_PATH!" goto exit_fail
    if "!FJ_JAVA_VERSION!" == "" goto exit_fail

    if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Version: !FJ_JAVA_VERSION! 1>&2

    call "!FJ_SCRIPT!" fun version_ge !FJ_JAVA_VERSION! !FJ_MIN_REQUIRED_JAVA_VERSION! <nul
    if not "!ERRORLEVEL!" == "0" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Version is not suitable ^(less than !FJ_MIN_REQUIRED_JAVA_VERSION!^) 1>&2
      goto exit_fail
    )

    if not "!FJ_MIN_UNSUPPORTED_JAVA_VERSION!" == "" (
      call "!FJ_SCRIPT!" fun version_ge !FJ_JAVA_VERSION! !FJ_MIN_UNSUPPORTED_JAVA_VERSION! <nul
      if "!ERRORLEVEL!" == "0" (
        if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Version is not supported ^(!FJ_MIN_UNSUPPORTED_JAVA_VERSION!+^) 1>&2
        goto exit_fail
      )
    )

    if not "!FJ_LOOK_FOR_SERVER_JAVA!" == "" (
      call "!FUN_ARG_PATH!" -server -version 1>nul 2>nul <nul
      if not "!ERRORLEVEL!" == "0" (
        if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Not a server Java 1>&2
        goto exit_fail
      )
    )

    if not "!FJ_LOOK_FOR_X64_JAVA!" == "" (
      rem This code works for Java 1.7+ only.
      call "!FUN_ARG_PATH!" -d64 -version 1>nul 2>nul <nul
      if not "!ERRORLEVEL!" == "0" (
        if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Not an x64 Java 1>&2
        goto exit_fail
      )
    )

    if not "!FJ_LOOK_FOR_X86_JAVA!" == "" (
      rem This code works for Java 1.7+ only.
      call "!FUN_ARG_PATH!" -d32 -version 1>nul 2>nul <nul
      if not "!ERRORLEVEL!" == "0" (
        if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!    Not an x86 Java 1>&2
        goto exit_fail
      )
    )

    if not "!FJ_DEBUG!" == "" (
      echo [!TIME!] !FJ_DEBUG_INDENT!    Java found^^! 1>&2
      echo. 1>&2
    )

    goto exit_ok
  )

  rem --------------------------------------------------------------------------------------
  rem "check_dir" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if the specified directory #3 is JDK home or JRE home, -1 otherwise.
  rem Sets FJ_JAVA_EXEC and FJ_JAVA_VERSION variables on success.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "check_dir" (
    if "!FUN_ARG1!" == "" goto exit_fail
    if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!Checking directory: !FUN_ARG_PATH! 1>&2
    if not exist "!FUN_ARG_PATH!" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!] !FJ_DEBUG_INDENT!  Directory does not exist 1>&2
      goto exit_fail
    )

    call "!FJ_SCRIPT!" fun check_java "!FUN_ARG_PATH!\jre\bin\java.exe" <nul
    if "!ERRORLEVEL!" == "0" goto exit_ok

    call "!FJ_SCRIPT!" fun check_java "!FUN_ARG_PATH!\bin\java.exe" <nul
    if "!ERRORLEVEL!" == "0" goto exit_ok

    goto exit_fail
  )

  rem --------------------------------------------------------------------------------------
  rem "scan_dir" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if the specified directory #3 is JDK home or JRE home or contains a child directory, which is JDK home or JRE home, -1 otherwise.
  rem Sets FJ_JAVA_EXEC and FJ_JAVA_VERSION variables on success.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "scan_dir" (
    if "!FUN_ARG1!" == "" goto exit_fail
    if not "!FJ_DEBUG!" == "" echo [!TIME!]   Scanning directory: !FUN_ARG_PATH! 1>&2
    if not exist "!FUN_ARG_PATH!" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!]     Directory does not exist 1>&2
      goto exit_fail
    )

    call "!FJ_SCRIPT!" fun check_dir "!FUN_ARG_PATH!" <nul
    if "!ERRORLEVEL!" == "0" goto exit_ok

    for /f %%i in ('dir "!FUN_ARG_PATH!" /A:D /B /O:-D /X 2^>nul') do (
      endlocal
      set "II=%%i"
      setlocal enabledelayedexpansion

      call "!FJ_SCRIPT!" fun check_dir "!FUN_ARG_PATH!\!II!" <nul
      if "!ERRORLEVEL!" == "0" goto exit_ok
    )

    goto exit_fail
  )

  rem --------------------------------------------------------------------------------------
  rem "check_reg_version_key" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if the specified registry Java version key #3 exists and has the specified Java home, -1 otherwise.
  rem Sets FJ_JAVA_EXEC and FJ_JAVA_VERSION variables on success.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "check_reg_version_key" (
    if not "!FJ_DEBUG!" == "" echo [!TIME!]     Checking registry key: !FUN_ARG1! 1>&2
    for /f "tokens=2*" %%a in ('reg query "!FUN_ARG1!" /v JavaHome 2^>nul ^| find "JavaHome"') do (
      endlocal
      set "BB=%%b"
      setlocal enabledelayedexpansion

      call "!FJ_SCRIPT!" fun check_dir "!BB!" <nul
      if "!ERRORLEVEL!" == "0" goto exit_ok
    )
    goto exit_fail
  )

  rem --------------------------------------------------------------------------------------
  rem "scan_reg_key" function
  rem --------------------------------------------------------------------------------------
  rem Returns exit code 0 if the specified registry key "#3\#4" contains a child version key with the specified Java home, -1 otherwise.
  rem Sets FJ_JAVA_EXEC and FJ_JAVA_VERSION variables on success.
  rem --------------------------------------------------------------------------------------
  if "!FUN_NAME!" == "scan_reg_key" (
    if not "!FJ_DEBUG!" == "" echo [!TIME!]   Scanning registry key: !FUN_ARG1!\!FUN_ARG2! 1>&2
    for /f "tokens=5* delims=\" %%x in ('reg query "!FUN_ARG1!\!FUN_ARG2!" 2^>nul ^| findstr /i /c:"!FUN_ARG2!\\"') do (
      endlocal
      set "XX=%%x"
      set "YY=%%y"
      setlocal enabledelayedexpansion

      if "!YY!" == "" (
        call "!FJ_SCRIPT!" fun check_reg_version_key "!FUN_ARG1!\!FUN_ARG2!\!XX!" <nul
        if "!ERRORLEVEL!" == "0" goto exit_ok
      ) else (
        call "!FJ_SCRIPT!" fun check_reg_version_key "!FUN_ARG1!\!FUN_ARG2!\!YY!" <nul
        if "!ERRORLEVEL!" == "0" goto exit_ok
      )
    )
    goto exit_fail
  )

  goto exit_fail
)

rem **************************************************************************************
rem --------------------------------------------------------------------------------------
rem Script start
rem --------------------------------------------------------------------------------------
rem **************************************************************************************

endlocal
set "FJ_MIN_REQUIRED_JAVA_VERSION=%~1"
set "FJ_SCRIPT_NAME=%~nx0"
set "FJ_DEBUG_INDENT="
setlocal enabledelayedexpansion

if "!FJ_MIN_REQUIRED_JAVA_VERSION!" == "" (
  echo. 1>&2
  echo Usage: 1>&2
  echo   !FJ_SCRIPT_NAME! ^<Minimal required Java version^> [^<Additional search directory^> ^<Additional search directory^> ...] 1>&2
  echo. 1>&2
  echo E.g.: !FJ_SCRIPT_NAME! 1.8 1>&2
  echo. 1>&2
  echo Set FJ_LOOK_FOR_SERVER_JAVA environment variable to look for server Java only 1>&2
  echo Set FJ_LOOK_FOR_X64_JAVA environment variable to look for x64 Java only 1>&2
  echo Set FJ_LOOK_FOR_X86_JAVA environment variable to look for x86 Java only 1>&2
  echo Set FJ_MIN_UNSUPPORTED_JAVA_VERSION environment variable to ignore Java starting from the specified version 1>&2
  echo. 1>&2
  exit /b 1
)

if not "!FJ_DEBUG!" == "" (
  echo. 1>&2
  echo Looking for Java !FJ_MIN_REQUIRED_JAVA_VERSION!+ 1>&2
  if not "!FJ_LOOK_FOR_SERVER_JAVA!" == "" echo Looking for server Java 1>&2
  if not "!FJ_LOOK_FOR_X64_JAVA!" == "" echo Looking for x64 Java 1>&2
  if not "!FJ_LOOK_FOR_X86_JAVA!" == "" echo Looking for x86 Java 1>&2
  if not "!FJ_MIN_UNSUPPORTED_JAVA_VERSION!" == "" echo Looking for Java less than !FJ_MIN_UNSUPPORTED_JAVA_VERSION! 1>&2
  echo. 1>&2
)

rem Check if result is already found and is suitable
if not "!FJ_JAVA_EXEC!" == "" (
  if not "!FJ_DEBUG!" == "" (
    echo [!TIME!] Checking the previously found or explicitly specified Java 1>&2
    echo [!TIME!]   Checking Java: !FJ_JAVA_EXEC! 1>&2
  )
  if not exist "!FJ_JAVA_EXEC!" (
    if not "!FJ_DEBUG!" == "" echo [!TIME!]     Java executable does not exist 1>&2
  ) else (
    if "!FJ_JAVA_VERSION!" == "" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!]     Detecting Java version 1>&2
      call "!FJ_SCRIPT!" fun detect_version "!FJ_JAVA_EXEC!" <nul
    )
    if "!FJ_JAVA_VERSION!" == "" (
      if not "!FJ_DEBUG!" == "" echo [!TIME!]     Version is unknown 1>&2
    ) else (
      call "!FJ_SCRIPT!" fun check_java_internal "!FJ_JAVA_EXEC!" <nul
      if "!ERRORLEVEL!" == "0" goto exit_ok
    )
  )
)

endlocal
set "FJ_JAVA_EXEC="
set "FJ_JAVA_VERSION="
set "FJ_DEBUG_INDENT=    "
setlocal enabledelayedexpansion

rem Check directories passed as parameters
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking directories passed as parameters 1>&2
endlocal
set "FJ_ALL_CUSTOM_DIRS="
:: -1 to ignore first argument
set "FJ_CUSTOM_DIRS_ARGC=-1"
for %%x in (%*) do set /A FJ_CUSTOM_DIRS_ARGC+=1
setlocal enabledelayedexpansion
:params_loop
  if !FJ_CUSTOM_DIRS_ARGC! LEQ 0 goto params_loop_end
  shift

  endlocal
  set "FJ_CUSTOM_DIR=%~1"
  set "FJ_CUSTOM_DIR_PATH=%~df1"
  set /A FJ_CUSTOM_DIRS_ARGC-=1
  setlocal enabledelayedexpansion

  if "!FJ_CUSTOM_DIR!" == "" goto params_loop

  if not "!FJ_ALL_CUSTOM_DIRS!" == "" set "FJ_ALL_CUSTOM_DIRS=!FJ_ALL_CUSTOM_DIRS!, "
  set "FJ_ALL_CUSTOM_DIRS=!FJ_ALL_CUSTOM_DIRS!^"!FJ_CUSTOM_DIR_PATH!^""
  for /f "delims=" %%x in ("!FJ_ALL_CUSTOM_DIRS!") do (
    endlocal
    set "FJ_ALL_CUSTOM_DIRS=%%x"
    setlocal enabledelayedexpansion
  )

  call "!FJ_SCRIPT!" fun scan_dir "!FJ_CUSTOM_DIR_PATH!" <nul
  if "!ERRORLEVEL!" == "0" goto exit_ok

  goto params_loop
:params_loop_end

endlocal
set "FJ_CUSTOM_DIRS_ARGC="
set "FJ_DEBUG_INDENT=  "
setlocal enabledelayedexpansion

if not "!FJ_SKIP_ALL_EXCEPT_ARGS!" == "" goto skip_all

rem Check JRE_HOME
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking JRE_HOME: !JRE_HOME! 1>&2
call "!FJ_SCRIPT!" fun check_dir "!JRE_HOME!" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

rem Check JAVA_HOME
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking JAVA_HOME: !JAVA_HOME! 1>&2
call "!FJ_SCRIPT!" fun check_dir "!JAVA_HOME!" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

rem Check JDK_HOME
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking JDK_HOME: !JDK_HOME! 1>&2
call "!FJ_SCRIPT!" fun check_dir "!JDK_HOME!" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

endlocal
set "FJ_DEBUG_INDENT=      "
setlocal enabledelayedexpansion

rem Check registry
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking registry 1>&2

call "!FJ_SCRIPT!" fun scan_reg_key "HKLM" "SOFTWARE\JavaSoft\JRE" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

call "!FJ_SCRIPT!" fun scan_reg_key "HKLM" "Software\Wow6432Node\JavaSoft\Java Runtime Environment" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

call "!FJ_SCRIPT!" fun scan_reg_key "HKLM" "Software\JavaSoft\Java Runtime Environment" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

call "!FJ_SCRIPT!" fun scan_reg_key "HKLM" "SOFTWARE\JavaSoft\JDK" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

call "!FJ_SCRIPT!" fun scan_reg_key "HKLM" "Software\Wow6432Node\JavaSoft\Java Development Kit" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

call "!FJ_SCRIPT!" fun scan_reg_key "HKLM" "Software\JavaSoft\Java Development Kit" <nul
if "!ERRORLEVEL!" == "0" goto exit_ok

endlocal
set "FJ_DEBUG_INDENT=    "
setlocal enabledelayedexpansion

rem Check Windows default places
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking default places 1>&2
if not "!ProgramW6432!" == "" (
  call "!FJ_SCRIPT!" fun scan_dir "!ProgramW6432!\Java" <nul
  if "!ERRORLEVEL!" == "0" goto exit_ok
)
if not "!ProgramFiles(x86)!" == "" (
  call "!FJ_SCRIPT!" fun scan_dir "!ProgramFiles(x86)!\Java" <nul
  if "!ERRORLEVEL!" == "0" goto exit_ok
) else if not "!ProgramFiles!" == "" (
  call "!FJ_SCRIPT!" fun scan_dir "!ProgramFiles!\Java" <nul
  if "!ERRORLEVEL!" == "0" goto exit_ok
)

endlocal
set "FJ_DEBUG_INDENT="
setlocal enabledelayedexpansion

rem Check Java in PATH
if not "!FJ_DEBUG!" == "" echo [!TIME!] Checking Java in PATH 1>&2
for /f %%i in ("java.exe") do (
  endlocal
  set "II=%%~fd$PATH:i"
  setlocal enabledelayedexpansion

  call "!FJ_SCRIPT!" fun check_java "!II!" <nul
  if "!ERRORLEVEL!" == "0" goto exit_ok
)

:skip_all

rem Report 'no Java found'
echo. 1>&2
echo Java executable of version !FJ_MIN_REQUIRED_JAVA_VERSION! is not found: 1>&2
if not "!FJ_ALL_CUSTOM_DIRS!" == "" echo - Java executable is not found under the specified directories: !FJ_ALL_CUSTOM_DIRS! 1>&2
echo - Neither the JAVA_HOME nor the JRE_HOME environment variable is defined 1>&2
echo - Path to JVM is not found in Windows registry 1>&2
echo - Java executable is not found in the default locations 1>&2
echo - Java executable is not found in the directories listed in the PATH environment variable 1>&2
echo. 1>&2
echo Please make sure either JAVA_HOME or JRE_HOME environment variable is defined and is pointing to the root directory of the valid Java ^(JRE^) installation 1>&2
if not "!FJ_MIN_UNSUPPORTED_JAVA_VERSION!" == "" echo Please note that all Java versions starting from !FJ_MIN_UNSUPPORTED_JAVA_VERSION! were skipped because stable operation on these Java versions is not guaranteed 1>&2
if "!FJ_DEBUG!" == "" (
  echo. 1>&2
  echo Environment variable FJ_DEBUG can be set to enable debug output 1>&2
)
echo. 1>&2

:exit_fail
if 0 == 0 (
  endlocal
  endlocal
  set "FJ_JAVA_EXEC="
  set "FJ_JAVA_VERSION="
)
exit /b -1

:exit_ok
if 0 == 0 (
  endlocal
  endlocal
  set "FJ_JAVA_EXEC=%FJ_JAVA_EXEC%"
  set "FJ_JAVA_VERSION=%FJ_JAVA_VERSION%"
)
exit /b 0
