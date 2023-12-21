#!/bin/bash

# Check if gnuplot is installed
if ! command -v gnuplot &> /dev/null; then
    echo "Error: gnuplot is not installed. Please install gnuplot and try again."
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

# Perform linear regression and plot
gnuplot -e "f(x) = a*x + b; fit f(x) '$gnuplot_data' via a, b; \
            set xlabel 'Overall Rating'; set ylabel 'Cleanliness'; \
            set title 'Linear Regression: Cleanliness vs Overall Rating'; \
            plot '$gnuplot_data' title 'Data', f(x) title 'Linear Regression' with lines"

# Remove temporary files
rm "$gnuplot_data"
