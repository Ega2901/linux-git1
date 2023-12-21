#!/bin/bash

# Check if gnuplot is installed
if ! command -v gnuplot &> /dev/null; then
    echo "Error: gnuplot is not installed. Please install gnuplot and try again."
    exit 1
fi

# Check if sed and awk are installed
if ! command -v sed &> /dev/null || ! command -v awk &> /dev/null; then
    echo "Error: sed or awk is not installed. Please install sed and awk and try again."
    exit 1
fi

# Create temporary data file
gnuplot_data=$(mktemp /tmp/gnuplot_data.XXXXXX)

# Extract data for linear regression, excluding entries with overall_ratingsource = -1
awk -F, 'NR > 1 && $17 != -1 { printf "%s %s\n", $17, $12 }' "$1" > "$gnuplot_data"

# Check if the data file is not empty
if [ ! -s "$gnuplot_data" ]; then
    echo "Error: No valid data for linear regression. Check the dataset and try again."
    exit 1
fi

# Calculate linear regression coefficients
# Calculate mean of x and y
mean_x=$(awk '{sum_x += $1} END {printf "%.6f", sum_x / NR}' "$gnuplot_data")
mean_y=$(awk '{sum_y += $2} END {printf "%.6f", sum_y / NR}' "$gnuplot_data")

# Check if mean_x is 0 (division by zero will occur)
if [ "$(awk 'BEGIN{print ('"$mean_x"' == 0)}')" -eq 1 ]; then
    echo "Error: Division by zero. Check the dataset for valid values."
    exit 1
fi

# Calculate slope (a) and intercept (b)
slope=$(awk '{sum_xy += ($1 - '"$mean_x"') * ($2 - '"$mean_y"')} \
              {sum_xx += ($1 - '"$mean_x"') * ($1 - '"$mean_x"')} \
           END {printf "%.6f", sum_xy / sum_xx}' "$gnuplot_data")

intercept=$(awk -v m="$mean_x" -v c="$mean_y" -v a="$slope" 'BEGIN {printf "%.6f", c - a * m}' /dev/null)

# Perform linear regression and plot
gnuplot -e "f(x) = $slope*x + $intercept; \
            set xlabel 'Overall Rating'; set ylabel 'Cleanliness'; \
            set title 'Linear Regression: Cleanliness vs Overall Rating'; \
            plot '$gnuplot_data' title 'Data', f(x) title 'Linear Regression' with lines"

# Remove temporary files
rm "$gnuplot_data"

# Путь к файлу датасета
dataset="/home/users/datasets/hotels.csv"

# Пункт 1: Средний рейтинг (overall_ratingsource)
rating_avg=$(awk -F, 'NR > 1 { sum += $17 } END { printf "RATING_AVG %.2f\n", sum / (NR - 1) }' "$dataset")
echo "$rating_avg"

# Пункт 2: Число отелей в каждой стране
hotels_by_country=$(awk -F, 'NR > 1 { country=tolower($7); count[country]++ } END { for (c in count) printf "HOTELNUMBER %s %d\n", c, count[c] }' "$dataset")
echo "$hotels_by_country"

# Пункт 3: Средний балл cleanliness по стране для отелей сети Holiday Inn и отелей Hilton
cleanliness_by_country=$(awk -F, 'NR > 1 { country=tolower($7); if (tolower($3) ~ /holiday inn|hilton/) { sum[country] += $12; count[country]++ } } END { for (c in count) printf "CLEANLINESS %s %.2f %.2f\n", c, sum[c] / count[c], sum[c] }' "$dataset")
echo "$cleanliness_by_country"
