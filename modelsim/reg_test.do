restart -f

force clk 0 0, 1 5 -repeat 10
force reset 1 0, 0 12

force d_in 16#00000000 0, 16#00000005 10, 16#00000000 20, 16#00000005 40, 16#00000000 60
force enable 0 0, 1 5, 0 20, 1 30, 0 40, 1 45, 0 50 

run 70