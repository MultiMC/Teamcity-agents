#!/bin/sh
#
# This script was created and contributed by Teradata
#******************************************************************************
# This script should be installed in the TeamCity agent installation folder

#This script is used by the upgrade process to re-start the agent
echo Custom Start

# make sure we are in the correct folder
cd `dirname $0`

#After the upgrade the agent.sh file is overlaid with an ascii version
#We must re-convert it back to ebcdic
iconv -f ISO8859-1 -t IBM-1047 update/bin/agent.sh > bin/agent.sh
iconv -f ISO8859-1 -t IBM-1047 update/bin/findJava.sh > bin/findJava.sh

#start the agent
agent.sh start
