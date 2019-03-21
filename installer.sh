#!/usr/bin/env bash

# this script will copy beluga-cli to /usr/local/bin so that it can be called
# from the command line simply by typing "beluga-cli"

function _spinner() {
    # $1 start/stop
    #
    # on start: $2 display message
    # on stop : $2 process exit status
    #           $3 spinner function pid (supplied from stop_spinner)
    # spinner from https://github.com/tlatsas/bash-spinner/blob/master/spinner.sh

    local on_success="✓"
    local on_fail="✖︎"
    local white="\e[1;37m"
    local green="\e[1;32m"
    local red="\e[1;31m"
    local nc="\e[0m"

    case $1 in
        start)
            # calculate the column where spinner and status msg will be displayed
            let column=$(tput cols)-${#2}-8
            # display message and position the cursor in $column column
            echo -ne ${2}
            printf "%${column}s"

            # start spinner
            i=1
            sp='\|/-'
            delay=${SPINNER_DELAY:-0.15}

            while :
            do
                printf "\b${sp:i++%${#sp}:1}"
                sleep $delay
            done
            ;;
        stop)
            if [[ -z ${3} ]]; then
                echo "spinner is not running.."
                exit 1
            fi

            kill $3 > /dev/null 2>&1

            # inform the user uppon success or failure
            echo -en "\b["
            if [[ $2 -eq 0 ]]; then
                echo -en "${green}${on_success}${nc}"
            else
                echo -en "${red}${on_fail}${nc}"
            fi
            echo -e "]"
            ;;
        *)
            echo "invalid argument, try {start/stop}"
            exit 1
            ;;
    esac
}

function start_spinner {
    # $1 : msg to display
    _spinner "start" "${1}" &
    # set global spinner pid
    _sp_pid=$!
    disown
}

function stop_spinner {
    # $1 : command exit status
    _spinner "stop" $1 $_sp_pid
    unset _sp_pid
}

