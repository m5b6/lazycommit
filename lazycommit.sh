#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' 

MODEL_PATH="models/llama3.gguf"

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

staged_files=$(git diff --cached --name-only | tr '\n' ' ')

if [ -z "$staged_files" ]; then
    print_color "YELLOW" "⚠️ No staged changes found. Please stage your changes using 'git add' first."
    exit 1
fi

print_divider
print_color "BLUE" "🤖 Generating commit message..."

prompt="You are a Git commit message generator. Your ONLY task is to create a single, concise, and informative commit message for the following code changes:
$staged_files
Instructions:
1. The commit message must be in the format: \"[emoji] Brief description - Short explanation\"
2. Use present tense and imperative mood (e.g., \"Add\" not \"Added\" or \"Adds\")
3. Keep the entire message under 50 characters
4. Include one relevant emoji at the start
5. Provide a brief description of what was done, followed by a hyphen and a short explanation or impact
6. Do not include any additional text, explanations, or formatting
Generate only the commit message. Do not include any other text, formatting, line breaks, symbols or explanations in your response."

print_divider
print_color "YELLOW" "Prompt:"
echo "$prompt"
print_divider

commit_message=$(llama \
-m "$MODEL_PATH" \
-p "$prompt" \
-n 15 \
--temp 0.8 \
--top-k 100 \
--top-p 1 \
--threads 8 \
--log-disable \
--no-display-prompt
)

if [ $? -ne 0 ]; then
    print_color "RED" "❌ Error: Failed to generate commit message. Make sure llama is installed and the model path is correct."
    exit 1
fi

print_color "GREEN" "✅ Commit message generated:"
echo "$commit_message"

print_divider
print_color "BLUE" "📦 Committing changes..."
git commit -m "$commit_message"

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
echo "\"$commit_message\""
print_divider