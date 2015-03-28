#!/usr/bin/env bash

subject=$1
cmd=$2

if [[ "$AUTH" == "" ]]; then
  AUTH="http://localhost:8080"
fi

shift
shift

if [[ $subject == "" ]] || [[ $cmd == "" ]]; then
  echo "Usage: auth [subject] [command] [arguments]"
  echo "Subjects :"
  echo "- user(s)"
  echo "- session(s)"
  echo
  echo "user commands:"
  echo "- add"
  echo "- get <uid>"
  echo "- edit <uid>"
  echo "- rm <uid>"
  echo
  echo "users commands:"
  echo "- list"
  echo
  echo "session commands:"
  echo "- get <sid>"
  echo "- rm <sid>"
  echo
  echo "sessions commands:"
  echo "- list"
  echo "- clean <age>"
  echo
  exit 2
fi

if [[ "$subject" == "user" ]]; then
  if [[ "$cmd" == "add" ]]; then
    echo -n "username: "; read username
    echo -n "password: "; read password
    domains=""
    while [[ "1" == "1" ]]; do
      echo -n "add domain (empty domain to quit): "; read newdomain
      if [[ "$newdomain" == "" ]]; then
        break
      fi
      if [[ "$domains" == "" ]]; then
        domains="\"$newdomain\""
      else
        domains="$domains,\"$newdomain\""
      fi
    done
    echo -n "enable (default=true): "; read en
    if [[ "$en" == "" ]]; then
      en="true"
    fi
    (
      echo "{"
      echo '  "username": "'"$username"'",'
      echo '  "password": "'"$password"'",'
      echo '  "domains": ['"$domains"'],'
      echo '  "enable": '"$en"''
      echo "}"
    ) | curl -L -XPOST -H 'Content-Type: application/json' -d @- "$AUTH/user"
    echo
  elif [[ "$cmd" == "get" ]]; then
    uid=$1
    if [[ "$uid" == "" ]]; then
      echo "uid is missing"
      exit 1
    fi
    curl -L "$AUTH/user/$uid"
    echo
  elif [[ "$cmd" == "edit" ]]; then
    uid=$1
    if [[ "$uid" == "" ]]; then
      echo "uid is missing"
      exit 1
    fi
    echo -n "field (username|password|domains|enable: "; read field
    if [[ "$field" == "" ]]; then
      echo "field is mandatory"
      exit 1
    fi
    if [[ "$field" == "domains" ]]; then
      domains=""
      while [[ "1" == "1" ]]; do
        echo -n "add domain (empty domain to quit): "; read newdomain
        if [[ "$newdomain" == "" ]]; then
          break
        fi
        if [[ "$domains" == "" ]]; then
          domains="\"$newdomain\""
        else
          domains="$domains,\"$newdomain\""
        fi
      done
      value="$domains"
    else
      echo -n "value: "; read value
    fi
    (
      echo "{"
      if [[ "$field" == "domains" ]]; then
        echo ' "'"$field"'": ['"$value"']'
      elif [[ "$field" == "enable" ]]; then
        echo ' "'"$field"'": '"$value"
      else
        echo ' "'"$field"'": "'"$value"'"'
      fi
      echo "}"
    ) | curl -L -XPUT -H 'Content-Type: application/json' -d @- "$AUTH/user/$uid"
    echo
  elif [[ "$cmd" == "rm" ]]; then
    uid=$1
    if [[ "$uid" == "" ]]; then
      echo "uid is missing"
      exit 1
    fi
    curl -L -XDELETE "$AUTH/user/$uid"
    echo
  else
    echo "'$cmd' is not a valid command"
    exit 1
  fi
elif [[ "$subject" == "users" ]]; then
  if [[ "$cmd" == "list" ]]; then
    curl -L "$AUTH/list/users"
    echo
  else
    echo "'$cmd' is not a valid command"
    exit 1
  fi
elif [[ "$subject" == "session" ]]; then
  if [[ "$cmd" == "get" ]]; then
    sid=$1
    if [[ "$sid" == "" ]]; then
      echo "sid is missing"
      exit 1
    fi
    curl -L "$AUTH/session/$sid"
    echo
  elif [[ "$cmd" == "rm" ]]; then
    sid=$1
    if [[ "$sid" == "" ]]; then
      echo "sid is missing"
      exit 1
    fi
    curl -XDELETE -L "$AUTH/session/$sid"
    echo
  else
    echo "'$cmd' is not a valid command"
    exit 1
  fi
elif [[ "$subject" == "sessions" ]]; then
  if [[ "$cmd" == "list" ]]; then
    curl -L "$AUTH/list/sessions"
  elif [[ "$cmd" == "clean" ]]; then
    age=$1
    if [[ "$age" == "" ]]; then
      echo "age is missing"
      exit 1
    fi
    curl -XGET -L "$AUTH/clean/$age"
    echo
  else
    echo "'$cmd' is not a valid command"
    exit 1
  fi
else
  echo "'$subject' is not a valid subject"
  exit 1
fi

