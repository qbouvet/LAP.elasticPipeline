onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_circuit/currenttime
add wave -noupdate /tb_circuit/finished
add wave -noupdate /tb_circuit/reset
add wave -noupdate /tb_circuit/clk
add wave -noupdate /tb_circuit/IFDready
add wave -noupdate /tb_circuit/data
add wave -noupdate /tb_circuit/dataValid
add wave -noupdate /tb_circuit/lastCyclesData
add wave -noupdate /tb_circuit/skippedInstructionFetch
add wave -noupdate /tb_circuit/instrOut
add wave -noupdate /tb_circuit/resOut
add wave -noupdate /tb_circuit/resValid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 295
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
WaveRestoreZoom {0 ps} {875 ps}
