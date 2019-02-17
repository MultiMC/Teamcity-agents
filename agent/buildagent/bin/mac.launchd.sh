#!/bin/sh
# This script requires 'load' or 'unload' parameter

old_cwd=`pwd`
cd `dirname $0`
cd ..
INSTALL_DIR=`pwd`

mkdir logs >/dev/null 2>&1
cd bin

## Fix attributes for service launcher
chmod +x ../launcher/bin/*
chmod +x ./*

exit1() {
  cd "$old_cwd"
  exit $1
}


case "$1" in
upgrade)

  launchctl load jetbrains.teamcity.BuildAgentUpgrade.plist
;;
upgradeend)

  launchctl unload jetbrains.teamcity.BuildAgentUpgrade.plist
;;
load|unload)
  PLIST=jetbrains.teamcity.BuildAgent.plist

  ## Update WorkingDirectory in plist file:
  /usr/libexec/PlistBuddy -c "Set :WorkingDirectory $INSTALL_DIR" $PLIST

  ## fix path to java
  sed -i -e "s/wrapper.java.command=.*/wrapper.java.command=java/" ../launcher/conf/wrapper.conf

  ## Process service load/unload
  launchctl $1 jetbrains.teamcity.BuildAgent.plist

;;
*)
    echo "JetBrains TeamCity Build Agent Mac launchctl starter"
    echo "Usage: "
    echo "  $0 load        - to start build agent deamon"
    echo "  $0 unload      - to stop build agent deamon"
    echo " "
;;
esac

exit1 0
