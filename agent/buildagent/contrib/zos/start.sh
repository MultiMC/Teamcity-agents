#!/bin/sh
#
# This script was created and contributed by Teradata
#******************************************************************************
# This script should be installed in the TeamCity agent installation folder

# make sure we are in the correct folder
cd `dirname $0`

# set up java
export JRE_HOME=<path to Java installation directory>
export JAVA_HOME=<path to Java installation directory>

# This is used when the agent does an upgrade
export TEAMCITY_AGENT_START_CMD=$PWD/restart.sh

# The agent processes must run in pure unix mode
export _BPX_SHAREAS="NO"

#optional custom path statement
#export PATH=$PATH:$PWD/buildbin

# start the agent
bin/agent.sh $*
