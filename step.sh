#!/bin/bash
set -ex

GREEN='\033[0;32m'
NC='\033[0m'

project_folder=$BITRISE_SOURCE_DIR

cd $project_folder

CURRENT_NIGHTLY_TAGS=( $( git tag -l --sort=committerdate | grep $NIGHTLY_BUILD_TAG_FORMAT ) )

LATEST_NIGHTLY_TAG=${CURRENT_NIGHTLY_TAGS[0]}

date=$(date '+%m-%d-%Y')

[[ -z "$LATEST_NIGHTLY_TAG" ]] && { git tag "$NIGHTLY_BUILD_TAG_FORMAT-$date" && echo "No nightly tags found. Exiting" >&2; exit 1; }

echo "Latest nightly tag found: $LATEST_NIGHTLY_TAG" >&1

RAW_MERGE_LOG=$(git log $LATEST_NIGHTLY_TAG..HEAD --merges)

[[ -z "$RAW_MERGE_LOG" ]] && { echo "No changes detected from last nightly build. Exiting" >&2; exit 1; }

JIRA_TICKETS_ADDRESSED=$(echo $RAW_MERGE_LOG | grep -o '[A-Z][A-Z0-9]\+-[0-9]\+' | awk '!a[$0]++' )

echo -e "${GREEN}Writing out release_notes.md${NC}" >&1
cat > release_notes.md <<EOF
Nightly Build $date
=================================

Relase Notes:
-------------
$(while read -r ticket_id ; do echo "	* https://$JIRA_PROJECT_URL/browse/$ticket_id"; done <<< "$JIRA_TICKETS_ADDRESSED")


Raw Merge Log:
--------------
$(while read -r merge_log ; do echo "	$merge_log"; done <<< "$(git log $LATEST_NIGHTLY_TAG..HEAD --merges --oneline)")
EOF

echo -e "Removing previous nightly tag." >&1
git tag -d $LATEST_NIGHTLY_TAG

echo -e "Writing new nightly tag." >&1
git tag "$NIGHTLY_BUILD_TAG_FORMAT-$date"

echo -e "${GREEN}Exporting release_notes.md.${NC}" >&1
envman add --key RELEASE_NOTES_PATH --value '$project_folder/release_notes.md'
