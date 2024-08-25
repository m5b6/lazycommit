#!/bin/bash

staged_changes=$(git diff --cached --name-only | tr '\n' ' ')

commit_message=$(llama \
-m model.gguf \
-p "Generate a concise and informative Git commit message for the following staged changes: $staged_changes" \
-n 128 \
--log-disable --no-display-prompt
)

commit_subject=$(echo "$commit_message" | head -n 1 | cut -c 1-50)

git commit -m "$commit_subject" -m "$commit_message"

git push

echo "Changes committed and pushed with message: $commit_subject"