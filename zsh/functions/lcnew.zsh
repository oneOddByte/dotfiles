lcnew() {
  if [[ $# -lt 1 ]]; then
    echo 'Usage: lcnew "<problem_name>"'
    return 1
  fi

  local base_dir="$HOME/Dev/grind-101/leetcode"
  local template="$base_dir/template.cpp"

  if [[ ! -f "$template" ]]; then
    echo "Error: template not found at $template"
    return 1
  fi

  local name slug target
  name="$*"
  
  # 1. Convert to lowercase
  # 2. Replace the FIRST space/special char sequence with a hyphen
  # 3. Replace all REMAINING space/special char sequences with underscores
slug=$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/^[^a-z0-9]+//; s/[^a-z0-9]+$//; s/[^a-z0-9]+/-/1; s/[^a-z0-9]+/_/g')


  if [[ -z "$slug" ]]; then
    echo "Error: invalid problem name."
    return 1
  fi

  target="$base_dir/${slug}.cpp"

  if [[ -e "$target" ]]; then
    echo "Error: file already exists: $target"
    return 1
  fi

  cp "$template" "$target" || return 1
  echo "Created: $target"
}
