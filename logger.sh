#!/bin/bash

echo "Preparing log event for Seq..."

CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")
LOG_TITLE="Event on {MachineName}"
LOG_LEVEL=Information
LOG_ORIGIN="Bash-based Seq injection script"

if [ "$SEQ_SERVER" == "" ]; then
SEQ_SERVER="http://host.docker.internal:5341/"
fi

while getopts ":l:t:x:k:f:s:o:" opt; do
  case $opt in
    l) LOG_LEVEL="$OPTARG"
    ;;
    t) LOG_TITLE="$OPTARG"
    ;;
    x) LOG_ENTRY="$OPTARG"
    ;;
    s) SEQ_SERVER="$OPTARG"
    ;;
    k) SEQ_API_KEY="$OPTARG"
    ;;
    k) LOG_ORIGIN="$OPTARG"
    ;;
    #f) LOG_ENTRY=$(cat "$OPTARG")
    f) LOG_FILE="$OPTARG"
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

echo "Populating template"

LOG_TEMPLATE_START="{\"@t\":\"$CURRENT_TIME\",\"@l\":\"$LOG_LEVEL\",\"@mt\":\"$LOG_TITLE\",\"@x\":\""
LOG_TEMPLATE_END="\",\"MachineName\":\"$HOSTNAME\",\"Source\":\"$LOG_ORIGIN\"}"

echo "Preparing event to post to Seq..."

echo -n $LOG_TEMPLATE_START > /request.txt
if [ "$LOG_FILE" == "" ]; then
echo -e "$LOG_ENTRY" | sed -e 's/[^ a-zA-Z0-9_.=-]/\\\\&/g' >> /request.txt

else

sed -i 's/\/\\"/g' $LOG_FILE
sed -i 's/"/\\"/g' $LOG_FILE
sed -i ':a;N;$!ba;s/\r\n/\\n/g' $LOG_FILE
sed -i ':a;N;$!ba;s/\n/\\n/g' $LOG_FILE

cat $LOG_FILE >> /request.txt
fi
echo -n $LOG_TEMPLATE_END >> /request.txt

echo "Posting to Seq..."

CURL_RESPONSE=$(curl -s -w "%{http_code}" -X POST -H "X-Seq-ApiKey: $SEQ_API_KEY" -H "Content-Type: application/vnd.serilog.clef" "${SEQ_SERVER%/}/api/events/raw" -d @/request.txt)

echo "Response from Seq: $CURL_RESPONSE"
