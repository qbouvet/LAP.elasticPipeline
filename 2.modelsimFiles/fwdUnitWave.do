onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbenchcommons/finished
add wave -noupdate /testbenchcommons/reset
add wave -noupdate /testbenchcommons/clk
add wave -noupdate -radix decimal /tb_forwardingunit/readAdrA
add wave -noupdate -radix decimal /tb_forwardingunit/readAdrB
add wave -noupdate -radix decimal /tb_forwardingunit/wAdrArray
add wave -noupdate /tb_forwardingunit/adrValidArray
add wave -noupdate -radix decimal /tb_forwardingunit/inputArray
add wave -noupdate /tb_forwardingunit/inputValidArray
add wave -noupdate /tb_forwardingunit/nReadyArray
add wave -noupdate /tb_forwardingunit/validArray
add wave -noupdate /tb_forwardingunit/readyArray
add wave -noupdate -radix decimal /tb_forwardingunit/outputArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {45882 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 319
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
WaveRestoreZoom {59955 ps} {202108 ps}
