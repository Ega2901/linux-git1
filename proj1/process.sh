#!/bin/bash


# Принимаем имя файла из аргумента
file="$1"
awk -F, '$12 != -1 && $18 != -1 { print $12, $18 }' <$file > ./file.csv
# Вычисляем среднее значение с использованием awk
rating_avg=$(awk -F, 'NR > 1 && $18 != -1 { sum += $18; count++ } END { if (count > 0) printf "RATING_AVG %.2f\n", sum / count }' $file)
echo "$rating_avg"
hotels_by_country=$(awk -F, 'NR > 1 && $7 != -1 { country=tolower($7); count[country]++ } END { for (c in count) printf "HOTELNUMBER %s %d\n", c, count[c] }' $file)
echo "$hotels_by_country"
cleanliness_by_country=$(awk -F, 'NR > 1 && $7 != -1 && $12 != -1 { country=tolower($7); if (tolower($2) ~ /holiday inn|hilton/) { sum[country] += $12; count[country]++ } } END { for (c in count) printf "CLEANLINESS %s %.2f %.2f\n", c, sum[c] / count[c], sum[c] }' $file)
echo "$cleanliness_by_country"



# Генерируем линейную регрессию и рисуем график
gnuplot_script=$(cat <<'END_GNUPLOT'
set terminal png size 300,400

f(x) = m*x + b
fit f(x) './file.csv' using 1:2 via m, b
set output 'linear_regression_plot.png'
plot './file.csv' using 1:2 title 'Data Points' with points, f(x) title 'fit'
END_GNUPLOT
)

# Сохраняем gnuplot скрипт во временный файл
echo "$gnuplot_script" > gnuplot_script.gp

# Выполняем gnuplot скрипт
gnuplot gnuplot_script.gp

# Удаляем временный файл
rm -f gnuplot_script.gp fit.log file.csv linear_regression_plot.png