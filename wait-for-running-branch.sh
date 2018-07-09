#!/bin/bash

if [ "" == "$BRANCHNAME" ]; then
  echo "BRANCHNAME envvar not set";
  exit;
fi

COUNT=0
RESETCOUNT=60 # 5sec retry = Reset the branch after 5 minutes
MAXCOUNT=120  # 5sec retry = Cancel after 10 minutes
SITEWAITCOUNT=30 # 5sec retry = Stop waiting after 2.5 minutes

STATUS=$(curl https://calypso.live/status?branch=$BRANCHNAME 2>/dev/null)

#Curl to start with no matter what
echo "Branch status = $STATUS, running curl https://calypso.live/?branch=$BRANCHNAME"
curl https://calypso.live/?branch=$BRANCHNAME >/dev/null 2>&1

STATUS=$(curl https://calypso.live/status?branch=$BRANCHNAME 2>/dev/null)

echo "Branch status after initial curl = $STATUS https://calypso.live/status?branch=$BRANCHNAME"

until $(echo $STATUS | grep -wqe "Ready\|NeedsPriming" ); do
  if [ $COUNT == $MAXCOUNT ]; then
    echo "Reached maximum allowed wait time, quitting"
    exit 1
  elif [ $COUNT == $RESETCOUNT ]; then
    echo "Reached reset timeout, attempting to reset the branch"
    curl https://calypso.live/?branch=$BRANCHNAME\&reset=true >/dev/null 2>&1
  fi

  # If it's still showing NotBuilt, then curl the branch directly rather than the status endpoint
  if [ "NotBuilt" == "$STATUS" ]; then
    echo "Branch status = $STATUS, running curl https://calypso.live/?branch=$BRANCHNAME"
    curl https://calypso.live/?branch=$BRANCHNAME >/dev/null 2>&1
  fi

  sleep 5
  STATUS=$(curl https://calypso.live/status?branch=$BRANCHNAME 2>/dev/null)
  ((COUNT++))
  echo "Branch status now = $STATUS https://calypso.live/status?branch=$BRANCHNAME"
done

SITE=$(curl https://calypso.live/?branch=$BRANCHNAME 2>/dev/null)
COUNT=0
until ! $(echo $SITE | grep -q "dserve" ); do
  if [ $COUNT == $SITEWAITCOUNT ]; then
    echo "Reached maximum allowed wait time, quitting"
    exit 1
  fi

  echo "Branch status is $STATUS, but site is not up yet. Waiting until it is up."

  ((COUNT++))
  sleep 5
  SITE=$(curl https://calypso.live/?branch=$BRANCHNAME 2>/dev/null)
  STATUS=$(curl https://calypso.live/status?branch=$BRANCHNAME 2>/dev/null)
done
