#!/bin/bash

# Проверяем, что передан аргумент (ник пользователя на Github)
if [ -z "$1" ]; then
  echo "Usage: $0 <github_username>"
  exit 1
fi

# Задаем переменные
USERNAME="$1"
REPO="datamove/linux-git2"
TOKEN_FILE="/home/Ega2901/public_repo_token"
CACHE_DIR="/home/Ega2901/.github_api_cache"

# Проверяем наличие файла с токеном
if [ ! -f "$TOKEN_FILE" ]; then
  echo "Error: GitHub token file not found. Please create a file at $TOKEN_FILE with your GitHub token."
  exit 1
fi

# Создаем каталог для кэша, если его нет
mkdir -p "$CACHE_DIR"

# Читаем токен из файла
TOKEN=$(cat "$TOKEN_FILE")

# Функция для выполнения запроса API с кэшированием
api_request() {
  local endpoint="$1"
  local cache_file="$CACHE_DIR/$(echo -n "$endpoint" | md5sum | awk '{print $1}')"

  # Проверяем, есть ли кэшированный результат
  if [ -f "$cache_file" ]; then
    cat "$cache_file"
  else
    # Выполняем запрос и кэшируем результат
    curl -s -H "Authorization: token $TOKEN" "$endpoint" > "$cache_file"
    cat "$cache_file"
  fi
}

# Функция для получения количества пулл-реквестов пользователя
get_pulls_count() {
  api_request "https://api.github.com/repos/$REPO/pulls?state=all&creator=$USERNAME" | jq length
}

# Функция для получения номера самого раннего (первого) пулл-реквеста пользователя
get_earliest_pull_number() {
  api_request "https://api.github.com/repos/$REPO/pulls?state=all&creator=$USERNAME" | jq -r '.[0].number'
}

# Функция для проверки, был ли пулл-реквест смержен
is_pull_merged() {
  local pull_number="$1"
  api_request "https://api.github.com/repos/$REPO/pulls/$pull_number" | jq -r '.merged'
}

# Получаем количество пулл-реквестов пользователя
PULLS=$(get_pulls_count)

# Если пулл-реквестов больше 0, обрабатываем их
if [ "$PULLS" -gt 0 ]; then
  # Получаем номер самого раннего (первого) пулл-реквеста пользователя
  EARLIEST=$(get_earliest_pull_number)

  # Проверяем, был ли первый пулл-реквест смержен
  MERGED=$(is_pull_merged "$EARLIEST")

  # Выводим результат
  echo "PULLS $PULLS"
  echo "EARLIEST $EARLIEST"
  echo "MERGED $((MERGED == true))"
else
  # Выводим результат, если пулл-реквестов нет
  echo "PULLS 0"
fi
