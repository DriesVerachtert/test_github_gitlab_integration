#!/bin/bash

set -e
set -x

LATEST_COMMIT_SHA=$(git log -n 1 --pretty=format:%H)
echo LATEST_COMMIT_SHA=${LATEST_COMMIT_SHA}

# should be 139 for cs/test-projects/test_github_gitlab_integration
echo CI_PROJECT_ID=${CI_PROJECT_ID}

echo CI_PIPELINE_ID=${CI_PIPELINE_ID}


# For each job, get just the job name and its id in 1 line. We're interested in ID of the job with name 'job1'.
# First just print the output of the curl for easier debugging
curl --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "https://bbpgitlab.epfl.ch/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs?scope[]=failed&scope[]=success"
# Parse the output and get the ID of job1.
JOB_ID_OF_JOB1=$(curl --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "https://bbpgitlab.epfl.ch/api/v4/projects/${CI_PROJECT_ID}/pipelines/${CI_PIPELINE_ID}/jobs?scope[]=failed&scope[]=success" | jq -r '.[] | {job: (.name + " " + (.id|tostring))} ' | grep job1 | sed 's|.* ||g;')

echo JOB_ID_OF_JOB1=${JOB_ID_OF_JOB1}

# Get the log of job1.
curl --location --header "PRIVATE-TOKEN: ${GITLAB_PRIVATE_TOKEN}" "https://gitlab.example.com/api/v4/projects/${CI_PROJECT_ID}/jobs/${JOB_ID_OF_JOB1}/trace" > log1.txt

echo "==============" Start of cat of log1.txt =============="
cat log1.txt
echo "==============" End of cat of log1.txt =============="


curl -s -u 'driesverachtert:${GITHUB_API_KEY}' -H "Accept: application/vnd.github.groot-preview+json"  https://api.github.com/repos/BlueBrain/test_github_gitlab_integration/commits/${LATEST_COMMIT_SHA}/pulls | jq -r '.[]["_links"]["comments"]["href"]'


# curl -s -u 'driesverachtert:${GITHUB_API_KEY}' -X POST -d '{"body": "test message"}' https://api.github.com/repos/BlueBrain/test_github_gitlab_integration/issues/3/comments
