#!/bin/bash

COUNT=0
MAXCOUNT=60 # 10 sec retry = Reset the branch after 10 minutes

CALL="curl https://circleci.com/api/v1.1/project/github/Automattic/wp-e2e-tests-for-branches/${CIRCLE_BUILD_NUM}"
STATUS_CALL_1="jq '.steps[] | select(.name==\"Run Tests\") | .actions[] | select(.index==0) | .status'"
STATUS_CALL_2="jq '.steps[] | select(.name==\"Run Tests\") | .actions[] | select(.index==1) | .status'"
STATUS_CALL_3="jq '.steps[] | select(.name==\"Run Tests\") | .actions[] | select(.index==2) | .status'"

STATUS_1=$(eval "${CALL} | ${STATUS_CALL_1}")
STATUS_2=$(eval "${CALL} | ${STATUS_CALL_2}")
STATUS_3=$(eval "${CALL} | ${STATUS_CALL_3}")

echo "Node 1 status: ${STATUS_1}"
echo "Node 2 status: ${STATUS_2}"
echo "Node 3 status: ${STATUS_3}"

until [[ $STATUS_1 == "\"success\"" || $STATUS_1 == "\"failed\"" ]] && [[ $STATUS_2 == "\"success\"" || $STATUS_2 == "\"failed\"" ]] && [[ $STATUS_3 == "\"success\"" || $STATUS_3 == "\"failed\"" ]] ; do
    if [ $COUNT == $MAXCOUNT ]; then
        echo "Reached maximum allowed wait time, quitting"
        echo "Calling endpoint with failed status"
        ./wp-calypso/test/e2e/scripts/notify-webhook.sh failed
        exit 1
    fi
    sleep 10
    STATUS_1=$(eval "${CALL} | ${STATUS_CALL_1}")
    STATUS_2=$(eval "${CALL} | ${STATUS_CALL_2}")
    STATUS_3=$(eval "${CALL} | ${STATUS_CALL_3}")
    ((COUNT++))

    echo "Node 1 status: ${STATUS_1}"
    echo "Node 2 status: ${STATUS_2}"
    echo "Node 3 status: ${STATUS_3}"
done

if [[ $STATUS_1 == "\"failed\"" ]] || [[ $STATUS_2 == "\"failed\"" ]] || [[ $STATUS_3 == "\"failed\"" ]]; then
    echo "Calling endpoint with failed status"
    ./wp-calypso/test/e2e/scripts/notify-webhook.sh failed
else
    echo "Calling endpoint with success status"
    ./wp-calypso/test/e2e/scripts/notify-webhook.sh success
fi