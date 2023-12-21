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

# Путь к файлу датасета
dataset="$1"

# Пункт 1: Средний рейтинг (overall_ratingsource)
rating_avg=$(awk -F, 'NR > 1 && $17 != -1 { sum += $17; count++ } END { if (count > 0) printf "RATING_AVG %.2f\n", sum / count }' "$dataset")
echo "$rating_avg"

# Пункт 2: Число отелей в каждой стране
hotels_by_country=$(awk -F, 'NR > 1 && $17 != -1 { country=tolower($7); count[country]++ } END { for (c in count) printf "HOTELNUMBER %s %d\n", c, count[c] }' "$dataset")
echo "$hotels_by_country"

# Пункт 3: Средний балл cleanliness по стране для отелей сети Holiday Inn и отелей Hilton
cleanliness_by_country=$(awk -F, 'NR > 1 && $17 != -1 { country=tolower($7); if (tolower($3) ~ /holiday inn|hilton/) { sum[country] += $12; count[country]++ } } END { for (c in count) printf "CLEANLINESS %s %.2f %.2f\n", c, sum[c] / count[c], sum[c] }' "$dataset")
echo "$cleanliness_by_country"

# Extract relevant data for linear regression
data_file=$(mktemp /tmp/linear_regression_data.XXXXXX)
awk -F' ' '{print $2, $3}' <<< "$cleanliness_by_country" > "$data_file"

# Check if the data file is not empty
if [ ! -s "$data_file" ]; then
    echo "Error: No valid data for linear regression. Check the dataset and try again."
    exit 1
fi

# Calculate linear regression coefficients using gnuplot
gnuplot_script=$(mktemp /tmp/gnuplot_script.XXXXXX)
cat <<EOL >"$gnuplot_script"
f(x) = a*x + b
fit f(x) "$data_file" using 1:2 via a, b

set xlabel 'Rating Avg'
set ylabel 'Cleanliness'
set title 'Linear Regression: Cleanliness vs Rating Avg'
plot "$data_file" title 'Data', f(x) title 'Linear Regression' with lines
EOL

gnuplot -persist "$gnuplot_script"

# Remove temporary files
rm "$data_file" "$gnuplot_script"
