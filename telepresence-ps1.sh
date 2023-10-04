#!/usr/bin/env bash

# Telepresence prompt helper for bash/zsh
# Displays current connection status and context
# Greatly inspired by https://github.com/jonmosco/kube-ps1

# Copyright 2023 Alex Gervais. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Debug
[[ -n $DEBUG ]] && set -x

# Default values for the prompt
# Override these values in ~/.zshrc or ~/.bashrc
TELEPRESENCE_PS1_TELEPRESENCE_BINARY="${TELEPRESENCE_PS1_TELEPRESENCE_BINARY:-telepresence}"
TELEPRESENCE_PS1_JQ_BINARY="${TELEPRESENCE_PS1_JQ_BINARY:-jq}"

TELEPRESENCE_PS1_SYMBOL_ENABLE="${TELEPRESENCE_PS1_SYMBOL_ENABLE:-true}"
TELEPRESENCE_PS1_CONNECTION_ENABLE="${TELEPRESENCE_PS1_CONNECTION_ENABLE:-true}"
TELEPRESENCE_PS1_CONTEXT_ENABLE="${TELEPRESENCE_PS1_CONTEXT_ENABLE:-true}"

TELEPRESENCE_PS1_PREFIX="${TELEPRESENCE_PS1_PREFIX-(}"
TELEPRESENCE_PS1_SYMBOL_DEFAULT=${TELEPRESENCE_PS1_SYMBOL_DEFAULT:-$'\u29D3'} # bow tie
TELEPRESENCE_PS1_SYMBOL_PADDING="${TELEPRESENCE_PS1_SYMBOL_PADDING:-false}"
TELEPRESENCE_PS1_SEPARATOR="${TELEPRESENCE_PS1_SEPARATOR-|}"
TELEPRESENCE_PS1_DIVIDER="${TELEPRESENCE_PS1_DIVIDER-:}"
TELEPRESENCE_PS1_SUFFIX="${TELEPRESENCE_PS1_SUFFIX-)}"

TELEPRESENCE_PS1_SYMBOL_COLOR="${TELEPRESENCE_PS1_SYMBOL_COLOR-magenta}"
TELEPRESENCE_PS1_DISCONNECTED_COLOR="${TELEPRESENCE_PS1_DISCONNECTED_COLOR-red}"
TELEPRESENCE_PS1_CONNECTED_COLOR="${TELEPRESENCE_PS1_CONNECTED_COLOR-magenta}"
TELEPRESENCE_PS1_CONTEXT_COLOR="${TELEPRESENCE_PS1_CONTEXT_COLOR-cyan}"
TELEPRESENCE_PS1_BG_COLOR="${TELEPRESENCE_PS1_BG_COLOR}"

# Determine our shell
_telepresence_ps1_shell_type() {
  local _SHELL_TYPE

  if [ "${ZSH_VERSION-}" ]; then
    _SHELL_TYPE="zsh"
  elif [ "${BASH_VERSION-}" ]; then
    _SHELL_TYPE="bash"
  fi
  echo $_SHELL_TYPE
}

_telepresence_ps1_init() {
  case "$(_telepresence_ps1_shell_type)" in
  "zsh")
    _TELEPRESENCE_PS1_OPEN_ESC="%{"
    _TELEPRESENCE_PS1_CLOSE_ESC="%}"
    _TELEPRESENCE_PS1_DEFAULT_BG="%k"
    _TELEPRESENCE_PS1_DEFAULT_FG="%f"
    setopt PROMPT_SUBST
    zmodload -F zsh/stat b:zstat
    zmodload zsh/datetime
    ;;
  "bash")
    _TELEPRESENCE_PS1_OPEN_ESC=$'\001'
    _TELEPRESENCE_PS1_CLOSE_ESC=$'\002'
    _TELEPRESENCE_PS1_DEFAULT_BG=$'\033[49m'
    _TELEPRESENCE_PS1_DEFAULT_FG=$'\033[39m'
    ;;
  esac

  _PS1_RESET_COLOR="${_TELEPRESENCE_PS1_OPEN_ESC}${_TELEPRESENCE_PS1_DEFAULT_FG}${_TELEPRESENCE_PS1_CLOSE_ESC}"
}

