#!/usr/bin/env bash

# this script will copy beluga-cli to /usr/local/bin so that it can be called
# from the command line simply by typing "beluga-cli"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [[ -e "/usr/local/bin/beluga-cli" && ! $SHLVL -gt 2 ]]; then
  echo -e "a file named beluga-cli already exists in /usr/local/bin.\nare you sure you want to overwrite it?"
  read -n1 -sp "overwrite? [y/N] " overwrite_response
  while [[ $overwrite_response != "y" && $overwrite_response != "n" && $overwrite_response != "" ]]; do
    read -n1 -s overwrite_response
  done
  echo
else
  overwrite_response="y"
fi

if [[ $overwrite_response == "y" ]]; then
  if [[ ! -z $(ls $DIR | grep beluga-cli ) && -d "/usr/local/bin" && $PATH =~ "/usr/local/bin" ]]; then
    if [[ -x "$DIR/beluga-cli" ]]; then
      cp "$DIR/beluga-cli" /usr/local/bin/beluga-cli >&2
      cmd_result=$?
      if [[ $cp_result -ne 0 ]]; then
        echo -e "\033[31;1mfailed:\033[0m problem copying executable to /usr/local/bin.\nare you sure you have permission?"
        exit 1
      else
        echo -e "\033[92;1mdone.\033[0m"
        exit 0
      fi
    else
      chmod +x "$DIR/beluga-cli" >&2
      cmd_result=$?

      if [[ $cmd_result -eq 0 && -x "$DIR/beluga-cli" ]]; then
        eval "$(dirname "$0")/$(basename "$0")"
        exit $?
      else
        echo -e "\033[31;1maborted:\033[0m couldn't make beluga-cli executable.\ntry \033[1mchmod +x beluga-cli\033[0m manually, then run this script again."
        exit 1
      fi
    fi
  else
    if [[ -z $(ls $DIR | grep beluga-cli ) ]]; then
      echo -e "\033[31;1maborted:\033[0m can't find beluga-cli executable"
    elif [[ ! -d "/usr/local/bin" ]]; then
      echo -e "\033[31;1mfailed:\033[0m problem finding /usr/local/bin, does it exist?"
    elif [[ ! $PATH =~ "/usr/local/bin" ]]; then
      echo -e "\033[31;1mfailed:\033[0m intended destination /usr/local/bin not included in \$PATH."
    fi
    exit 1
  fi
fi
