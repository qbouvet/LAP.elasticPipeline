onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_opunit/currenttime
add wave -noupdate /tb_opunit/finished
add wave -noupdate /tb_opunit/reset
add wave -noupdate /tb_opunit/clk
add wave -noupdate -radix decimal /tb_opunit/argA
add wave -noupdate -radix decimal /tb_opunit/argB
add wave -noupdate -radix decimal /tb_opunit/argI
add wave -noupdate /tb_opunit/oc
add wave -noupdate -radix decimal /tb_opunit/res
add wave -noupdate /tb_opunit/pValidArray
add wave -noupdate /tb_opunit/nReady
add wave -noupdate /tb_opunit/valid
add wave -noupdate /tb_opunit/readyArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12775 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 189
configure wave -valuecolwidth 268
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
WaveRestoreZoom {0 ps} {134926 ps}
