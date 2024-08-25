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

generate_llama_response() {
    local prompt="$1"
    local num_tokens="$2"
    llama \
    -m "$MODEL_PATH" \
    -p "$prompt" \
    -n "$num_tokens" \
    --temp 1.1 \
    --top-k 50 \
    --top-p 1 \
    --threads 8 \
    --log-disable \
    --no-display-prompt
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
print_color "BLUE" "🤖 Generating commit message components..."

# Generate emoji
emoji_prompt="Generate a single emoji that best represents changes to these files: $staged_files"
emoji=$(generate_llama_response "$emoji_prompt" 5 | tr -d '[:space:]')

# Generate joke
joke_prompt="Create a short, one-line joke or pun related to these changed files: $staged_files. Keep it under 40 characters."
joke=$(generate_llama_response "$joke_prompt" 15 | tr -d '\n')

# Combine components
commit_message="$emoji $joke"

print_color "GREEN" "✅ Commit message components generated:"
echo "Emoji: $emoji"
echo "Joke: $joke"
echo "Combined: $commit_message"

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