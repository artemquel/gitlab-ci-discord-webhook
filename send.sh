#!/bin/bash

EMBED_COLOR=3066993
STATUS_MESSAGE="Results"
    
oIFS="$IFS"
IFS="/"
declare -a arrIN=($CI_JOB_URL)
IFS="$oIFS"
unset oIFS
    
project=${arrIN[3]}
arrIN[0]=""
arrIN[1]=""
arrIN[2]=""
arrIN[3]=""
    
function join { local IFS="/$1"; shift; echo "$*"; }
    
path=$(join , ${arrIN[@]})
ARTIFACT_URL="https://${project}.gitlab.io/-/${path}/artifacts/$FILENAME"

if [ $# -lt 1 ]; then
  echo -e "WARNING!!\nYou need to pass the WEBHOOK_URL environment variable as the second argument to this script.\nFor details & guide, visit: https://github.com/DiscordHooks/gitlab-ci-discord-webhook" && exit
fi

AUTHOR_NAME="$(git log -1 "$CI_COMMIT_SHA" --pretty="%aN")"
COMMITTER_NAME="$(git log -1 "$CI_COMMIT_SHA" --pretty="%cN")"
COMMIT_SUBJECT="$(git log -1 "$CI_COMMIT_SHA" --pretty="%s")"
COMMIT_MESSAGE="$(git log -1 "$CI_COMMIT_SHA" --pretty="%b")" | sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g'


if [ "$AUTHOR_NAME" == "$COMMITTER_NAME" ]; then
  CREDITS="$AUTHOR_NAME authored & committed"
else
  CREDITS="$AUTHOR_NAME authored & $COMMITTER_NAME committed"
fi

if [ -z $CI_MERGE_REQUEST_ID ]; then
  URL=""
else
  URL="$CI_PROJECT_URL/merge_requests/$CI_MERGE_REQUEST_ID"
fi

TIMESTAMP=$(date --utc +%FT%TZ)

WEBHOOK_DATA='{
		"username": "",
		"avatar_url": "https://gitlab.com/favicon.png",
		"embeds": [ {
			"color": '$EMBED_COLOR',
			"author": {
			"name": "Pipeline #'"$CI_PIPELINE_IID"' '"$STATUS_MESSAGE"' - '"$CI_PROJECT_PATH_SLUG"'",
			"url": "'"$CI_PIPELINE_URL"'",
			"icon_url": "https://gitlab.com/favicon.png"
			},
			"title": "'"$COMMIT_SUBJECT"'",
			"url": "'"$URL"'",
			"description": "'"${COMMIT_MESSAGE//$'\n'/ }"\\n\\n"$CREDITS"'",
			"fields": [
			{
				"name": "Commit",
				"value": "'"[\`$CI_COMMIT_SHORT_SHA\`]($CI_PROJECT_URL/commit/$CI_COMMIT_SHA)"'",
				"inline": true
			},
			{
				"name": "Branch",
				"value": "'"[\`$CI_COMMIT_REF_NAME\`]($CI_PROJECT_URL/tree/$CI_COMMIT_REF_NAME)"'",
				"inline": true
			},
			{
				"name": "Artifacts",
				"value": "'"[\`$CI_JOB_ID\`]($ARTIFACT_URL)"'",
				"inline": true
			}
			],
			"timestamp": "'"$TIMESTAMP"'"
		} ]
	}'

for ARG in "$@"; do
  echo -e "[Webhook]: Sending webhook to Discord...\\n";

  (curl --fail --progress-bar -A "GitLabCI-Webhook" -H Content-Type:application/json -H X-Author:k3rn31p4nic#8383 -d "$WEBHOOK_DATA" "$ARG" \
  && echo -e "\\n[Webhook]: Successfully sent the webhook.") || echo -e "\\n[Webhook]: Unable to send webhook."
done
