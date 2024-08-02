curl -H "Accept: application/vnd.github.everest-preview+json" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  --request POST --data '{"event_type": "update_data"}' \
  https://api.github.com/repos/nntrn/what-im-reading/dispatches
