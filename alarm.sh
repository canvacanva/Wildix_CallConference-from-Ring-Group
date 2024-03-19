#!/bin/bash

#Editare con i dati del centralino e l'ID del gruppo
APIuser='admin'
APIpwd='xxxxxx'
PBX='127.0.0.1'
IDGroup='xx'
UserStart=$1
ConfName='<ConferenzaAllarme>'

APIGroup= curl -u $APIuser:$APIpwd -s -X GET 'http://'$PBX'/api/v1/Dialplan/CallGroups/' | jq -r '.result.records[] | select(.id=='$IDGroup') | .members[]' | cut -c -3 > /tmp/list_call.log
sleep 2
api=$(curl -u $APIuser:$APIpwd -X POST 'http://'$PBX'/api/v1/Originate' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'channel=Local/'$UserStart'@pbxinternal' --data-urlencode 'exten=98123' --data-urlencode 'context=users' --data-urlencode 'context=users' --data-urlencode 'callerid='$ConfName'' --data-urlencode 'async=true')
sleep 2
cat /tmp/list_call.log | while read line || [[ -n $line ]];
	do
	APIDialPlan=$(curl -u $APIuser:$APIpwd -s -X GET 'http://'$PBX'/api/v1/Colleagues/' | jq -r '.result.records[] | select(.extension=="'$line'") | .dialplan')
	APIMobileP=$(curl  -u $APIuser:$APIpwd -s -X GET 'http://'$PBX'/api/v1/Colleagues/' | jq -r '.result.records[] | select(.extension=="'$line'") | .mobilePhone')
	APIName=$(curl -u $APIuser:$APIpwd -s -X GET 'http://'$PBX'/api/v1/Colleagues/' | jq -r '.result.records[] | select(.extension=="'$line'") | .name')
	APIExten=$line
	#echo $APIMobileP
	#sleep 2
	##### verifica se lo user ha la mobility chiamo al cellulare, oppure chiamo interno 
	if [ -z "${APIMobileP}" ]
		then 
		echo $APIName has no mobility extension, call internal
		api=$(curl -u $APIuser:$APIpwd -X POST 'http://'$PBX'/api/v1/Originate' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'channel=Local/'$APIExten'@'$APIDialPlan'' --data-urlencode 'exten=98123' --data-urlencode 'context=users' --data-urlencode 'context=users' --data-urlencode 'callerid='$ConfName'' --data-urlencode 'async=true')
		else
		echo Calling $APIName using mobilty number $APIMobileP with dialan $APIDialPlan
		api=$(curl -u $APIuser:$APIpwd -X POST 'http://'$PBX'/api/v1/Originate' --header 'Content-Type: application/x-www-form-urlencoded' --data-urlencode 'channel=Local/'$APIMobileP'@'$APIDialPlan'' --data-urlencode 'exten=98123' --data-urlencode 'context=users' --data-urlencode 'context=users' --data-urlencode 'callerid='$ConfName'' --data-urlencode 'async=true')
	fi;
done
