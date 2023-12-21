#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <dataset_file.csv>"
    exit 1
fi

# Step 1: Calculate the average rating (overall_ratingsource)
awk -F ',' 'NR>1 && $16!=-1 {sum+=$16; count++} END {if (count>0) print "RATING_AVG", sum/count}' "$1"

# Step 2: Calculate the number of hotels in each country
awk -F ',' 'NR>1 {split($7, parts, "_"); country=tolower(parts[1]); count[country]++} END {for (c in count) if (count[c]>0) print "HOTELNUMBER", c, count[c]}' "$1"

# Step 3: Calculate the average cleanliness score per country for Holiday Inn and Hilton
awk -F ',' 'NR>1 && $13!=-1 {split($1, parts, "_"); country=tolower(parts[2]); if (country == "holiday" || country == "hilton") {sum[country]+=$13; count[country]++}} END {for (c in sum) if (count[c]>0) print "CLEANLINESS", c, sum[c]/count[c]}' "$1"

# Step 4: Generate data for gnuplot and calculate linear regression coefficients
awk -F ',' 'NR>1 && $13!=-1 && $16!=-1 {print $13, $16}' "$1" > /tmp/temp_data.txt
gnuplot -e "input='/tmp/temp_data.txt'; output='/tmp/plot.png'" - <<'EOF'
    f(x) = m*x + b
    fit f(x) input via m, b
    plot input with points pointtype 7 pointsize 1.5, f(x) title "Linear Regression"
EOF
