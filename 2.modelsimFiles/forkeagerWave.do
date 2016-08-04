onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_forkeager/currenttime
add wave -noupdate /tb_forkeager/finished
add wave -noupdate /tb_forkeager/reset
add wave -noupdate /tb_forkeager/clk
add wave -noupdate /tb_forkeager/pValid
add wave -noupdate /tb_forkeager/nReady1
add wave -noupdate /tb_forkeager/nReady0
add wave -noupdate /tb_forkeager/valid1
add wave -noupdate /tb_forkeager/valid0
add wave -noupdate /tb_forkeager/ready
add wave -noupdate /tb_forkeager/internalValidArray
add wave -noupdate /tb_forkeager/internalNReadyArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {66482 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 309
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
WaveRestoreZoom {0 ps} {220672 ps}
