#!/bin/bash

# Проверка наличия аргумента
if [ -z "$1" ]; then
    echo "Usage: $0 <github_username>"
    exit 1
fi

# Переменные
github_username=$1
repo_owner="datamove"
repo_name="linux-git2"
cache_dir="$HOME/.github_cache"
api_url="https://api.github.com/repos/$repo_owner/$repo_name/pulls?state=all&per_page=100"
merged_flag=0
earliest_pull_number=""

# Создание каталога для кэша, если не существует
mkdir -p "$cache_dir"

# Функция для получения данных через API с учетом кэша
get_data() {
    local url=$1
    local cache_file="$cache_dir/$(echo -n "$url" | md5sum | cut -d ' ' -f 1)"

    # Используем кэш, если файл существует и не старше 1 часа
    if [ -f "$cache_file" ] && [ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 3600 ]; then
        cat "$cache_file"
    else
        curl -s "$url" > "$cache_file"
        cat "$cache_file"
    fi
}

# Функция для обработки пулл-реквестов
process_pulls() {
    local pulls_url=$api_url

    while [ "$pulls_url" != "null" ]; do
        response=$(get_data "$pulls_url")
        pulls_url=$(echo "$response" | jq -r '.next')

        # Обработка каждого пулл-реквеста
        pulls=$(echo "$response" | jq -r '.[] | select(.user.login == "'"$github_username"'")')
        for pull in $pulls; do
            pull_number=$(echo "$pull" | jq -r '.number')
            merged=$(echo "$pull" | jq -r '.merged')

            # Первый пулл-реквест
            if [ -z "$earliest_pull_number" ]; then
                earliest_pull_number=$pull_number
            fi

            # Проверка смерженности первого пулл-реквеста
            if [ "$pull_number" -eq "$earliest_pull_number" ]; then
                if [ "$merged" == "true" ]; then
                    merged_flag=1
                fi
            fi
        done
    done

    echo "PULLS $pulls_count"
    echo "EARLIEST $earliest_pull_number"
    echo "MERGED $merged_flag"
}

# Получение данных о пулл-реквестах
pulls_data=$(process_pulls)

# Вывод результатов
echo "$pulls_data"
