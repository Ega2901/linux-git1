#!/bin/bash

# Проверяем, что передан один аргумент
if [ "$#" -ne 1 ]; then
  echo "Использование: $0 <ник_пользователя_на_GitHub>"
  exit 1
fi

# Получаем аргумент (ник пользователя)
user=$1

# Директория для кэширования ответов API
cache_dir="/home/Ega2901/github_api_cache"
mkdir -p "$cache_dir"

# Функция для получения информации о пулл-реквестах из API GitHub
function get_pulls_info() {
  local page=$1
  local cache_file="$cache_dir/pulls_info_page${page}.json"

  # Если ответ уже закэширован, используем его
  if [ -f "$cache_file" ]; then
    cat "$cache_file"
  else
    # Запрашиваем информацию о пулл-реквестах
    curl -s "https://api.github.com/repos/datamove/linux-git2/pulls?state=all&creator=$user&page=$page" > "$cache_file"
    cat "$cache_file"
  fi
}

# Инициализируем переменные
total_pulls_count=0
earliest_pull_number=""
earliest_pull_merged=""

# Обрабатываем пулл-реквесты по страницам
page=1
while true; do
  pulls_info=$(get_pulls_info "$page")

  # Проверяем, что пользователь существует
  if [[ $(echo "$pulls_info" | jq '.message') == "Not Found" ]]; then
    echo "Пользователь $user не найден на GitHub."
    exit 1
  fi

  # Получаем количество пулл-реквестов на текущей странице
  page_pulls_count=$(echo "$pulls_info" | jq length)

  # Прерываем цикл, если больше нет пулл-реквестов
  if [ "$page_pulls_count" -eq 0 ]; then
    break
  fi

  # Обновляем общее количество пулл-реквестов
  total_pulls_count=$((total_pulls_count + page_pulls_count))

  # Поиск самого раннего пулл-реквеста
  earliest_pull=$(echo "$pulls_info" | jq -r '.[0] | {number: .number, merged: .merged}')

  # Обновляем информацию о самом раннем пулл-реквесте
  if [ -z "$earliest_pull_number" ] || [ "${earliest_pull.number}" -lt "$earliest_pull_number" ]; then
    earliest_pull_number="${earliest_pull.number}"
    earliest_pull_merged="${earliest_pull.merged}"
  fi

  # Увеличиваем счетчик страниц
  page=$((page + 1))
done

# Выводим количество пулл-реквестов
echo "PULLS $total_pulls_count"

# Выводим номер самого раннего пулл-реквеста
echo "EARLIEST $earliest_pull_number"

# Выводим бинарный флаг MERGED
if [ "$earliest_pull_merged" == "true" ]; then
  echo "MERGED 1"
else
  echo "MERGED 0"
fi
