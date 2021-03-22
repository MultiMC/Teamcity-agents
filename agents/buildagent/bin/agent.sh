#!/bin/sh
# ------------------------------------------------------------------------------------------------
# Please do not modify this script, your changes will be lost after each TeamCity server upgrade !
# ------------------------------------------------------------------------------------------------

# ---------------------------------------------------------------------
# TeamCity build agent start/stop script
# ---------------------------------------------------------------------
# Environment variables:
#
# JAVA_HOME or JRE_HOME     Set Java to use by agent process. Must point to a directory with bin/java executable.
#
# TEAMCITY_AGENT_MEM_OPTS   Set agent memory options (JVM options)
#
# TEAMCITY_AGENT_OPTS       Set additional agent JVM options
#
# TEAMCITY_LAUNCHER_MEM_OPTS    Set agent launcher memory options (JVM options)
#
# TEAMCITY_LAUNCHER_OPTS    Set agent launcher JVM options
#
# TEAMCITY_AGENT_PREPARE_SCRIPT    name of a script to execute before start/stop
#
# ---------------------------------------------------------------------

old_cwd=`pwd`
this_script="$0"
command_name=$1
command_sub_name=$2
workingdir=`dirname "$this_script"`
cd "$workingdir"


if [ "$CONFIG_FILE" = "" ]; then
    CONFIG_FILE=../conf/buildAgent.properties
fi
# TODO: Read LOG_DIR from buildAgent.properties for Bundle compatibility
if [ "$LOG_DIR" = "" ]; then
    LOG_DIR=../logs
fi

TEAMCITY_AGENT_MEM_OPTS_ACTUAL="$TEAMCITY_AGENT_MEM_OPTS"

if [ "$TEAMCITY_AGENT_MEM_OPTS_ACTUAL" = "" ]; then
    TEAMCITY_AGENT_MEM_OPTS_ACTUAL="-Xmx384m"
fi

# uncomment for debugging OOM errors:
#    TEAMCITY_AGENT_MEM_OPTS_ACTUAL="$TEAMCITY_AGENT_MEM_OPTS_ACTUAL -XX:+HeapDumpOnOutOfMemoryError"

TEAMCITY_AGENT_OPTS_ACTUAL="$TEAMCITY_AGENT_OPTS -ea $TEAMCITY_AGENT_MEM_OPTS_ACTUAL -Dteamcity_logs=$LOG_DIR/"

TEAMCITY_LAUNCHER_MEM_OPTS_ACTUAL="$TEAMCITY_LAUNCHER_MEM_OPTS"

if [ "$TEAMCITY_LAUNCHER_MEM_OPTS_ACTUAL" = "" ]; then
    TEAMCITY_LAUNCHER_MEM_OPTS_ACTUAL="-Xms16m -Xmx64m"
fi

TEAMCITY_LAUNCHER_OPTS_ACTUAL="-ea $TEAMCITY_LAUNCHER_OPTS $TEAMCITY_LAUNCHER_MEM_OPTS_ACTUAL"

if [ -f ../conf/teamcity-agent-log4j.xml ]; then
    TEAMCITY_AGENT_OPTS_ACTUAL="$TEAMCITY_AGENT_OPTS_ACTUAL -Dlog4j.configuration=file:../conf/teamcity-agent-log4j.xml"
fi

if [ "$PID_FILE" = "" ]; then
    PID_FILE=$LOG_DIR/buildAgent.pid
fi

TEAMCITY_LAUNCHER_CLASSPATH="../launcher/lib/launcher.jar"

check_alive() {
    ps_alive=0
    if [ -f "$PID_FILE" ] ; then
      # Some 'ps' requires '-p' flag (Solaris 10 default). Solaris 10 /usr/ucb/ps does not support '-p'
      minus_p=''
      if ps -p 1 >/dev/null 2>/dev/null; then
        minus_p='-p'
      fi
      if ps $minus_p `cat $PID_FILE` >/dev/null 2>&1; then
        ps_alive=1;
      else
        rm $PID_FILE
      fi
    fi

    if [ "$ps_alive" = "0" ]; then
        return 1
    else
      # Special case for Solaris, since default ps truncates output and there no '-w' option
      case "`uname`" in
      SunOS*)
        # Ensure proper ps and grep would be used
        PATH="/usr/ucb:/usr/xpg6/bin:/usr/xpg4/bin:$PATH"
        export PATH
        if ps auxww 1>/dev/null 2>/dev/null; then
          if ps auxww "`cat "$PID_FILE"`" 2>/dev/null | grep 'jetbrains.buildServer.agent' >/dev/null; then
            return 0
          else
            echo "PID file ($PID_FILE) contains pid not from TeamCity agent and will be removed."
            rm "$PID_FILE"
            return 1
          fi
        else
          echo "[WARN] Result of check for running TeamCity may be false positive: 'ps' works not as expected"
          return 0
        fi
      ;;
      esac

      # Check that process is TeamCity agent
      # Alternative: pgrep -F "$PID_FILE" -f 'jetbrains.buildServer.agent'
      # Unfortunately AIX, OSX, HP-UX does not support pgrep
      if ps -oargs 1>/dev/null 2>/dev/null; then
        field="args"
      elif ps -ocommand 1>/dev/null 2>/dev/null; then
        field="command"
      else
        echo "[WARN] Result of check for running TeamCity may be false positive: cannot use 'ps', neither 'args' nor 'command' output supported."
        return 0
      fi
      if ps "-o$field" -p "`cat "$PID_FILE"`" 2>/dev/null | grep 'jetbrains.buildServer.agent' >/dev/null; then
        return 0
      else
        echo "PID file ($PID_FILE) contains pid not from TeamCity agent and will be removed."
        rm "$PID_FILE"
        return 1
      fi
    fi
    echo "[ERROR] Unexpected state"
    return 0
}