_telepresence_ps1_color_fg() {
  local _PS1_FG_CODE
  case "${1}" in
  black) _PS1_FG_CODE=0 ;;
  red) _PS1_FG_CODE=1 ;;
  green) _PS1_FG_CODE=2 ;;
  yellow) _PS1_FG_CODE=3 ;;
  blue) _PS1_FG_CODE=4 ;;
  magenta) _PS1_FG_CODE=5 ;;
  cyan) _PS1_FG_CODE=6 ;;
  white) _PS1_FG_CODE=7 ;;
  # 256
  [0-9] | [1-9][0-9] | [1][0-9][0-9] | [2][0-4][0-9] | [2][5][0-6]) _PS1_FG_CODE="${1}" ;;
  *) _PS1_FG_CODE=default ;;
  esac

  if [[ "${_PS1_FG_CODE}" == "default" ]]; then
    _PS1_FG_CODE="${_TELEPRESENCE_PS1_DEFAULT_FG}"
    return
  elif [[ "$(_telepresence_ps1_shell_type)" == "zsh" ]]; then
    _PS1_FG_CODE="%F{$_PS1_FG_CODE}"
  elif [[ "$(_telepresence_ps1_shell_type)" == "bash" ]]; then
    if tput setaf 1 &>/dev/null; then
      _PS1_FG_CODE="$(tput setaf ${_PS1_FG_CODE})"
    elif [[ $_PS1_FG_CODE -ge 0 ]] && [[ $_PS1_FG_CODE -le 256 ]]; then
      _PS1_FG_CODE="\033[38;5;${_PS1_FG_CODE}m"
    else
      _PS1_FG_CODE="${_TELEPRESENCE_PS1_DEFAULT_FG}"
    fi
  fi
  echo ${_TELEPRESENCE_PS1_OPEN_ESC}${_PS1_FG_CODE}${_TELEPRESENCE_PS1_CLOSE_ESC}
}

_telepresence_ps1_color_bg() {
  local _PS1_BG_CODE
  case "${1}" in
  black) _PS1_BG_CODE=0 ;;
  red) _PS1_BG_CODE=1 ;;
  green) _PS1_BG_CODE=2 ;;
  yellow) _PS1_BG_CODE=3 ;;
  blue) _PS1_BG_CODE=4 ;;
  magenta) _PS1_BG_CODE=5 ;;
  cyan) _PS1_BG_CODE=6 ;;
  white) _PS1_BG_CODE=7 ;;
  # 256
  [0-9] | [1-9][0-9] | [1][0-9][0-9] | [2][0-4][0-9] | [2][5][0-6]) _PS1_BG_CODE="${1}" ;;
  *) _PS1_BG_CODE=$'\033[0m' ;;
  esac

  if [[ "${_PS1_BG_CODE}" == "default" ]]; then
    _PS1_FG_CODE="${_TELEPRESENCE_PS1_DEFAULT_BG}"
    return
  elif [[ "$(_telepresence_ps1_shell_type)" == "zsh" ]]; then
    _PS1_BG_CODE="%K{$_PS1_BG_CODE}"
  elif [[ "$(_telepresence_ps1_shell_type)" == "bash" ]]; then
    if tput setaf 1 &>/dev/null; then
      _PS1_BG_CODE="$(tput setab ${_PS1_BG_CODE})"
    elif [[ $_PS1_BG_CODE -ge 0 ]] && [[ $_PS1_BG_CODE -le 256 ]]; then
      _PS1_BG_CODE="\033[48;5;${_PS1_BG_CODE}m"
    else
      _PS1_BG_CODE="${DEFAULT_BG}"
    fi
  fi
  echo ${_TELEPRESENCE_PS1_OPEN_ESC}${_PS1_BG_CODE}${_TELEPRESENCE_PS1_CLOSE_ESC}
}

_telepresence_ps1_symbol() {
  [[ "${TELEPRESENCE_PS1_SYMBOL_ENABLE}" == false ]] && return

  case "$(_telepresence_ps1_shell_type)" in
  bash)
    if ((BASH_VERSINFO[0] >= 4)) && [[ $'\u29D3' != "\\u29D3" ]]; then
      TELEPRESENCE_PS1_SYMBOL="${TELEPRESENCE_PS1_SYMBOL_DEFAULT}"
    else
      TELEPRESENCE_PS1_SYMBOL=$'\xE2\xA7\x93'
    fi
    ;;
  zsh)
    TELEPRESENCE_PS1_SYMBOL="${TELEPRESENCE_PS1_SYMBOL_DEFAULT}"
    ;;
  *)
    TELEPRESENCE_PS1_SYMBOL="t"
    ;;
  esac

  if [[ "${TELEPRESENCE_PS1_SYMBOL_PADDING}" == true ]]; then
    echo "${TELEPRESENCE_PS1_SYMBOL} "
  else
    echo "${TELEPRESENCE_PS1_SYMBOL}"
  fi
}

