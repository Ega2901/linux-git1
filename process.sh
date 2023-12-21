#!/bin/bash

# Шаг 1: Создание временного файла для данных линейной регрессии
temp_file="/tmp/temp_data.txt"

# Шаг 2: Формирование скрипта gnuplot
gnuplot_script="/tmp/gnuplot_script.gp"

# Шаг 3: Вычисление среднего рейтинга
awk -F ',' 'NR>1 && $18!=-1 {sum+=$18; count++} END {if (count>0) print "RATING_AVG", sum/count; else print "RATING_AVG", "N/A"}' "$1"

# Шаг 4: Вычленение страны из поля doc_id и подсчет количества отелей в каждой стране
awk -F ',' 'NR>1 {split($1, parts, "_"); country=tolower(parts[1]); hotel_count[country]++} END {for (c in hotel_count) print "HOTELNUMBER", c, hotel_count[c]}' "$1"

# Шаг 5: Вычисление среднего балла cleanliness по стране для отелей Holiday Inn и Hilton
awk -F ',' 'NR>1 && $13!=-1 {split($1, parts, "_"); country=tolower(parts[1]); if (country == "holidayinn" || country == "hilton") {sum[country]+=$13; count[country]++}} END {for (c in sum) if (count[c]>0) print "CLEANLINESS", c, sum[c]/count[c]}' "$1"

# Шаг 6: Фильтрация данных для линейной регрессии и сохранение во временный файл
awk -F ',' 'NR>1 && $13!=-1 && $18!=-1 {print $18, $13}' "$1" > "$temp_file"

# Проверка, что временный файл содержит данные
if [ ! -s "$temp_file" ]; then
    echo "Error: No valid data for gnuplot."
    exit 1
fi

# Шаг 7: Запись скрипта gnuplot
cat > "$gnuplot_script" <<EOL
set term png
set output "/tmp/linear_regression_plot.png"
set xlabel "Overall Rating"
set ylabel "Cleanliness"
set title "Линейная регрессия: Чистота vs. Общий рейтинг"
set datafile separator ","
f(x) = m*x + b
fit f(x) '$temp_file' using 1:2 via m, b
plot "$temp_file" using 1:2 title "Точки данных" with points pointtype 7 pointsize 1.5, \
     f(x) title "Линейная регрессия"
EOL

# Запуск gnuplot с игнорированием ошибок при вычислении коэффициентов линейной регрессии
gnuplot "$gnuplot_script" 2>/dev/null || true