exit1() {
  cd "$old_cwd"
  exit $1
}

java_exec=""
QUIET=0
need_java() {
    java_hint=""
    if [ -f '../conf/teamcity-agent.jvm' ]; then
      java_hint="`head -n 1 '../conf/teamcity-agent.jvm'`"
      if [ ! -z "$java_hint" ]; then
        java_hint="`dirname \"$java_hint\"`"
        java_hint="`dirname \"$java_hint\"`"
      fi
    fi
    if [ -z "$java_hint" ] || [ ! -d "$java_hint" ]; then
      java_hint=""
    fi

    . ./findJava.sh
    FJ_MIN_UNSUPPORTED_JAVA_VERSION=12
    FJ_SKIP_ALL_EXCEPT_ARGS=1
    # First search only among specified directories
    find_java 1.8 "$TEAMCITY_JRE" "$java_hint" "`pwd`/../jre" "`pwd`/../../jre" >/dev/null 2>&1
    unset FJ_SKIP_ALL_EXCEPT_ARGS
    FJ_LOOK_FOR_X86_JAVA=1
    # Then in all other possible locations for 32bit java 1.8+, arguments are required there as it's covered in previous attempt
    find_java 1.8 >/dev/null 2>&1
    unset FJ_LOOK_FOR_X86_JAVA
    # Then in all other possible locations for any bitness
    find_java 1.8 "$TEAMCITY_JRE" "$java_hint" "`pwd`/../jre" "`pwd`/../../jre";
    if [ $? -ne 0 ]; then
        if [ "$QUIET" -eq 0 ]; then
          echo "Java not found. $1 Please ensure JDK or JRE is installed and JAVA_HOME environment variable points to it."
        fi
        if [ ! -z "$2" ]; then
          exit1 $2
        fi
        exit1 1
    fi
    java_exec="$FJ_JAVA_EXEC"
    if [ "$QUIET" -eq 0 ]; then
      echo "Java executable is found: '$FJ_JAVA_EXEC'"
    fi
    # Cleanup env
    unset FJ_JAVA_EXEC
    unset FJ_JAVA_VERSION
    unset FJ_MIN_UNSUPPORTED_JAVA_VERSION
}

