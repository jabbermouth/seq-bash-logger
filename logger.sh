#!/bin/bash

echo "Preparing log event for Seq..."

CURRENT_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")
LOG_TITLE="Event on {MachineName}"
LOG_LEVEL=Information

if [ "$SEQ_SERVER" == "" ]; then
SEQ_SERVER="http://host.docker.internal:5341/"
fi

while getopts ":l:t:x:k:f:s:" opt; do
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
    f) LOG_ENTRY=$(cat "$OPTARG")
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

LOG_ENTRY=$(echo -e "$LOG_ENTRY" | sed -e 's/[^ a-zA-Z0-9,._+@%-]/\\&/g' | sed -z 's/\n/LINEFEED/g')

LOG_TEMPLATE='{"@t":"CURRENT_TIME","@l":"LOG_LEVEL","@mt":"LOG_TITLE","@x":"LOG_MESSAGE","MachineName":"HOSTNAME"}'

echo "Applying template"

LOG_TEMPLATE=$(echo -e "$LOG_TEMPLATE" \
    | sed -z "s/CURRENT_TIME/$CURRENT_TIME/g" \
    | sed -z "s/HOSTNAME/$HOSTNAME/g" \
    | sed -z "s/LOG_TITLE/$LOG_TITLE/g" \
    | sed -z "s/LOG_LEVEL/$LOG_LEVEL/g" \
    | sed -z "s/LOG_MESSAGE/$LOG_ENTRY/g")

LOG_TEMPLATE=$(echo -e "$LOG_TEMPLATE" | sed -z 's/LINEFEED/\\n/g')

echo "Posting to Seq..."

CURL_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "X-Seq-ApiKey: $SEQ_API_KEY" -H "Content-Type: application/vnd.serilog.clef" "${SEQ_SERVER%/}/api/events/raw" -d @- << EOF
$LOG_TEMPLATE
EOF
)

echo "Response from Seq: $CURL_RESPONSE"
