onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_registerfile/currenttime
add wave -noupdate /tb_registerfile/finished
add wave -noupdate /tb_registerfile/reset
add wave -noupdate /tb_registerfile/clk
add wave -noupdate -radix decimal /tb_registerfile/adrA
add wave -noupdate -radix decimal /tb_registerfile/adrB
add wave -noupdate -radix decimal /tb_registerfile/a
add wave -noupdate -radix decimal /tb_registerfile/b
add wave -noupdate -radix decimal /tb_registerfile/adrW
add wave -noupdate -radix decimal /tb_registerfile/wrData
add wave -noupdate /tb_registerfile/pValidArray
add wave -noupdate /tb_registerfile/nReadyArray
add wave -noupdate /tb_registerfile/readyArray
add wave -noupdate /tb_registerfile/validArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {48244 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {127794 ps}
