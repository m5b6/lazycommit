#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

MODEL_PATH="models/model.gguf"

print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

print_divider() {
    printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
}

if [ ! -f "$MODEL_PATH" ]; then
    print_color "RED" "❌ Error: Model file not found at $MODEL_PATH"
    exit 1
fi

#print_divider
#print_color "BLUE" "🔍 Checking for staged changes..."
#staged_files=$(git diff --cached --name-only | tr '\n' ' ')
#
#if [ -z "$staged_files" ]; then
#    print_color "YELLOW" "⚠️ No staged changes found. Please stage your changes using 'git add' first."
#    exit 1
#fi

#print_color "GREEN" "✅ Found staged changes in the following files:"
#echo "$staged_files"

print_divider
print_color "BLUE" "🤖 Generating commit message..."

prompt="Generate a git commit message for changes in these files: $staged_files. The message must be in this exact format, with no additional text: '[emoji] Changed [files] - [brief description or joke]'. Keep it under 50 characters. Only output the commit message, nothing else."

print_color "YELLOW" "Complete prompt being sent to the model:"
echo "$prompt"

commit_message=$(llama \
-m "$MODEL_PATH" \
-p "$prompt" \
-n 50 \
--temp 0.7 \
--top-k 40 \
--top-p 0.9 \
--repeat-penalty 1.1 \
--repeat-last-n 64 \
--batch-size 512 \
--threads 4 \
--log-disable \
--no-display-prompt
)

if [ $? -ne 0 ]; then
    print_color "RED" "❌ Error: Failed to generate commit message. Make sure llama is installed and the model path is correct."
    exit 1
fi

commit_subject=$(echo "$commit_message" | grep -E '^\[.*\] Changed.*-.*' | head -n 1 | cut -c 1-50)

if [ -z "$commit_subject" ]; then
    print_color "YELLOW" "⚠️ Generated message didn't match expected format. Using a default message."
    commit_subject="🤖 Changed $staged_files - Automatic commit"
fi

print_color "GREEN" "✅ Commit message generated:"
echo "Subject: $commit_subject"

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