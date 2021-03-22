#!/bin/sh

# ---------------------------------------------------------------------
# TeamCity build agent installation script
# ---------------------------------------------------------------------
# Parameters:
#
# $1 required: TeamCity Server URL
# $2 required: Authorization token. Must be "-1" if no auto registration required
# $3 optional: Agent account
# $4 optional: Account password
# 
# ---------------------------------------------------------------------

TC_SERVER_URL="$1"
TC_AUTH_TOKEN="$2"
TC_AA_USERNAME="$3"
TC_AA_PASSWORD="$4"

echo "Installing TeamCity Agent for $TC_SERVER_URL"
if [ -z "$TC_SERVER_URL" ]; then
  echo "usage $0 <TC Server URL>" >&2
  exit 1
fi

##
# looking for Java 
##
echo "Looking for Java Runtime Environment..."
chmod +x findJava.sh
. ./findJava.sh
FJ_MIN_UNSUPPORTED_JAVA_VERSION=12
find_java 1.6 "`pwd`/../jre" ;
if [ $? -ne 0 ]; then
  echo "Cannot install the Agent due to JRE is not found. Please install JRE or JDK first."
  exit 1
fi
 
##
# setup Agent properties 
##
echo "Configuring the Agent's properties..."
cat ../conf/buildAgent.dist.properties | sed '/serverUrl=/ c\
serverUrl='"$TC_SERVER_URL"'' > ../conf/buildAgent.properties

# set authorization token if auto registration requested
if [ "$TC_AUTH_TOKEN" != "-1" ]; then
  printf "\n%b\n" "agent.push.auth.key=$TC_AUTH_TOKEN" >> ../conf/buildAgent.properties
fi 

##
# start agent 
##
chmod +x agent.sh
pwd
if [ -n "$TC_AA_USERNAME" ]; then
  echo "Starting the Agent under '$TC_AA_USERNAME' account..."
  echo $TC_AA_PASSWORD|su $TC_AA_USERNAME -c "nohup ./agent.sh start"
else
  echo "Starting the Agent under '`whoami`' account..."
  nohup ./agent.sh start
fi 
echo WARNING: The TeamCity Agent installed as standalone application and will not start automatically on machine reboot.
exit 0


