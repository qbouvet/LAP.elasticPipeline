restart -f

force reset 1 0, 0 10
force clk 0 0, 1 5 -repeat 10

force d_in 10#10 0
force p_valid 0 0, 1 15, 0 20
force n_ready 0 0

run 100