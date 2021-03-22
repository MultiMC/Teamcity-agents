#!/bin/sh
# --------------------------------------------------------------------------------------
# DO NOT CHANGE THIS FILE! ALL YOUR CHANGES WILL BE ELIMINATED AFTER AUTOMATIC UPGRADE.
# --------------------------------------------------------------------------------------
# Searches for Java executable
# Usage: . findJava.sh; find_java <Minimal Java Version> [<Additional search directory> <Additional search directory> ...]
# E.g.: . findJava.sh; find_java 1.8
# Set FJ_LOOK_FOR_SERVER_JAVA environment variable to look for server Java only
# Set FJ_LOOK_FOR_X64_JAVA environment variable to look for x64 Java only
# Set FJ_LOOK_FOR_X86_JAVA environment variable to look for x86 Java only
# Set FJ_MIN_UNSUPPORTED_JAVA_VERSION environment variable to ignore Java starting from the specified version
# --------------------------------------------------------------------------------------

# --------------------------------------------------------------------------------------
# Determines version of Java executable located at $1.
# Returns 0 and sets determined version to $FJ_JAVA_VERSION variable on success, returns 1 otherwise.
# --------------------------------------------------------------------------------------
detect_version() {
  if [ -z "$1" ]; then return 1; fi

  eval "$1" -version 1>/dev/null 2>/dev/null
  if [ $? -ne 0 ]; then return 1; fi

  FJ_JAVA_VERSION=`"$1" -version 2>&1 | grep "version" | awk '-F"' '{print($2)}'`

  if [ -z "$FJ_JAVA_VERSION" ]; then return 1; fi

  return 0
}

# --------------------------------------------------------------------------------------
# Returns 0 if Java version ($1) is greater than or equal to $2, 1 otherwise.
# --------------------------------------------------------------------------------------
version_ge() {
  v1=`echo "$1" | sed -e 's/[-_+].*//g' 2>/dev/null`
  v2=`echo "$2" | sed -e 's/[-_+].*//g' 2>/dev/null`
  
  major1=`echo "$v1" | awk -F. '{print($1)}' 2>/dev/null`
  minor1=`echo "$v1" | awk -F. '{print($2)}' 2>/dev/null`
  major2=`echo "$v2" | awk -F. '{print($1)}' 2>/dev/null`
  minor2=`echo "$v2" | awk -F. '{print($2)}' 2>/dev/null`

  if [ $major1 -eq 1 -a -n "$minor1" ]; then
    major1="$minor1"
    minor1=`echo "$v1" | awk -F. '{print($3)}' 2>/dev/null`
  fi

  if [ $major2 -eq 1 -a -n "$minor2" ]; then
    major2="$minor2"
    minor2=`echo "$v2" | awk -F. '{print($3)}' 2>/dev/null`
  fi

  if [ -z "$minor1" ]; then
    minor1="0"
  fi

  if [ -z "$minor2" ]; then
    minor2="0"
  fi

  if [ $major1 -eq $major2 ]; then
    test $minor1 -ge $minor2
    return $?
  else
    test $major1 -gt $major2
    return $?
  fi
}

# --------------------------------------------------------------------------------------
# Returns 0 if the specified Java executable ($1) exists, has proper version and is server/x64 if needed; 1 otherwise.
# Sets $FJ_JAVA_EXEC and $FJ_JAVA_VERSION variables on success.
# --------------------------------------------------------------------------------------
check_java() {
  if [ -z "$1" ]; then return 1; fi
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT  Checking Java: $1" 1>&2; fi
  if [ ! -f "$1" ]; then
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Java executable does not exist" 1>&2; fi
    return 1
  fi

  detect_version "$1"
  if [ $? -ne 0 ]; then
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Failed to detect Java version" 1>&2; fi
    return 1
  fi

  check_java_internal "$1"
  if [ $? -ne 0 ]; then
    FJ_JAVA_VERSION=""
    return 1
  fi

  FJ_JAVA_EXEC="$1"
  return 0
}

