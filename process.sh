#!/bin/bash

# Проверяем наличие аргумента (пути к файлу с датасетом)
if [ -z "$1" ]; then
    echo "Usage: $0 <dataset_file>"
    exit 1
fi

# Переменные для временных файлов
temp_file="/tmp/temp_data.txt"
gnuplot_script="/tmp/gnuplot_script.gp"

# Шаг 1: Вычисление среднего рейтинга (overall_ratingsource)
rating_avg=$(awk -F ',' 'NR>1 && $18!=-1 {sum+=$18; count++} END {if (count>0) print sum/count; else print "N/A"}' "$1")
echo "RATING_AVG $rating_avg"

# Шаг 2: Число отелей в каждой стране
awk -F ',' 'NR>1 && $7!="N/A" {count[tolower($7)]++} END {for (country in count) print "HOTELNUMBER", country, count[country]}' "$1" | sort

# Шаг 3: Средний балл cleanliness по стране для отелей сети Holiday Inn vs. отелей Hilton
awk -F ',' 'NR>1 && $13!=-1 && $18!=-1 && $7!="N/A" {sum[$9 tolower($7)]+=$13; count[$9 tolower($7)]++} END {for (key in sum) print "CLEANLINESS", key, key in count ? sum[key]/count[key] : "N/A"}' "$1"

# Шаг 4: Фильтрация данных для линейной регрессии и сохранение во временный файл
awk -F ',' 'NR>1 && $13!=-1 && $18!=-1 {print $18, $13}' "$1" > "$temp_file"

# Проверка, что временный файл содержит данные
if [ ! -s "$temp_file" ]; then
    echo "Error: No valid data for gnuplot."
    exit 1
fi

# Шаг 5: Запись скрипта gnuplot
cat > "$gnuplot_script" <<EOL
set term png
set output "/tmp/linear_regression_plot.png"
set xlabel "Overall Rating"
set ylabel "Cleanliness"
set title "Линейная регрессия: Чистота vs. Общий рейтинг"
set datafile separator ","
plot "$temp_file" using 1:2 title "Точки данных" with points pointtype 7 pointsize 1.5, \
     "$temp_file" using 1:2 smooth linear title "Линейная регрессия"
EOL

# Шаг 6: Расчет коэффициентов линейной регрессии
gnuplot -e "fit f(x) '$temp_file' using 1:2 via m, b" > /dev/null

# Шаг 7: Вывод коэффициентов линейной регрессии
m=$(grep 'slope' fit.log | awk '{print $3}')
b=$(grep 'intercept' fit.log | awk '{print $3}')
echo "Linear Regression Coefficients:"
echo "Slope (m): $m"
echo "Intercept (b): $b"

# Шаг 8: Запуск gnuplot
gnuplot "$gnuplot_script"

# Очистка временных файлов
rm "$temp_file" "$gnuplot_script" fit.log
