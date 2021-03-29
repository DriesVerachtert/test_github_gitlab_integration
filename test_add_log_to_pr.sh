#!/bin/bash

set -e
set -x

LATEST_COMMIT_SHA=$(git log -n 1 --pretty=format:%H)
sleep 1
echo LATEST_COMMIT_SHA=${LATEST_COMMIT_SHA}

# should be 139 for cs/test-projects/test_github_gitlab_integration
echo CI_PROJECT_ID=${CI_PROJECT_ID}

echo CI_PIPELINE_ID=${CI_PIPELINE_ID}
sleep 1

# For each job, get just the job name and its id in 1 line. We're interested in ID of the job with name 'job1'.
# First just print the output of the curl for easier debugging
curl --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "https://bbpgitlab.epfl.ch/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs?scope[]=failed&scope[]=success"
sleep 1
# Parse the output and get the ID of job1.
JOB_ID_OF_JOB1=$(curl --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "https://bbpgitlab.epfl.ch/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs?scope[]=failed&scope[]=success" | jq -r '.[] | {job: (.name + " " + (.id|tostring))} ' | jq -r '.[]' | grep job1 | sed 's|.* ||g;')
sleep 1
echo JOB_ID_OF_JOB1=${JOB_ID_OF_JOB1}
sleep 1
# Get the log of job1.
curl --location --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "https://bbpgitlab.epfl.ch/api/v4/projects/${CI_PROJECT_ID}/jobs/${JOB_ID_OF_JOB1}/trace" > log1.txt
sleep 1
echo "==============" Start of cat of log1.txt =============="
cat log1.txt
echo "==============" End of cat of log1.txt =============="
sleep 1
BODY_PART_1='{"public":false,"files":{"job1.txt":'
BODY_LOG_CONTENTS=$( jo content="$(cat log1.txt)" )
BODY_PART_2='}}'

sleep 1

curl -X POST -u "driesverachtert:${GITHUB_API_KEY}" -H "Accept: application/vnd.github.v3+json" https://api.github.com/gists -d "${BODY_PART_1}${BODY_LOG_CONTENTS}${BODY_PART_2}" > create-gist-result.json
sleep 1
cat create-gist-result.json
sleep 1
GIST_RAW_URL=$(cat create-gist-result.json | jq -r '.[0]["files"]["job1.txt"]["raw_url"]')
sleep 1
echo GIST_RAW_URL=${GIST_RAW_URL}


# for debugging, get all data about the PR that contains this commit
curl -s -u "driesverachtert:${GITHUB_API_KEY}" -H "Accept: application/vnd.github.groot-preview+json"  https://api.github.com/repos/BlueBrain/test_github_gitlab_integration/commits/${LATEST_COMMIT_SHA}/pulls 
# just get the comments_url of this PR, so that we can add another comment
COMMENTS_URL=$(curl -s -u "driesverachtert:${GITHUB_API_KEY}" -H "Accept: application/vnd.github.groot-preview+json"  https://api.github.com/repos/BlueBrain/test_github_gitlab_integration/commits/${LATEST_COMMIT_SHA}/pulls | jq -r '.[]["_links"]["comments"]["href"]')

echo COMMENTS_URL=${COMMENTS_URL}

curl -s -u "driesverachtert:${GITHUB_API_KEY}" -X POST -d "{\"body\": \"Job build log of job job1 with ID ${JOB_ID_OF_JOB1} of pipeline ${CI_PIPELINE_ID} triggered by commit ${LATEST_COMMIT_SHA}: ${GIST_RAW_URL} \"}" ${COMMENTS_URL}
