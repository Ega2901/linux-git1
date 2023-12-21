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
token_file="/home/users/xxxx/github_token" # Поменяйте на ваш путь к токену
cache_dir="$HOME/.github_api_cache"
cache_file_pulls="$cache_dir/pulls_cache.json"
cache_file_earliest="$cache_dir/earliest_cache.json"
cache_file_merged="$cache_dir/merged_cache.json"

# Создать каталог для кэша, если его нет
mkdir -p "$cache_dir"

# Функция для выполнения запроса к Github API и кэширования результата
function github_api_request {
  local url=$1
  local token=$2
  local cache_file=$3

  # Проверяем, есть ли кэш и он не устарел (например, не старше 1 часа)
  if [ -f "$cache_file" ] && [ $(find "$cache_file" -mmin +60) ]; then
    cat "$cache_file"
  else
    if [ -z "$token" ]; then
      curl -s "$url" > "$cache_file"
    else
      curl -s -H "Authorization: token $token" "$url" > "$cache_file"
    fi
    cat "$cache_file"
  fi
}

# Функция для получения числа пулл-реквестов
function get_pulls_count {
  local url="$api_url?state=all&per_page=100&user=$user"
  local token=$(cat "$token_file" 2>/dev/null)
  github_api_request "$url" "$token" "$cache_file_pulls" | jq length
}

# Функция для получения информации о самом раннем пулл-реквесте
function get_earliest_pull {
  local url="$api_url?state=all&per_page=1&user=$user"
  local token=$(cat "$token_file" 2>/dev/null)
  github_api_request "$url" "$token" "$cache_file_earliest" | jq '.[0].number // empty'
}

# Функция для определения флага MERGED
function get_merged_flag {
  local url="$api_url?state=all&per_page=1&user=$user"
  local token=$(cat "$token_file" 2>/dev/null)
  github_api_request "$url" "$token" "$cache_file_merged" | jq -r '.[0].merged // false' | awk '{print "MERGED", $1 ? 1 : 0}'
}

# Вывод результатов
actual_pulls=$(get_pulls_count)
actual_earliest=$(get_earliest_pull)
actual_merged_flag=$(get_merged_flag)

# Ожидаемые значения
expected_pulls=100
expected_earliest=628
expected_merged_flag=1

# Сравнение результатов
echo "Actual PULLS: $actual_pulls, Expected PULLS: $expected_pulls"
echo "Actual EARLIEST: $actual_earliest, Expected EARLIEST: $expected_earliest"
echo "Actual MERGED: $actual_merged_flag, Expected MERGED: $expected_merged_flag"

if [ "$actual_pulls" -eq "$expected_pulls" ]; then
  echo "Number of pull-requests correct"
else
  echo "Number of pull-requests wrong"
fi

if [ "$actual_earliest" -eq "$expected_earliest" ]; then
  echo "Number of earliest request is correct"
else
  echo "Number of earliest request is wrong"
fi

if [ "$actual_merged_flag" -eq "$expected_merged_flag" ]; then
  echo "Merged flag is correct ($actual_merged_flag)"
else
  echo "Merged flag is wrong ($actual_merged_flag vs $expected_merged_flag)"
fi
