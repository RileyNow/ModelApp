#!/usr/local/bin/bash
echo $BASH_VERSION

source myShell.library

function printHelp() {
cat <<EOF
Description:
============
This script gets the data for the latest snapshot for a given application and deployable name
Arguments:
==========
1 - application name
2 - deployable name

Example:
========
./getSnapshotStatus.sh "myApp02" "PRD"

EOF
}

clear #start by cleaning the terminal window

#== read the mySettings.conf file
parseMySettingsFile

#== get the provided arguments settings
checkForHelp $1
getCLArgumentAppName $1
getCLArgumentDeployableName $2

#== perform the request
start=`date +%s`
getDeployableValidationResult "${appName}" "${deplName}"
end=`date +%s`
echo -ne "time was `expr $end - $start` seconds."

echo -e " "; echo "== finished."; echo -e