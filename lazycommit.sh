#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

print_divider() {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

print_divider
print_color "BLUE" "🔍 Checking for staged changes..."
staged_changes=$(git diff --cached --unified=0)

if [ -z "$staged_changes" ]; then
    print_color "YELLOW" "⚠️ No staged changes found. Please stage your changes using 'git add' first."
    exit 1
fi

print_color "GREEN" "✅ Found staged changes:"
echo "$staged_changes"

print_divider
print_color "BLUE" "🤖 Generating commit message..."
commit_message=$(llama \
-m model.gguf \
-p "Very short and funny commit message for these changes: $staged_changes" \
-n 12 \
--ctx-size 512 \
--log-disable --no-display-prompt
)

commit_subject=$(echo "$commit_message" | head -n 1 | cut -c 1-50)

print_color "GREEN" "✅ Commit message generated:"
echo "Subject: $commit_subject"
echo "Full message:"
echo "$commit_message"

print_divider
print_color "BLUE" "📦 Committing changes..."
git commit -m "$commit_subject"

print_divider
print_color "BLUE" "🚀 Pushing changes to remote repository..."
if git push; then
    print_color "GREEN" "✅ Changes successfully committed and pushed!"
else
    print_color "RED" "❌ Failed to push changes. Please check your network connection and try again."
    exit 1
fi

print_divider
print_color "GREEN" "🎉 All done! Your changes have been committed and pushed with the following message:"
echo "\"$commit_subject\""
print_divider