# --------------------------------------------------------------------------------------
# Returns 0 if the specified Java executable ($1) has proper version and is server/x64 if needed; 1 otherwise.
# --------------------------------------------------------------------------------------
check_java_internal() {
  if [ -z "$1" ]; then return 1; fi
  if [ -z "$FJ_JAVA_VERSION" ]; then return 1; fi

  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Version: $FJ_JAVA_VERSION" 1>&2; fi

  version_ge $FJ_JAVA_VERSION $FJ_MIN_REQUIRED_JAVA_VERSION
  if [ $? -ne 0 ]; then
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Version is not suitable (less than $FJ_MIN_REQUIRED_JAVA_VERSION)" 1>&2; fi
    return 1
  fi

  if [ -n "$FJ_MIN_UNSUPPORTED_JAVA_VERSION" ]; then
    version_ge $FJ_JAVA_VERSION $FJ_MIN_UNSUPPORTED_JAVA_VERSION
    if [ $? -eq 0 ]; then
      if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Version is not supported (${FJ_MIN_UNSUPPORTED_JAVA_VERSION}+)" 1>&2; fi
      return 1
    fi
  fi

  if [ -n "$FJ_LOOK_FOR_SERVER_JAVA" ]; then
    eval "$1" -server -version 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
      if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Not a server Java" 1>&2; fi
      return 1
    fi
  fi

  if [ -n "$FJ_LOOK_FOR_X64_JAVA" ]; then
    # This code works for Java 1.7+ only.
    eval "$1" -d64 -version 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
      if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Not an x64 Java" 1>&2; fi
      return 1
    fi
  fi

  if [ -n "$FJ_LOOK_FOR_X86_JAVA" ]; then
    # This code works for Java 1.7+ only.
    eval "$1" -d32 -version 1>/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
      if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT    Not an x86 Java" 1>&2; fi
      return 1
    fi
  fi

  if [ -n "$FJ_DEBUG" ]; then
    echo "[`date +%T`] $FJ_DEBUG_INDENT    Java found!" 1>&2
    echo "" 1>&2
  fi

  return 0
}

# --------------------------------------------------------------------------------------
# Returns 0 if the specified directory ($1) is JDK home or JRE home, 1 otherwise.
# Sets $FJ_JAVA_EXEC and $FJ_JAVA_VERSION variables on success.
# --------------------------------------------------------------------------------------
check_dir() {
  if [ -z "$1" ]; then return 1; fi
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] ${FJ_DEBUG_INDENT}Checking directory: $1" 1>&2; fi
  if [ ! -d "$1" ]; then
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] $FJ_DEBUG_INDENT  Directory does not exist" 1>&2; fi
    return 1
  fi

  check_java "$1/jre/bin/java"
  if [ $? -eq 0 ]; then return 0; fi

  check_java "$1/bin/java"
  return $?
}

