onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_circuit/currenttime
add wave -noupdate /tb_circuit/ifdEmpty
add wave -noupdate /tb_circuit/finished
add wave -noupdate /tb_circuit/reset
add wave -noupdate /tb_circuit/clk
add wave -noupdate /tb_circuit/IFDready
add wave -noupdate /tb_circuit/data
add wave -noupdate /tb_circuit/dataValid
add wave -noupdate /tb_circuit/currentInstruction
add wave -noupdate -radix decimal /tb_circuit/resOut
add wave -noupdate /tb_circuit/resValid
add wave -noupdate /tb_circuit/circ/OPU/valid
add wave -noupdate /tb_circuit/circ/OPU/pValidArray
add wave -noupdate /tb_circuit/circ/OPU/readyArray
add wave -noupdate /tb_circuit/circ/FPRU/validArray
add wave -noupdate /tb_circuit/circ/FPRU/readyArray
add wave -noupdate /tb_circuit/circ/FPRU/adrValidArray
add wave -noupdate /tb_circuit/circ/FPRU/inputValidArray
add wave -noupdate /tb_circuit/circ/adrWDelayChannel/ready
add wave -noupdate /tb_circuit/circ/adrWDelayChannel/p_valid
add wave -noupdate /tb_circuit/circ/adrWDelayChannel/valid
add wave -noupdate /tb_circuit/circ/regFile/readyArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {11099 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 392
configure wave -valuecolwidth 275
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
WaveRestoreZoom {0 ps} {117028 ps}
