#!/bin/bash

# Проверяем, передан ли файл с датасетом в аргументах
if [ "$#" -ne 1 ]; then
    echo "Использование: $0 <путь_к_файлу_датасета>"
    exit 1
fi

# Путь к файлу датасета
dataset="$1"

# Создаем временный файл для gnuplot в /tmp
gnuplot_data=$(mktemp /tmp/gnuplot_data.XXXXXX)

# Извлекаем данные для линейной регрессии, исключая записи с overall_ratingsource = -1
awk -F, 'NR > 1 && $17 != -1 { printf "%s %s\n", $17, $12 }' "$dataset" > "$gnuplot_data"

# Вычисляем коэффициенты линейной регрессии
regression_coefficients=$(gnuplot -e "f(x) = a*x + b; fit f(x) '$gnuplot_data' via a, b; print a, b")

# Извлекаем коэффициенты из вывода
slope=$(echo "$regression_coefficients" | awk '{print $1}')
intercept=$(echo "$regression_coefficients" | awk '{print $2}')

# Генерируем скрипт для gnuplot
gnuplot_script=$(mktemp /tmp/gnuplot_script.XXXXXX)
echo "set xlabel 'Overall Rating'" > "$gnuplot_script"
echo "set ylabel 'Cleanliness'" >> "$gnuplot_script"
echo "set title 'Linear Regression: Cleanliness vs Overall Rating'" >> "$gnuplot_script"
echo "plot '$gnuplot_data' title 'Data', $slope*x + $intercept title 'Linear Regression' with lines" >> "$gnuplot_script"

# Имя файла для сохранения графика в /tmp
output_file=$(mktemp /tmp/linear_regression_plot.XXXXXX.png)

# Запускаем gnuplot
gnuplot -p "$gnuplot_script"

# Удаляем временные файлы
rm "$gnuplot_data" "$gnuplot_script"

# Перемещаем график в /tmp
mv "linear_regression_plot.png" "$output_file"

echo "График сохранен в файл: $output_file"