# --------------------------------------------------------------------------------------
# Returns 0 if the specified directory ($1) is JDK home or JRE home or contains a child directory, which is JDK home or JRE home, 1 otherwise.
# Additional relative path can be specified in $2.
# Sets $FJ_JAVA_EXEC and $FJ_JAVA_VERSION variables on success.
# --------------------------------------------------------------------------------------
scan_dir() {
  if [ -z "$1" ]; then return 1; fi
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`]   Scanning directory: $1" 1>&2; fi
  if [ ! -d "$1" ]; then
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`]     Directory does not exist" 1>&2; fi
    return 1
  fi

  check_dir "$1$2"
  if [ $? -eq 0 ]; then return 0; fi

  for child in $1/*; do
    if [ -d "$child" ]; then
      check_dir "$child$2"
      if [ $? -eq 0 ]; then return 0; fi
    fi
  done

  return 1
}

# --------------------------------------------------------------------------------------
# Main entry point.
# Returns 0 if Java of the version not less than $1 is found, 1 on incorrect usage, 2 otherwise.
# Sets $FJ_JAVA_EXEC and $FJ_JAVA_VERSION variables on success.
# --------------------------------------------------------------------------------------
find_java() {
  FJ_DEBUG_INDENT=""

  FJ_MIN_REQUIRED_JAVA_VERSION="$1"
  if [ -z "$FJ_MIN_REQUIRED_JAVA_VERSION" ]; then
    echo "" 1>&2
    echo "Usage:" 1>&2
    echo "  . findJava.sh; find_java <Minimal required Java version> [<Additional search directory> <Additional search directory> ...]" 1>&2
    echo "" 1>&2
    echo "E.g.: . findJava.sh; find_java 1.8" 1>&2
    echo "" 1>&2
    echo "Set FJ_LOOK_FOR_SERVER_JAVA environment variable to look for server Java only" 1>&2
    echo "Set FJ_LOOK_FOR_X64_JAVA environment variable to look for x64 Java only" 1>&2
    echo "Set FJ_LOOK_FOR_X86_JAVA environment variable to look for x86 Java only" 1>&2
    echo "Set FJ_MIN_UNSUPPORTED_JAVA_VERSION environment variable to ignore Java starting from the specified version" 1>&2
    echo "" 1>&2
    return 1
  fi

  if [ -n "$FJ_DEBUG" ]; then
    echo "" 1>&2
    echo "Looking for Java ${FJ_MIN_REQUIRED_JAVA_VERSION}+" 1>&2
    if [ -n "$FJ_LOOK_FOR_SERVER_JAVA" ]; then echo "Looking for server Java" 1>&2; fi
    if [ -n "$FJ_LOOK_FOR_X64_JAVA" ]; then echo "Looking for x64 Java" 1>&2; fi
    if [ -n "$FJ_LOOK_FOR_X86_JAVA" ]; then echo "Looking for x86 Java" 1>&2; fi
    if [ -n "$FJ_MIN_UNSUPPORTED_JAVA_VERSION" ]; then echo "Looking for Java less than $FJ_MIN_UNSUPPORTED_JAVA_VERSION" 1>&2; fi
    echo "" 1>&2;
  fi

  # Check if result is already found and is suitable
  if [ -n "$FJ_JAVA_EXEC" ]; then
    if [ -n "$FJ_DEBUG" ]; then
      echo "[`date +%T`] Checking the previously found or explicitly specified Java" 1>&2
      echo "[`date +%T`]   Checking Java: $FJ_JAVA_EXEC" 1>&2
    fi
    if [ ! -f "$FJ_JAVA_EXEC" ]; then
      if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`]     Java executable does not exist" 1>&2; fi
    else
      if [ -z "$FJ_JAVA_VERSION" ]; then
        if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`]     Detecting Java version" 1>&2; fi
        detect_version "$FJ_JAVA_EXEC"
      fi
      if [ -z "$FJ_JAVA_VERSION" ]; then
        if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`]     Version is unknown" 1>&2; fi
      else
        check_java_internal "$FJ_JAVA_EXEC"
        if [ $? -eq 0 ]; then return 0; fi
      fi
    fi
  fi

  FJ_JAVA_EXEC=""
  FJ_JAVA_VERSION=""

  FJ_DEBUG_INDENT="    "

  # Check directories passed as parameters
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking directories passed as parameters" 1>&2; fi
  FJ_ALL_CUSTOM_DIRS=""
  shift
  for dir in "$@"; do
    scan_dir "$dir"
    if [ $? -eq 0 ]; then return 0; fi

    if [ -n "$FJ_ALL_CUSTOM_DIRS" ]; then FJ_ALL_CUSTOM_DIRS="$FJ_ALL_CUSTOM_DIRS, "; fi
    FJ_ALL_CUSTOM_DIRS="$FJ_ALL_CUSTOM_DIRS'$dir'"
  done

  FJ_DEBUG_INDENT="  "

  if [ -n "$FJ_SKIP_ALL_EXCEPT_ARGS" ]; then
     return 2
  fi

  # Check JRE_HOME
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking JRE_HOME: $JRE_HOME" 1>&2; fi
  check_dir "$JRE_HOME"
  if [ $? -eq 0 ]; then return 0; fi

  # Check JAVA_HOME
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking JAVA_HOME: $JAVA_HOME" 1>&2; fi
  check_dir "$JAVA_HOME"
  if [ $? -eq 0 ]; then return 0; fi

  # Check JDK_HOME
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking JDK_HOME: $JDK_HOME" 1>&2; fi
  check_dir "$JDK_HOME"
  if [ $? -eq 0 ]; then return 0; fi

  # Mac OS X
  test `uname` = "Darwin"
  IS_MAC=$?
  if [ $IS_MAC -eq 0 ]; then
    # Try java_home utility first
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Trying 'java_home' utility" 1>&2; fi

    check_dir `/usr/libexec/java_home -v $FJ_MIN_REQUIRED_JAVA_VERSION 2>/dev/null`
    if [ $? -eq 0 ]; then return 0; fi

    check_dir `/usr/libexec/java_home 2>/dev/null`
    if [ $? -eq 0 ]; then return 0; fi

    FJ_DEBUG_INDENT="    "

    # Check Mac OS X default place
    if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking default places" 1>&2; fi

    scan_dir "/Library/Java/JavaVirtualMachines" "/Contents/Home"
    if [ $? -eq 0 ]; then return 0; fi

    scan_dir "/System/Library/Java/JavaVirtualMachines" "/Contents/Home"
    if [ $? -eq 0 ]; then return 0; fi

    scan_dir "/System/Library/Frameworks/JavaVM.framework/Versions" "/Home"
    if [ $? -eq 0 ]; then return 0; fi

    FJ_DEBUG_INDENT="  "

    check_dir "/System/Library/Frameworks/JavaVM.framework/Home"
    if [ $? -eq 0 ]; then return 0; fi

    check_dir "/Library/Java/Home"
    if [ $? -eq 0 ]; then return 0; fi
  fi

  FJ_DEBUG_INDENT="    "

  # Check Linux default places
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking default places" 1>&2; fi

  scan_dir "/usr/lib/jvm"
  if [ $? -eq 0 ]; then return 0; fi

  scan_dir "/usr/java"
  if [ $? -eq 0 ]; then return 0; fi

  scan_dir "/usr/local/java"
  if [ $? -eq 0 ]; then return 0; fi

  FJ_DEBUG_INDENT=""

  # Check Java in PATH
  if [ -n "$FJ_DEBUG" ]; then echo "[`date +%T`] Checking Java in PATH" 1>&2; fi

  check_java `which java 2>/dev/null`
  if [ $? -eq 0 ]; then return 0; fi

  check_java java
  if [ $? -eq 0 ]; then return 0; fi

  # Report 'no Java found'
  echo "" 1>&2
  echo "Java executable of version $FJ_MIN_REQUIRED_JAVA_VERSION is not found:" 1>&2
  if [ -n "$FJ_ALL_CUSTOM_DIRS" ]; then echo "- Java executable is not found under the specified directories: $FJ_ALL_CUSTOM_DIRS" 1>&2; fi
  echo "- Neither the JAVA_HOME nor the JRE_HOME environment variable is defined" 1>&2
  if [ $IS_MAC -eq 0 ]; then
    echo "- Java executable is not found using 'java_home' utility" 1>&2
  fi
  echo "- Java executable is not found in the default locations" 1>&2
  echo "- Java executable is not found in the directories listed in the PATH environment variable" 1>&2
  echo "" 1>&2
  echo "Please make sure either JAVA_HOME or JRE_HOME environment variable is defined and is pointing to the root directory of the valid Java (JRE) installation" 1>&2
  if [ -n "$FJ_MIN_UNSUPPORTED_JAVA_VERSION" ]; then
    echo "Please note that all Java versions starting from $FJ_MIN_UNSUPPORTED_JAVA_VERSION were skipped because stable operation on these Java versions is not guaranteed" 1>&2;
  fi
  if [ -z "$FJ_DEBUG" ]; then
    echo "" 1>&2
    echo "Environment variable FJ_DEBUG can be set to enable debug output" 1>&2
  fi
  echo "" 1>&2

  return 2
}
