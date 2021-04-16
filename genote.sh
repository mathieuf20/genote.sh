#!/bin/sh

print_notes() {
		url=$(grep $1 $PARSED_FILE | awk -F':' '{print $7}')
		curl -G -s "https://www.usherbrooke.ca/genote/application/etudiant/notes.php" \
			--data-urlencode "$url" -b $COOKIE_JAR > $NOTES_FILE$1
	
		echo $(grep $1 $PARSED_FILE | awk -F':' '{printf "%s - %s\n", $2, $1}')
		echo ===========================================================
		sed \
			-e '1,/<table class="zebra"/d' \
			-e '/<\/table>/,$d' \
			-e '/^.*&nbsp.*$/d' \
			-e '/thead>/d' \
			-e '/tbody/d' \
			-e 's/^ *//g' \
			-e 's/<td style.*">/<td>/g' \
			-e '/<\/tr>/d' \
			-e 's/<tr.*>//g' \
			-e 's/<td>//g' \
			-e 's/<\/td>/:/g' $NOTES_FILE$1 | \
		tr '\n' '+' | \
		sed \
			-e 's/^+//g'\
			-e 's/:+/:/g' \
			-e 's/+/\n/g' \
			-e '/^$/d' | \
		awk -F':' '{printf "%-20s | %-10s | %-10s | %-10s \n", $1, $2, $3, $4}'
}

mkdir -p /tmp/genote

#Temporary files used by curl to store cookies and http headers
COOKIE_JAR=/tmp/genote/cookieJar
HEADER_DUMP_DEST=/tmp/genote/headers
LOGIN_FORM=/tmp/genote/loginForm
PARSED_FILE=/tmp/genote/parsed
COURS_FILE=/tmp/genote/cours
NOTES_FILE=/tmp/genote/notes 

# The service to be called, and a url-encoded version (the url encoding isn't perfect, if you're encoding complex stuff you may wish to replace with a different method)
ENCODED_DEST=`echo "https://www.usherbrooke.ca/genote/public/index.php" | perl -p -e 's/([^A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg' | sed 's/%2E/./g' | sed 's/%0A//g'`
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
curl -s -k -b $COOKIE_JAR -c $COOKIE_JAR $CURL_DEST_TRIM

curl -s 'https://www.usherbrooke.ca/genote/application/etudiant/cours.php' \
	-b $COOKIE_JAR > $COURS_FILE

sed \
	-e '1,/<tbody>/d' \
	-e '/<\/tbody>/,$d' \
	-e '/<tr>/d' \
	-e 's/<td class="coursetudiant">/:/g' \
	-e 's/<span.*\/span>//g' $COURS_FILE | \
tr '\n' ' ' | \
sed \
	-e 's/<\/td>/\n/g' \
	-e 's/<a href="//g' \
	-e 's/">Consulter<\/a>//g' | \
tr '\n' ' ' | \
sed \
	-e 's/<\/tr>/\n/g' \
	-e 's/ *:/:/g' \
	-e 's/ (/:/g' \
	-e 's/)//g' | \
sed \
	-e 's/^://g' \
	-e '/notes.php/!d' \
	-e 's/notes.php?//g' |
sort > $PARSED_FILE


if [ "$1" = "all" ]; then
	while read cours
	do
		sigle=$(echo $cours | awk -F':' '{printf "%s - %s\n", $2, $1}')
		print_notes $sigle
		echo
	done < $PARSED_FILE
else
	choice=$(cat $PARSED_FILE  | awk -F':' '{printf "%s - %s\n", $2, $1}' | fzf)
	
	if [ ! -z "$choice" ]; then
		sigle=$(echo $choice | awk '{print $1}')
		print_notes $sigle
	fi
fi

rm -rf /tmp/genote > /dev/null