if [[ ! $SHLVL -gt 2 ]]; then
  echo "checking beluga-cli dependencies..."
  dependencies=(curl ftp openssl)

  for dependitem in ${dependencies[@]}; do
    hash $dependitem 2> /dev/null
    if [[ $? -ne 0 ]]; then
      echo -en "\033[1;33mwarning:\033[0m "
      read -n1 -sp "can't find $dependitem. continue anyway? [y/N] " userresponse
      userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
      while [[ $userresponse != "y" && $userresponse != "n" && $userresponse != "" ]]; do
        read -n1 -s userresponse
        userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
      done
      if [[ $userresponse != "y" ]]; then echo -e "\nok; quitting without installation."; exit 1; fi
      currline="warning: can't find $dependitem. continue anyway? [y/N] "
      for n in $(seq 0 ${#currline}); do
        echo -ne " \b\b"
      done
      echo -e "[\033[1;91m✖︎\033[0m] $dependitem"
      missingitems=("${missingitems[@]} $dependitem")
    else
      echo -e "[\033[1;32m✓\033[0m] $dependitem"
    fi
  done
  echo
elif [[ ! -z "$@" ]]; then
  missingitems=("$@")
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

if [[ -e "/usr/local/bin/beluga-cli" && ! $SHLVL -gt 2 ]]; then
  echo -en "\033[1;33mwarning:\033[0m "
  read -n1 -sp "are you sure you want to overwrite the existing file /usr/local/bin/beluga-cli? [y/N] " userresponse
  userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
  while [[ $userresponse != "y" && $userresponse != "n" && $userresponse != "" ]]; do
    read -n1 -s userresponse
    userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
  done
  if [[ $userresponse == "y" ]]; then
    currline="warning: are you sure you want to overwrite the existing file /usr/local/bin/beluga-cli? [y/N] "
    for n in $(seq 0 ${#currline}); do
      echo -ne " \b\b"
    done
  fi
else
  userresponse="y"
fi

if [[ "$userresponse" == "y" ]]; then
  if [[ -e "$DIR/beluga-cli" && -d "/usr/local/bin" && $PATH =~ "/usr/local/bin" ]]; then
    if [[ -x "$DIR/beluga-cli" ]]; then
      start_spinner "copying beluga-cli to /usr/local/bin"
      sleep 0.1
      cp "$DIR/beluga-cli" /usr/local/bin/beluga-cli >/dev/null 2>/dev/null
      cmd_result=$?
      stop_spinner $cmd_result

      if [[ $cmd_result -ne 0 ]]; then
        echo -e "\033[31;1mfailed:\033[0m problem copying executable to /usr/local/bin.\nare you sure you have permission?"
        exit 1
      else
        if [[ ! -d "$HOME/.beluga-cli/man" ]]; then
          start_spinner "creating .beluga-cli directory"
          sleep 0.1
          mkdir -p "$HOME/.beluga-cli/man" 1>/dev/null 2>&1
          cmd_result=$?
          stop_spinner $cmd_result
        fi

        if [[ ! -f "$HOME/man/beluga-cli.1" ]]; then
          currline="can't find man file. download new copy? [y/N] "
          read -n1 -sp "$currline" userresponse
          userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
          while [[ $userresponse != "y" && $userresponse != "n" && $userresponse != "" ]]; do
            read -n1 -s userresponse
            userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
          done
          if [[ $userresponse == "y" ]]; then
            for n in $(seq 0 ${#currline}); do
              echo -ne " \b\b"
            done
            start_spinner "downloading new copy from GitHub"
            sleep 0.1
            man_status=$(curl -s -r 0-1 https://raw.githubusercontent.com/entrez/beluga-cli/master/man/beluga-cli.1)
            if [[ ! "$man_status" =~ "404: Not Found" ]]; then
              curl -s "https://raw.githubusercontent.com/entrez/beluga-cli/master/man/beluga-cli.1" -o "$HOME/.beluga-cli/man/beluga-cli.1"
              cmd_result=$?
            else
              cmd_result=1
            fi
            stop_spinner $cmd_result
            if [[ $cmd_result -ne 0 ]]; then
              echo -e "\033[31;1mfailed:\033[0m problem downloading new copy from GitHub."
            fi
          fi
        fi

        if [[ -f "$HOME/.beluga-cli/man/beluga-cli.1" && ! -f "/usr/local/share/man/man1/beluga-cli.1" ]]; then
          sysname="$(uname -s)"
          start_spinner "installing manpage"
          sleep 0.1
          ln -s "$HOME/.beluga-cli/man/beluga-cli.1" "/usr/local/share/man/man1/beluga-cli.1"
          cmd_result=$?
          if [[ cmd_result -eq 0 ]]; then
            [[ "$sysname" == "Darwin" ]] && /usr/libexec/makewhatis /usr/local/share/man || mandb -u
            cmd_result=$?
          fi
          stop_spinner $cmd_result
          if [[ $cmd_result -ne 0 ]]; then
            if [[ "$sysname" == "Darwin" ]]; then
              echo -e "\033[31;1mfailed:\033[0m manpage database not updated - try manually running\n\n      /usr/libexec/makewhatis /usr/local/share/man\n"
            else
              echo -e "\033[31;1mfailed:\033[0m manpage database not updated - try manually running\n\n      mandb -u\n"
            fi
          fi
        fi
        echo
        if [[ ${#missingitems[@]} -gt 0 ]]; then
          echo -en "\033[1;33mwarning:\033[0m "
          if [[ ${#missingitems[@]} -gt 1 ]]; then
            echo "before using beluga-cli, install the following dependencies:"
          else
            echo "before using beluga-cli, install the following dependency:"
          fi
          for itemname in ${missingitems[@]}; do
            echo " - $itemname"
          done
          echo -n "also "
        fi
        echo -e "make sure to run \033[37;1mbeluga-cli update\033[0m to ensure you have the most up-to-date version of the utility, and \033[37;1mbeluga-cli config\033[0m to set up your credentials!"

        exit 0
      fi
    else
      start_spinner "changing permissions to make file executable" >&2
      sleep 0.1
      chmod +x "$DIR/beluga-cli"
      cmd_result=$?
      stop_spinner $cmd_result

      if [[ $cmd_result -eq 0 && -x "$DIR/beluga-cli" ]]; then
        eval "$(dirname "$0")/$(basename "$0") ${missingitems[@]}"
        exit $?
      else
        echo -e "\033[31;1maborted:\033[0m couldn't make beluga-cli executable.\ntry \033[1mchmod +x beluga-cli\033[0m manually, then run this script again."
        exit 1
      fi
    fi
  else
    if [[ ! -e "$DIR/beluga-cli" ]]; then
      echo -en "\033[1;33mwarning:\033[0m "
      read -n1 -sp "can't find beluga-cli executable. download new copy? [y/N] " userresponse
      userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
      while [[ $userresponse != "y" && $userresponse != "n" && $userresponse != "" ]]; do
        read -n1 -s userresponse
        userresponse=$(echo "$userresponse" | tr [:upper:] [:lower:])
      done
      if [[ $userresponse == "y" ]]; then
        currline="warning: can't find beluga-cli executable. download new copy? [y/N] "
        for n in $(seq 0 ${#currline}); do
          echo -ne " \b\b"
        done
      fi

      if [[ $userresponse != "y" ]]; then echo -e "\nok; quitting without installation."; exit 1; fi
      start_spinner "downloading new copy from GitHub"
      sleep 0.1
      curl -s "https://raw.githubusercontent.com/entrez/beluga-cli/master/beluga-cli" -o "$DIR/beluga-cli"
      cmd_result=$?
      stop_spinner $cmd_result

      if [[ $cmd_result -eq 0 ]]; then
        eval "$(dirname "$0")/$(basename "$0") ${missingitems[@]}"
        exit $?
      else
        echo -e "\033[31;1mfailed:\033[0m problem downloading new copy from GitHub."
        exit 1
      fi
    elif [[ ! -d "/usr/local/bin" ]]; then
      echo -e "\033[31;1mfailed:\033[0m problem finding /usr/local/bin, does it exist?"
    elif [[ ! $PATH =~ "/usr/local/bin" ]]; then
      echo -e "\033[31;1mfailed:\033[0m intended destination /usr/local/bin not included in \$PATH."
    fi
    exit 1
  fi
else
  echo -e "\nok; quitting without installation."
  exit 1
fi
