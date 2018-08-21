#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

cd $project_folder

git fetch --tags

LATEST_NIGHTLY_TAG=$( git ls-remote --tags | grep $nightly_build_tag_format | head -n 1 )

date=$(date '+%m-%d-%Y')

[[ -z "$LATEST_NIGHTLY_TAG" ]] && { git tag "$nightly_build_tag_format-$date" && git push origin "$nightly_build_tag_format-$date" && echo -e "${RED}No nightly tags found. Exiting${NC}" >&1; exit 1; }

echo "Latest nightly tag found: $LATEST_NIGHTLY_TAG" >&1

RAW_MERGE_LOG=$(git log $LATEST_NIGHTLY_TAG..HEAD --merges)

[[ -z "$RAW_MERGE_LOG" ]] && { echo -e "${RED}No changes detected from last nightly build. Exiting${NC}" >&1; exit 1; }

JIRA_TICKETS_ADDRESSED=$(echo $RAW_MERGE_LOG | grep -o '[A-Z][A-Z0-9]\+-[0-9]\+' | awk '!a[$0]++' )

echo -e "${GREEN}Writing out release_notes.md${NC}" >&1
cat > release_notes.md <<EOF
Nightly Build $date
=================================

Relase Notes:
-------------
$(while read -r ticket_id ; do echo "	* https://$jira_project_url/browse/$ticket_id"; done <<< "$JIRA_TICKETS_ADDRESSED")


Raw Merge Log:
--------------
$(while read -r merge_log ; do echo "	$merge_log"; done <<< "$(git log $LATEST_NIGHTLY_TAG..HEAD --merges --oneline)")
EOF

echo -e "Removing previous nightly tag." >&1
git tag -d $LATEST_NIGHTLY_TAG

echo -e "Writing new nightly tag." >&1
git tag "$nightly_build_tag_format-$date"
git push origin "$nightly_build_tag_format-$date"

echo -e "${GREEN}Exporting release_notes.md.${NC}" >&1
envman add --key RELEASE_NOTES_PATH --value '$project_folder/release_notes.md'

echo -e "${GREEN}Adding release_notes.md to artifacts.${NC}" >&1
cp  '$project_folder/release_notes.md' '$BITRISE_DEPLOY_DIR/release_notes.md'