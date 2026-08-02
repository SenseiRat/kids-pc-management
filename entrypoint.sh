#!/bin/bash

ACTION="$1"
MODE="$2"
TAGS=("${@:3}")

COMMON_ARGS=(
  --inventory inventory
  --user ansible
  --private-key .ansible_private_key
  --vault-password-file .ansible_vault_pass
  sites.yml
  ### -vvv
)

if [[ "$ACTION" == "check" ]]; then
  COMMON_ARGS+=(--check --diff)
elif [[ "$ACTION" != "run" ]]; then
  echo "Usage: $0 <check|run> [limit|skip <tags...>]"
  exit 1
fi

if [[ "$MODE" == "limit" ]]; then
  IFS=,
  COMMON_ARGS+=(--tags "${TAGS[*]}")
  unset IFS
elif [[ "$MODE" == "skip" ]]; then
  IFS=,
  COMMON_ARGS+=(--skip-tags "${TAGS[*]}")
  unset IFS
fi

ansible-playbook "${COMMON_ARGS[@]}"

