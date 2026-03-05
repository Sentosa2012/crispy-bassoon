#!/bin/bash

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default configuration file
CONFIG_FILE="config.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES_DIR="$SCRIPT_DIR/modules"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root${NC}"
   exit 1
fi

# Parse command line arguments
while getopts "c:h" opt; do
  case $opt in
    c)
      CONFIG_FILE="$OPTARG"
      ;;
    h)
      echo "Usage: $0 -c config.yml"
      echo "  -c: Configuration file path (default: config.yml)"
      echo "  -h: Show this help message"
      exit 0
      ;;
    *)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

# Check if configuration file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo -e "${RED}Configuration file not found: $CONFIG_FILE${NC}"
  exit 1
fi

# Function to extract YAML values (simple parser)
get_yaml_value() {
  local key="$1"
  local file="$2"
  grep "^$key:" "$file" | sed 's/.*: //' | tr -d '"' | tr -d "'"
}

# Function to check if module is enabled
is_enabled() {
  local section="$1"
  local file="$2"
  local value=$(grep "^$section:" "$file" | sed 's/.*: //' | tr -d '"' | tr -d "'")
  [[ "$value" == "true" ]]
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Ubuntu 24.04 LTS Server Setup${NC}"
echo -e "${GREEN}========================================${NC}"

export CONFIG_FILE SCRIPT_DIR

# Run modules in order
for module in "$MODULES_DIR"/[0-9][0-9]-*.sh; do
  if [[ -f "$module" ]]; then
    module_name=$(basename "$module")
    echo -e "${YELLOW}Running: $module_name${NC}"
    bash "$module"
    if [[ $? -eq 0 ]]; then
      echo -e "${GREEN}✓ $module_name completed${NC}"
    else
      echo -e "${RED}✗ $module_name failed${NC}"
      exit 1
    fi
    echo ""
  fi
done

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
