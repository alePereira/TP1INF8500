vsim -t ps work.uart_tb
add wave all
#{sim:/uart_tb/bfm/we } \
#{sim:/uart_tb/bfm/ce } \
#{sim:/uart_tb/bfm/adr } \
#{sim:/uart_tb/bfm/dat } \
#{sim:/uart_tb/bfm/rx } \
#{sim:/uart_tb/bfm/tx } \
#{sim:/uart_tb/bfm/inter } \
#{sim:/uart_tb/stimuli/bfm/cb/inter } \
#{sim:/uart_tb/bfm/arst } 
run -all
coverage report -detail -cvg -file report.txt
quit -sim
#run 40 ns
