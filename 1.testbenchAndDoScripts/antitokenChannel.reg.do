restart -f

force reset 1 0, 0 100
force clk 1 0, 0 50 -repeat 100

force wrenable 1 0
force isInsertionSpot 0 0
force antitoken 0 0
force d_in 0 0, 1 150


run 500
