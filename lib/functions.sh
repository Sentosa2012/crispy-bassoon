#!/bin/bash

# Common functions library

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging functions
log_info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
  echo -e "${GREEN}[✓]${NC} $*"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $*"
}

# YAML parsing helper - simple implementation
get_yaml_value() {
  local key="$1"
  local file="$2"
  grep "^[[:space:]]*$key:" "$file" | head -1 | sed 's/.*: //' | tr -d '"' | tr -d "'"
}

# Check if section is enabled
is_section_enabled() {
  local section="$1"
  local file="$2"
  
  local value=$(sed -n "/^[[:space:]]*$section:/,/^[[:space:]]*[a-zA-Z]/p" "$file" | \
                grep "^[[:space:]]*enabled:" | head -1 | sed 's/.*: //' | tr -d '"' | tr -d "'")
  
  [[ "$value" == "true" ]]
}

# Validate command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check if running as root
require_root() {
  if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
  fi
}
