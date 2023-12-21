#!/bin/bash

# Проверка передачи аргумента
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <dataset_file.csv>"
    exit 1
fi

# Шаг 1: Вычисление среднего рейтинга (overall_ratingsource)
awk -F ',' 'NR>1 && $16!=-1 {sum+=$16; count++} END {if (count>0) print "RATING_AVG", sum/count}' "$1"

# Шаг 2: Вычисление числа отелей в каждой стране
awk -F ',' 'NR>1 {split($7, parts, "_"); country=tolower(parts[1]); count[country]++} END {for (c in count) if (count[c]>0) print "HOTELNUMBER", c, count[c]}' "$1"

# Шаг 3: Вычисление среднего балла cleanliness по стране для отелей Holiday Inn vs. отелей Hilton
awk -F ',' 'NR>1 && $13!=-1 {split($1, parts, "_"); country=tolower(parts[2]); if (country == "holiday" || country == "hilton") {sum[country]+=$13; count[country]++}} END {for (c in sum) if (count[c]>0) print "CLEANLINESS", c, sum[c]/count[c]}' "$1"

# Шаг 4: Генерация данных для gnuplot и расчет коэффициентов линейной регрессии
awk -F ',' 'NR>1 && $13!=-1 && $16!=-1 {print $13, $16}' "$1" > /tmp/temp_data.txt
gnuplot -e "input='/tmp/temp_data.txt'; output='/tmp/plot.png'" -c gnuplot_script.gp
