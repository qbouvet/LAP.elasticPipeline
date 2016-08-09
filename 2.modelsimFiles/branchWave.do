onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbenchcommons/currenttime
add wave -noupdate /testbenchcommons/finished
add wave -noupdate /testbenchcommons/reset
add wave -noupdate /testbenchcommons/clk
add wave -noupdate /tb_branch/condition
add wave -noupdate /tb_branch/pValid
add wave -noupdate /tb_branch/nReadyArray
add wave -noupdate /tb_branch/ready
add wave -noupdate /tb_branch/validArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {42573 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 137
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ps} {129280 ps}
