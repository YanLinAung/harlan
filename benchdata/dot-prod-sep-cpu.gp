set term pdfcairo font ",12"
set output "dot-prod-sep-cpu.pdf"

set ylab "Execution time (�s)
set xlab "Vector size"

set key off
set xtics 0,2500000

plot 'dot-prod-sep-cpu.dat' using 1:($2/1000)