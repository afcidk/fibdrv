set terminal png
set output 'perf.png'

set xlabel 'number of fibonacci sequences'
set ylabel 'times (ns)

plot 'perf_dbl.out' using 1:2 title "Fast doubling", \
     'perf_dp.out'  using 1:2 title "Dynamic Programming"
