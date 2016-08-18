onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_circuit/currenttime
add wave -noupdate /tb_circuit/ifdEmpty
add wave -noupdate /tb_circuit/finished
add wave -noupdate /tb_circuit/reset
add wave -noupdate /tb_circuit/clk
add wave -noupdate /tb_circuit/IFDready
add wave -noupdate /tb_circuit/currentInstruction
add wave -noupdate -radix decimal /tb_circuit/circ/opResult
add wave -noupdate /tb_circuit/circ/opResultValid
add wave -noupdate -radix decimal /tb_circuit/circ/fwdUnit/wAdrArray
add wave -noupdate -radix decimal /tb_circuit/circ/fwdUnit/readAdrB
add wave -noupdate -radix decimal /tb_circuit/circ/fwdUnit/readAdrA
add wave -noupdate /tb_circuit/circ/fwdUnit/adrValidArray
add wave -noupdate -radix decimal /tb_circuit/circ/fwdUnit/inputArray
add wave -noupdate /tb_circuit/circ/fwdUnit/inputValidArray
add wave -noupdate -radix decimal /tb_circuit/circ/fwdUnit/outputArray
add wave -noupdate /tb_circuit/circ/fwdUnit/validArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {72699 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 461
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
WaveRestoreZoom {182255 ps} {279882 ps}
