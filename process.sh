#!/usr/bin/awk -f

# Проверка наличия аргумента
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <dataset_file>"
    exit 1
fi

# Путь к файлу с датасетом
dataset_file=$1

# Временные файлы для gnuplot и awk
tmp_data_file=$(mktemp /tmp/cleanliness_regression_data.XXXXXX)
output_file="/tmp/regression_plot.png"

# Задача 1: Средний рейтинг (overall_ratingsource)
rating_avg=$(awk -F',' '{ if ($17 != -1) { sum += $17; count++ } } END { if (count > 0) print "RATING_AVG " sum/count }' $dataset_file)
echo $rating_avg

# Задача 2: Число отелей в каждой стране
hotels_by_country=$(awk -F',' '{ if ($1 != -1) { country=tolower($7); count[country]++ } } END { for (c in count) print "HOTELNUMBER " c " " count[c] }' $dataset_file)
echo "$hotels_by_country"

# Задача 3: Средний балл cleanliness по стране для отелей Holiday Inn vs. Hilton
cleanliness_avg=$(awk -F',' '{ if ($1 != -1 && $12 != -1) { country=tolower($7); cleanliness=$12; hotel_network=tolower($2); sum[country, hotel_network] += cleanliness; count[country, hotel_network]++ } } END { for (c in count) { split(c, arr, SUBSEP); country = arr[1]; network = arr[2]; avg = sum[c] / count[c]; if (count[country, "holiday inn"] > 0 && count[country, "hilton"] > 0) print "CLEANLINESS " country " " avg " " count[country, "holiday inn"] " " count[country, "hilton"]; } }' $dataset_file)
echo "$cleanliness_avg"

# Задача 4: Используя gnuplot рассчитайте коэффициенты линейной регрессии для cleanliness от overall_ratingsource
awk -F',' '{ if ($12 != -1 && $17 != -1) print $12, $17 }' $dataset_file > $tmp_data_file

# Задача 5: Используя awk рассчитайте среднее значение cleanliness и overall_ratingsource
awk -F',' '
BEGIN {
    clean_sum = 0;
    overall_sum = 0;
    clean_count = 0;
    overall_count = 0;
}

{
    if ($12 != -1) {
        clean_sum += $12;
        clean_count++;
    }

    if ($17 != -1) {
        overall_sum += $17;
        overall_count++;
    }
}

END {
    if (clean_count > 0) {
        clean_avg = clean_sum / clean_count;
        print "CLEAN_AVG " clean_avg;
    }

    if (overall_count > 0) {
        overall_avg = overall_sum / overall_count;
        print "OVERALL_AVG " overall_avg;
    }
}
' $dataset_file

gnuplot <<EOF
set terminal pngcairo enhanced font 'Verdana,12' size 800,600
set output "$output_file"

set title "Linear Regression: Cleanliness vs Overall Rating"
set xlabel "Overall Rating"
set ylabel "Cleanliness"

f(x) = a * x + b
fit f(x) "$tmp_data_file" using 1:2 via a, b

plot "$tmp_data_file" using 1:2 with points title "Data Points", \
     f(x) with lines title sprintf("Regression Line: y = %.2fx + %.2f", a, b)
EOF

echo "Regression plot saved to: $output_file"

# Удаление временных файлов
rm -f $tmp_data_file
