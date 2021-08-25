#!/usr/local/bin/bash
clear #start by cleaning the terminal window
echo $BASH_VERSION

source $(dirname "$0")/myShell.library

function printHelp() {
cat <<EOF
Description:
============
This script exports the full content of a snapshot. The export is stored in the subFolder export and displayed on the screen. For dataformat json it does a prettyPrint, for other formats it is just a text display.

Arguments:
==========
1 - application name
2 - deployable name
3 - dataFormat for the export (json, yaml, xml, ini)

Example:
========
./exportAllData.sh bookKeepingApp2 PRD json

EOF
}

#==========
#   MAIN
#==========

clear #start by cleaning the terminal window
curDTstamp="$(date -u +%s)"
parseMySettingsFile
checkJqInstalled

#== collect settings
checkForHelp $1
getCLArgumentAppName $1
getCLArgumentDeployableName $2
getCLArgumentFormat $3
getCLArgumentExporterName "returnAllData"
echo " ";echo -e "the snapshot content of the \e[92m$deplName\e[39m deployable for application \e[92m${appName}\e[39m has been requested using the exporter \e[92m${expName}\e[39m in \e[92m${expFormat}\e[39m "

#== run the exporter request and collect the result
response=$(curl -s "${sncUrl}/api/sn_cdm/request/export?deployableName=${deplName}&exporterName=${expName}&appName=${appName}&dataFormat=${expFormat}" --request POST --header 'Accept:application/json' --user ${sncUser}:${sncPwd})

#== check if the exporter worked properly.
getRequestResult "export" "${response}"

#== loop until result.state=completed
loopUntilRequestStateComplete "30" "$requestId"

#== get the response
response=$(curl -s "${sncUrl}/api/sn_cdm/response/${requestId}" --request GET --header 'Accept:application/json' --user ${sncUser}:${sncPwd})
outputState=$(echo $response | jq --raw-output '.result.output.state')
if [[ $outputState == "failure" ]]; then
	echo -e "\e[41m!!error\e[49m - output state = failure"
	echo $response | jq .result; echo " ";
	resultError=$(echo $response | jq .result.output.errors)
	if [[ "${resultError}" == *"is not found"* ]];
        then
            echo " "; echo -e "execute the following commands as script include in the \e[33msn_cdm\e[39m scope to create the exporter ${expName}:"; echo " "
			echo -e "\e[33m$(loadDemoData_createExporterScript)\e[39m"; echo " "
            break
    fi
	exit
else
	#== print the result on screen and export in file
	if [[ $expStatus != "failure" ]]; then
		if [ ! -e "export" ]; then
			mkdir export
		fi

		echo " "; echo -e "== the response metadata is : "
		#echo $response

		expExecId=$(echo $response | jq .result.request_id)
		expStatus=$(echo $response | jq .result.state)
		echo " "; echo -e "the exporter execution id is $expExecId and finished with status $expStatus."

		echo " "; echo -e "== the pretty print response  is : "
		echo $response | jq -r '.result.output.exporter_result' > export/exportData.$expFormat
		cat export/exportData.$expFormat
	fi
fi
