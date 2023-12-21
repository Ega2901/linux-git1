#!/bin/bash

# Проверка наличия аргумента
if [ -z "$1" ]; then
  echo "Укажите ник пользователя на Github в качестве аргумента."
  exit 1
fi

# Переменные
user=$1
repo="datamove/linux-git2"
api_url="https://api.github.com/repos/$repo/pulls"
token_file="/home/Ega2901/public_repo_token"

# Функция для выполнения запроса к Github API
function github_api_request {
  local url=$1
  local token=$2
  if [ -z "$token" ]; then
    curl -s "$url" | jq .
  else
    curl -s -H "Authorization: token $token" "$url" | jq .
  fi
}

# Функция для получения числа пулл-реквестов
function get_pulls_count {
  local url="$api_url?state=all&per_page=100"
  local token=$(cat "$token_file" 2>/dev/null)
  local count=$(github_api_request "$url" "$token" | jq length)
  echo "$count"
}

# Функция для получения информации о самом раннем пулл-реквесте
function get_earliest_pull {
  local url="$api_url?state=all&per_page=1"
  local token=$(cat "$token_file" 2>/dev/null)
  local earliest=$(github_api_request "$url" "$token" | jq '.[0].number // empty')
  echo "$earliest"
}

# Функция для определения флага MERGED
function get_merged_flag {
  local url="$api_url?state=all&per_page=1"
  local token=$(cat "$token_file" 2>/dev/null)
  local merged=$(github_api_request "$url" "$token" | jq '.[0].merged // false')
  if [ "$merged" == "true" ]; then
    echo "MERGED 1"
  else
    echo "MERGED 0"
  fi
}

# Вывод результатов
echo "PULLS $(get_pulls_count)"
echo "EARLIEST $(get_earliest_pull)"
echo "$(get_merged_flag)"

