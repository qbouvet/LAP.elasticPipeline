restart -f

force n_ready 0 0, 1 40
force p_valid0 0 0, 1 10, 0 20, 1 30, 0 40, 1 50, 0 60, 1 70
force p_valid1 0 0, 1 20, 0 40, 1 60

run 80
