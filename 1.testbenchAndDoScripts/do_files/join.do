restart -f

force n_ready 0 0, 1 30
force p_valid0 0 0, 1 10, 0 20, 1 40, 0 60
force p_valid1 0 0, 1 20, 0 30, 1 50

run 70