case "$command_name" in
start|run)
        if check_alive ; then
          echo "Build agent is already running with PID `cat $PID_FILE`"
          exit1 1
        fi

        if [ ! -r "$CONFIG_FILE" ]; then
          mkdir ../conf >/dev/null 2>&1
          mv *.properties *.xml *.dtd ../conf >/dev/null 2>&1
        fi

        echo "Starting TeamCity build agent..."

        need_java "Cannot start TeamCity agent."

        mkdir -p $LOG_DIR 2>/dev/null

        # Fix attributes for Mac service launcher (TW-49776, TW-57312)
        chmod +x ../launcher/bin/* 2>/dev/null

        if [ -f ../lib/latest/launcher.jar ]; then
            rm ../lib/launcher.jar
            mv ../lib/latest/launcher.jar ../lib/launcher.jar
            TEAMCITY_LAUNCHER_CLASSPATH="../lib/launcher.jar"            
        fi

        if [ "$TEAMCITY_AGENT_PREPARE_SCRIPT" != "" ]; then
            "$TEAMCITY_AGENT_PREPARE_SCRIPT" "$@"
        fi

        "$java_exec" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Check $TEAMCITY_AGENT_OPTS_ACTUAL jetbrains.buildServer.agent.AgentMain -file $CONFIG_FILE
        check_result="$?"
        if [ "$check_result" != "0" ]; then
           exit1 1;
        fi

        if [ "$command_name" = "start" ]; then
          NOHUP=""
          nohup id >/dev/null 2>&1 && NOHUP=nohup

          $NOHUP "$java_exec" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Launcher $TEAMCITY_AGENT_OPTS_ACTUAL jetbrains.buildServer.agent.AgentMain -file $CONFIG_FILE > "$LOG_DIR/output.log" 2> "$LOG_DIR/error.log" &
          launcher_pid=$!
          echo $launcher_pid > $PID_FILE

          echo "Done [$launcher_pid], see log at `cd $LOG_DIR && pwd`/teamcity-agent.log"

        else
          "$java_exec" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Launcher $TEAMCITY_AGENT_OPTS_ACTUAL jetbrains.buildServer.agent.AgentMain -file $CONFIG_FILE
        fi
        ;;
stop)
   echo "Stopping TeamCity build agent..."

   if [ "$command_sub_name" = "kill" ] ; then
         if check_alive ; then
            echo "Stopping buildAgent [`cat $PID_FILE`]"
            kill `cat $PID_FILE`
            for i in 1 2 3 4 5 6 7 8 9 10; do
              # '!' Negation does not work on Solaris sh. ':' is noop.
              if check_alive; then :;
              else break;
              fi
              sleep 1
            done
            if check_alive; then
              echo "Cannot stop buildAgent"
              exit1 1
            else
              echo "Stopped"
              rm "$PID_FILE"
            fi

         else
            echo "$PID_FILE not found, nothing to stop."
         fi

   else
        check_alive ;

        need_java "Cannot stop TeamCity agent."
         
        LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.
        export LD_LIBRARY_PATH
  
        if [ "$command_sub_name" = "force" ]; then
            FORCE="force"
        fi

        if [ -f ../lib/latest/launcher.jar ]; then
            TEAMCITY_LAUNCHER_CLASSPATH="../lib/latest/launcher.jar"
        fi

        if [ "$TEAMCITY_AGENT_PREPARE_SCRIPT" != "" ]; then
            "$TEAMCITY_AGENT_PREPARE_SCRIPT" "$@"
        fi

        "$java_exec" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -cp $TEAMCITY_LAUNCHER_CLASSPATH jetbrains.buildServer.agent.Stop -file $CONFIG_FILE $FORCE $TEAMCITY_AGENT_OPTS_ACTUAL

        check_result="$?"
        if [ "$check_result" != "0" ]; then
          echo "Cannot stop agent gracefully, you can try to kill agent by '$this_script stop kill' command"
          exit1 1
        fi

   fi
   ;;
status)
    if [ "$2" = "short" ]; then
      QUIET=1
    fi
    ## Simple pid file based checking.
    #if check_alive ; then
    #    echo "Build Agent running with pid [`cat $PID_FILE`]"
    #    exit1 0
    #else
    #    echo "$PID_FILE not found."
    #    exit1 1
    #fi
    need_java "Cannot check TeamCity agent status. " -1

    if [ "$2" != "short" ]; then
      echo "Checking TeamCity build agent status..."
    fi

    if [ -f ../lib/latest/launcher.jar ]; then
        TEAMCITY_LAUNCHER_CLASSPATH="../lib/latest/launcher.jar"
    fi

    if [ "$TEAMCITY_AGENT_PREPARE_SCRIPT" != "" ]; then
        "$TEAMCITY_AGENT_PREPARE_SCRIPT" "$@"
    fi

    TEAMCITY_CONFIGURATOR_JAR="../lib/agent-configurator.jar"
    "$java_exec" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -jar "$TEAMCITY_CONFIGURATOR_JAR" "$@" --agent-config-file "$CONFIG_FILE"
    exit1 $?
   ;;
configure)
    need_java "Cannot configure TeamCity agent. " 1

    echo "Configuring TeamCity build agent..."

    if [ "$TEAMCITY_AGENT_PREPARE_SCRIPT" != "" ]; then
        "$TEAMCITY_AGENT_PREPARE_SCRIPT" "$@"
    fi

    TEAMCITY_CONFIGURATOR_JAR="../lib/agent-configurator.jar"
    "$java_exec" $TEAMCITY_LAUNCHER_OPTS_ACTUAL -jar "$TEAMCITY_CONFIGURATOR_JAR" "$@" --agent-config-file "$CONFIG_FILE"
    exit1 $?
    ;;
*)
        echo "JetBrains TeamCity Build Agent"
        echo "Usage: "
        echo "  $this_script start     - to start build agent in background"
        echo "  $this_script stop      - to stop build agent after current build finish"
        echo " "
        echo "  $this_script run         - to start build agent in the current console"
        echo "  $this_script stop force  - to stop build agent terminating currently running build"
        exit1 1
        ;;
esac

exit1 0