_telepresence_ps1_status() {
  local _T_STATUS
  local _T_STATUS_JSON
  local _T_STATUS_USER_DAEMON_STATUS
  local _T_STATUS_USER_CONTEXT

  _T_STATUS_JSON="$(${TELEPRESENCE_PS1_TELEPRESENCE_BINARY} status --output json)"

  if [[ "${TELEPRESENCE_PS1_CONNECTION_ENABLE}" == true ]]; then
    _T_STATUS_USER_DAEMON_STATUS="$(${TELEPRESENCE_PS1_JQ_BINARY} -r .user_daemon.status <<< "${_T_STATUS_JSON}")"
    if [[ "${_T_STATUS_USER_DAEMON_STATUS}" != "Connected" ]]; then
      _T_STATUS+="$(_telepresence_ps1_color_fg $TELEPRESENCE_PS1_DISCONNECTED_COLOR)disconnected${_PS1_RESET_COLOR}"
    else
      _T_STATUS+="$(_telepresence_ps1_color_fg $TELEPRESENCE_PS1_CONNECTED_COLOR)connected${_PS1_RESET_COLOR}"
      if [[ "${TELEPRESENCE_PS1_CONTEXT_ENABLE}" == true ]]; then
        _T_STATUS_USER_CONTEXT="$(${TELEPRESENCE_PS1_JQ_BINARY} -r .user_daemon.kubernetes_context <<< "${_T_STATUS_JSON}")"
        _T_STATUS+="${TELEPRESENCE_PS1_DIVIDER}"
        _T_STATUS+="$(_telepresence_ps1_color_fg $TELEPRESENCE_PS1_CONTEXT_COLOR)${_T_STATUS_USER_CONTEXT}${_PS1_RESET_COLOR}"
      fi
    fi
  fi
  echo $_T_STATUS
}

# Set telepresence-ps1 shell defaults
_telepresence_ps1_init

# Build our prompt
telepresence_ps1() {
  local _PS1

  # Set background Color
  [[ -n "${TELEPRESENCE_PS1_BG_COLOR}" ]] && _PS1+="$(_telepresence_ps1_color_bg ${TELEPRESENCE_PS1_BG_COLOR})"

  # Prefix
  if [[ -z "${TELEPRESENCE_PS1_PREFIX_COLOR:-}" ]] && [[ -n "${TELEPRESENCE_PS1_PREFIX}" ]]; then
    _PS1+="${TELEPRESENCE_PS1_PREFIX}"
  else
    _PS1+="$(_telepresence_ps1_color_fg $TELEPRESENCE_PS1_PREFIX_COLOR)${TELEPRESENCE_PS1_PREFIX}${_PS1_RESET_COLOR}"
  fi

  # Symbol
  _PS1+="$(_telepresence_ps1_color_fg $TELEPRESENCE_PS1_SYMBOL_COLOR)$(_telepresence_ps1_symbol)${_PS1_RESET_COLOR}"

  # Separator
  if [[ -n "${TELEPRESENCE_PS1_SEPARATOR}" ]] && [[ "${TELEPRESENCE_PS1_SYMBOL_ENABLE}" == true ]]; then
    _PS1+="${TELEPRESENCE_PS1_SEPARATOR}"
  fi

  # Status
  _PS1+="$(_telepresence_ps1_status)"

  # Suffix
  if [[ -z "${TELEPRESENCE_PS1_SUFFIX_COLOR:-}" ]] && [[ -n "${TELEPRESENCE_PS1_SUFFIX}" ]]; then
    _PS1+="${TELEPRESENCE_PS1_SUFFIX}"
  else
    _PS1+="$(_telepresence_ps1_color_fg $TELEPRESENCE_PS1_SUFFIX_COLOR)${TELEPRESENCE_PS1_SUFFIX}${_PS1_RESET_COLOR}"
  fi

  # Reset background color if defined
  [[ -n "${TELEPRESENCE_PS1_BG_COLOR}" ]] && _PS1+="${_TELEPRESENCE_PS1_OPEN_ESC}${_TELEPRESENCE_PS1_DEFAULT_BG}${_TELEPRESENCE_PS1_CLOSE_ESC}"

  echo "${_PS1}"
}
