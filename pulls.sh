#!/bin/bash

# Проверяем, что передан один аргумент
if [ "$#" -ne 1 ]; then
  echo "Использование: $0 <ник_пользователя_на_GitHub>"
  exit 1
fi

# Получаем аргумент (ник пользователя)
user=$1

# Директория для кэширования ответов API GitHub
cache_dir="/home/ubuntu/aimasters-checkers/hws/linux4/Ega2901/43/github_api_cache"
mkdir -p "$cache_dir"

# Директория для записи результатов
result_dir="/home/ubuntu/aimasters-checkers/hws/linux4/Ega2901/43/results"
mkdir -p "$result_dir"

# Директория для клонирования репозитория
repo_dir="/home/ubuntu/aimasters-checkers/hws/linux4/Ega2901/43/linux-git1"
mkdir -p "$repo_dir"

# Устанавливаем правильного владельца для директорий
chown -R ubuntu:ubuntu "/home/ubuntu/aimasters-checkers/hws/linux4/Ega2901/43"

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

# Клонируем репозиторий, если еще не склонирован
if [ ! -d "$repo_dir/.git" ]; then
  git clone https://github.com/datamove/linux-git2.git "$repo_dir"
fi

# Переходим в директорию с репозиторием
cd "$repo_dir" || exit 1

# Обновляем репозиторий
git pull origin main

# Инициализируем переменные
total_pulls_count=0
earliest_pull_number=""
earliest_pull_merged=""

# Обрабатываем пулл-реквесты по страницам
page=1
while true; do
  pulls_info=$(get_pulls_info "$page")

  # Проверяем, что пользователь существует
  if [ "$(echo "$pulls_info" | jq '.[0].message')" == "Not Found" ]; then
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

  # Поиск самого раннего пулл-реквеста на текущей странице
  earliest_pull=$(echo "$pulls_info" | jq -r 'sort_by(.created_at) | .[0] | {number: .number, merged: .merged}')

  # Обновляем информацию о самом раннем пулл-реквесте
  if [ -n "$earliest_pull" ]; then
    earliest_pull_number=$(echo "$earliest_pull" | jq -r '.number')
    earliest_pull_merged=$(echo "$earliest_pull" | jq -r '.merged')
  fi

  # Увеличиваем счетчик страниц
  page=$((page + 1))
done

# Выводим результаты через стандартный вывод
echo "PULLS $total_pulls_count"
if [ -n "$earliest_pull_number" ]; then
  echo "EARLIEST $earliest_pull_number"
  if [ "$earliest_pull_merged" == "true" ]; then
    echo "MERGED 1"
  else
    echo "MERGED 0"
  fi
else
  echo "EARLIEST N/A"
  echo "MERGED 0"
fi > "$result_dir/results.log"
