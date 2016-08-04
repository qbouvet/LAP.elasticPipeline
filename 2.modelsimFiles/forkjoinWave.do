onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_forkjoin/currenttime
add wave -noupdate /tb_forkjoin/finished
add wave -noupdate /tb_forkjoin/clk
add wave -noupdate /tb_forkjoin/reset
add wave -noupdate /tb_forkjoin/pValid
add wave -noupdate /tb_forkjoin/valid
add wave -noupdate /tb_forkjoin/nReady
add wave -noupdate /tb_forkjoin/ready
add wave -noupdate /tb_forkjoin/readyArray_out
add wave -noupdate /tb_forkjoin/validArray_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 171
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {982 ps}
