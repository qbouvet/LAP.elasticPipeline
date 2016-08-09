onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbenchcommons/finished
add wave -noupdate /testbenchcommons/reset
add wave -noupdate /testbenchcommons/clk
add wave -noupdate /tb_joinn/pValidArray
add wave -noupdate /tb_joinn/nReady
add wave -noupdate /tb_joinn/valid
add wave -noupdate /tb_joinn/readyArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {39063 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 235
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
WaveRestoreZoom {0 ps} {237056 ps}
