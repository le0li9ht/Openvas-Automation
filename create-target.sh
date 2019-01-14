#!/bin/bash
#Script for automatic creation of openvas targets

#Create a socket using openvasmd -c sock

re='^[0-9]+$'
#reading the /tmp/hosts file
while IFS='' read -r line || [[ -n "$line" ]]; do

    #parsing each line for IP and hostname
    [ -z "$line" ] && continue
    IP=`echo $line | awk -F  "|" '{print $3}' | awk '{$1=$1};1'`
    hostname=`echo $line | awk -F  "|" '{print $2}' | awk '{$1=$1};1'`

    #variables for future use
    scan_name=$hostname'-'$IP
    port=22

    #Check for special characters
    if [[ $hostname == *['!'@#\$%^\&\;\`*\\\/]* ]] || [[ !($IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$) ]]; then
	echo "Sorry we cannot process the input host file. check once whether any field has special characters like except\n Note: a hostname can have -,_,+ "
        exit
    else
	#Check if target already present
	a=`gvm-cli socket --sockpath /openvas/sock --gmp-username responder --gmp-password 6b5d72eb-682a-4df7-9027-fb719d324f14 -X '<get_targets/>' | if grep -q -w $IP; then echo "found"; fi`
        if [ -z "$a" ]
        then
	  #Create Target
	  #Port_list id=\"9ddce1ae-57e7-11e1-b13c-406186ea4fc5\" represent "All TCP and Nmap 5.51 top 1000 UDP"
	  #Change the ssh_credential id 
          payload="<create_target><name>$scan_name</name><hosts>$IP</hosts><port_list id=\"9ddce1ae-57e7-11e1-b13c-406186ea4fc5\"></port_list><alive_tests>Consider Alive</alive_tests> <ssh_credential id=\"f2a692a7-bc12-4f63-b180-5b3d6aeffe66\"><port>$port</port></ssh_credential></create_target>"
    	  echo $payload >/openvas/file_tmp.xml
    	  gvm-cli socket --sockpath sock --gmp-username responder --gmp-password 6b5d72eb-682a-4df7-9027-fb719d324f14 --log DEBUG file_tmp.xml    
        else
          echo "Target Already Exists"
        fi
	
    fi

done < '/tmp/hosts'
