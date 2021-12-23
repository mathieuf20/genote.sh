#!/bin/sh

print_cotes_for_trimester() {
	LAST_TRIMESTER_COTES=$(cat $COTES_PROGRAMME_FILE | jq ".bilansTrimestres[${1}].inscriptionsActivitesPedagogiques" | jq -r '.[] | ["\(.codeActivitePedagogique):\(.titreActivitePedagogique):\(.descriptionLien):NOTE\(.note):\(.noteConfirmee)"]')

	echo $LAST_TRIMESTER_COTES | \
		sed \
			-e 's/\[ "//g' \
			-e 's/" \] /\n/g' \
			-e 's/" \]//g' \
			-e 's/:NOTE:/:N\/D:/g' \
			-e 's/:NOTE:/:N\/D:/g' \
			-e 's/NOTE//g' \
			-e 's/false//g' \
			-e 's/true/(Confirmée)/g' | \
		awk -F':' '{printf "%-6s: %-2s %s \n", $1, $4, $5}'
		
	TRIMESTER_MEAN=$(cat $COTES_PROGRAMME_FILE | jq ".bilansTrimestres[${1}].moyenneTrimestrielle" | sed -e 's/"//g' -e 's/\(.*\)1$/Hiver \1/g;s/\(.*\)2$/Été \1/g;s/\(.*\)3$/Automne \1/g')
	if [ "$TRIMESTER_MEAN" != "null" ]
	then
		echo "Moyenne trimestrielle: $TRIMESTER_MEAN/4.3"
	fi
}

mkdir -p /tmp/gecote

#Temporary files used by curl to store cookies and http headers
COOKIE_JAR=/tmp/gecote/cookieJar
HEADER_DUMP_DEST=/tmp/gecote/headers
LOGIN_FORM=/tmp/gecote/loginForm
PARSED_FILE=/tmp/gecote/parsed
PROGRAMMES_FILE=/tmp/gecote/programmes
COTES_PROGRAMME_FILE=/tmp/gecote/cotesProgramme

# The service to be called, and a url-encoded version (the url encoding isn't perfect, if you're encoding complex stuff you may wish to replace with a different method)
ENCODED_DEST=`echo "https://monportail.usherbrooke.ca/api/validate" | perl -p -e 's/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg' | sed 's/%2E/./g' | sed 's/%0A//g'`
CAS_HOSTNAME=cas.usherbrooke.ca

#Authentication details. This script only supports username/password login, but curl can handle certificate login if required
USERNAME=$(pass show udes/username)
PASSWORD=$(pass show udes/password)
#Visit CAS and get a login form. This includes a unique ID for the form, which we will store in CAS_ID and attach to our form submission. jsessionid cookie will be set here
curl -s -k -c $COOKIE_JAR https://$CAS_HOSTNAME/login?service=$ENCODED_DEST > $LOGIN_FORM
CAS_ID=`grep name=.lt $LOGIN_FORM | sed 's/.*value..//' | sed 's/\".*//'`
CAS_EXEC=`grep name=.execution $LOGIN_FORM | sed 's/.*value..//' | sed 's/\".*//'`

if [ "$CAS_ID" = "" ]; then
   echo "Login ticket or execution token is empty."
   exit 1
fi

#Submit the login form, using the cookies saved in the cookie jar and the form submission ID just extracted. We keep the headers from this request as the return value should be a 302 including a "ticket" param which we'll need in the next request
curl -s -k --data "username=$USERNAME&password=$PASSWORD&lt=$CAS_ID&execution=$CAS_EXEC&_eventId=submit" -i -b $COOKIE_JAR -c $COOKIE_JAR https://$CAS_HOSTNAME/login?service=$ENCODED_DEST -D $HEADER_DUMP_DEST -o /dev/null

#Visit the URL with the ticket param to finally set the casprivacy and, more importantly, MOD_AUTH_CAS cookie. Now we've got a MOD_AUTH_CAS cookie, anything we do in this session will pass straight through CAS
CURL_DEST=`grep Location $HEADER_DUMP_DEST | sed 's/Location: //'`

if [ "$CURL_DEST" = "" ]; then
    echo "Cannot login. Check if you can login in a browser using user/pass and the following url: https://$CAS_HOSTNAME/login?service=$ENCODED_DEST"
    exit 1
fi

CURL_DEST_TRIM="$(echo ${CURL_DEST} | sed -e 's/[[:space:]]*$//')"
curl -s -k -b $COOKIE_JAR -c $COOKIE_JAR $CURL_DEST_TRIM > /dev/null

curl -s 'https://monportail.usherbrooke.ca/api/grades/programmes-cheminements' \
	-b $COOKIE_JAR > $PROGRAMMES_FILE

LAST_PROGRAM_INDEX=$(jq -r '.[0].index' $PROGRAMMES_FILE)

curl -s "https://monportail.usherbrooke.ca/api/grades/bulletin-cumulatif/${LAST_PROGRAM_INDEX}" \
	-b $COOKIE_JAR > $COTES_PROGRAMME_FILE

if [ "$1" = "all" ]; then
	TRIMESTER_COUNT=$(cat $COTES_PROGRAMME_FILE | jq '.bilansTrimestres | length')
	for i in $(seq $((TRIMESTER_COUNT - 1)) -1 0)
	do
		TRIMESTER_ID=$(cat $COTES_PROGRAMME_FILE | jq ".bilansTrimestres[$i].trimestre" | sed -e 's/"//g' -e 's/\(.*\)1$/Hiver \1/g;s/\(.*\)2$/Été \1/g;s/\(.*\)3$/Automne \1/g')
		echo "================================\nNotes du trimestre ${TRIMESTER_ID}:"
		print_cotes_for_trimester $i
	done
	CUMULATIVE_MEAN=$(cat $COTES_PROGRAMME_FILE | jq -r '.moyenneCumulative')
	echo "================================\nMoyenne cumulative: ${CUMULATIVE_MEAN}/4.3"
else
	print_cotes_for_trimester ${1-0}
	CUMULATIVE_MEAN=$(cat $COTES_PROGRAMME_FILE | jq -r '.moyenneCumulative')
	echo "================================\nMoyenne cumulative: ${CUMULATIVE_MEAN}/4.3"
fi

rm -rf /tmp/gecote > /dev/null
