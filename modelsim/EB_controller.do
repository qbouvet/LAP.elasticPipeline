restart -f

force reset 1 0, 0 10
force clk 0 0, 1 5 -repeat 10


force p_valid 0 0, 1 10, 0 40
force n_ready 0 0, 1 40, 0 60

force p_valid 1 70, 0 80
force n_ready 1 70, 0 90

force p_valid 1 100
force n_ready 1 120	



run 300	