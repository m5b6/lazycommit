#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' 
MODEL_PATH="models/llama3.gguf"
COMMIT_LOG="commits.log"

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
    --temp 0.95 \
    --top-k 60 \
    --top-p 0.95 \
    --threads 8 \
    --log-disable 
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

if [ -f "$COMMIT_LOG" ]; then
    commit_count=$(cat "$COMMIT_LOG")
else
    commit_count=0
fi

((commit_count++))

echo $commit_count > "$COMMIT_LOG"

print_divider
print_color "BLUE" "🤖 Generating commit message..."

tag="❮ 🤖 lazycommit #$commit_count ❯"

joke_prompt="SYSTEM: Tell me a joke. LLAMA: OKAY! HERE IT GOES! THE JOKE IS "
joke=$(generate_llama_response "$joke_prompt" 50 | tr -d '\n\r\t`*_' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

commit_message="$tag $joke"
full_commit_message="$commit_message

I have lazily committed $commit_count times"

print_color "GREEN" "✅ Commit message generated:"
echo "Joke: $joke"
echo "Combined: $full_commit_message"

print_divider
print_color "BLUE" "📦 Committing changes..."
git commit -m "$full_commit_message"

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
echo "$full_commit_message"
print_divider