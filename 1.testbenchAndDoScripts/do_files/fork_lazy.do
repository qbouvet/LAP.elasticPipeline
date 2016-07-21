restart -f

force p_valid 0 0, 1 10, 0 50
force n_ready0 0 0, 1 20, 0 30, 1 40, 0 50, 1 60, 0 70, 1 80
force n_ready1 0 0, 1 30, 0 50, 0 60, 1 70

run 90
