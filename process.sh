#!/bin/bash

# Check the number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <dataset_file>"
    exit 1
fi

# Dataset file path
dataset_file=$1

# Temporary files for gnuplot and awk
tmp_data_file=$(mktemp /tmp/cleanliness_regression_data.XXXXXX)
output_file="/tmp/regression_plot.png"

# Task 1: Average rating (overall_ratingsource)
rating_avg=$(awk -F',' '{ if ($17 != -1) { sum += $17; count++ } } END { if (count > 0) print "RATING_AVG " sum/count }' $dataset_file)
echo $rating_avg

# Task 2: Number of hotels in each country
hotels_by_country=$(awk -F',' '{ if ($1 != -1) { country=tolower($7); count[country]++ } } END { for (c in count) print "HOTELNUMBER " c " " count[c] }' $dataset_file)
echo "$hotels_by_country"

# Task 3: Average cleanliness score per country for Holiday Inn vs. Hilton
cleanliness_avg=$(awk -F',' '{ if ($1 != -1 && $12 != -1 && $12 != 0) { country=tolower($7); cleanliness=$12; hotel_network=tolower($2); sum[country, hotel_network] += cleanliness; count[country, hotel_network]++ } } END { for (c in count) { split(c, arr, SUBSEP); country = arr[1]; network = arr[2]; avg = sum[c] / count[c]; if (count[country, "holiday inn"] > 0 && count[country, "hilton"] > 0) print "CLEANLINESS " country " " avg " " count[country, "holiday inn"] " " count[country, "hilton"]; } }' $dataset_file)
echo "$cleanliness_avg"

# Task 4: Use gnuplot to calculate linear regression coefficients for cleanliness vs overall_ratingsource
awk -F',' '{ if ($12 != -1 && $17 != -1) print $12, $17 }' $dataset_file > $tmp_data_file

# Task 5: Use awk to calculate average cleanliness and overall_ratingsource
awk -F',' '
BEGIN {
    clean_sum = 0;
    overall_sum = 0;
    clean_count = 0;
    overall_count = 0;
}

{
    if ($12 != -1 && $12 != 0) {
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

# Task 6: Use gnuplot to create a linear regression plot
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

# Cleanup temporary files
rm -f $tmp_data_file
