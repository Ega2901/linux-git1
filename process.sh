#!/bin/bash

# Проверяем наличие аргумента (пути к файлу с датасетом)
if [ -z "$1" ]; then
    echo "Usage: $0 <dataset_file>"
    exit 1
fi

# Переменные для временных файлов
temp_file="/tmp/temp_data.txt"
gnuplot_script="/tmp/gnuplot_script.gp"

# Шаг 1: Средний рейтинг (overall_ratingsource)
rating_avg=$(awk -F ',' 'NR>1 {sum+=$18; count+=($18!=-1)} END {if (count>0) print sum/count; else print "N/A"}' "$1")
echo "RATING_AVG $rating_avg"

# Шаг 2: Число отелей в каждой стране
awk -F ',' 'NR>1 {count[$7]++} END {for (country in count) print "HOTELNUMBER", tolower(country), count[country]}' "$1" | sort

# Шаг 3: Средний балл cleanliness по стране для отелей сети Holiday Inn vs. отелей Hilton
awk -F ',' 'NR>1 {if ($9=="Holiday Inn" && $13!=-1) {sum_holiday+=$13; count_holiday++} else if ($9=="Hilton" && $13!=-1) {sum_hilton+=$13; count_hilton++}} END {if (count_holiday>0 && count_hilton>0) print "CLEANLINESS", "holidayinn", "hilton", sum_holiday/count_holiday, sum_hilton/count_hilton; else print "N/A", "N/A", "N/A", "N/A"}' "$1"

# Шаг 4: Генерация скрипта gnuplot
cat > "$gnuplot_script" <<EOL
set term png
set output "/tmp/linear_regression_plot.png"
set xlabel "Overall Rating"
set ylabel "Cleanliness"
set title "Linear Regression: Cleanliness vs. Overall Rating"
set datafile separator ","
plot "$temp_file" using 1:2 title "Data Points" with points pointtype 7 pointsize 1.5, \
     "$temp_file" using 1:3 title "Linear Regression" with lines
fit f(x) "$temp_file" using 1:2 via m, b
EOL

# Шаг 5: Фильтрация данных для линейной регрессии и сохранение во временный файл
awk -F ',' 'NR>1 {if ($13!=-1 && $18!=-1) print $18, $13}' "$1" > "$temp_file"

# Шаг 6: Запуск gnuplot
gnuplot "$gnuplot_script"

# Очистка временных файлов
rm "$temp_file" "$gnuplot_script"

