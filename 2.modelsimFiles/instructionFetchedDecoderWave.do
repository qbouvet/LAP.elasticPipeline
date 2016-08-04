onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_instructionfetcherdecoder/currenttime
add wave -noupdate /tb_instructionfetcherdecoder/finished
add wave -noupdate /tb_instructionfetcherdecoder/reset
add wave -noupdate /tb_instructionfetcherdecoder/clk
add wave -noupdate /tb_instructionfetcherdecoder/instr
add wave -noupdate -radix decimal /tb_instructionfetcherdecoder/adrA
add wave -noupdate -radix decimal /tb_instructionfetcherdecoder/adrB
add wave -noupdate -radix decimal /tb_instructionfetcherdecoder/adrW
add wave -noupdate -radix decimal /tb_instructionfetcherdecoder/argI
add wave -noupdate -radix decimal /tb_instructionfetcherdecoder/oc
add wave -noupdate /tb_instructionfetcherdecoder/instrValid
add wave -noupdate /tb_instructionfetcherdecoder/nReadyArray
add wave -noupdate /tb_instructionfetcherdecoder/ifdReady
add wave -noupdate /tb_instructionfetcherdecoder/validArray
add wave -noupdate /tb_instructionfetcherdecoder/currentHeldInstruction
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {9023 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 180
configure wave -valuecolwidth 265
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
WaveRestoreZoom {0 ps} {212821 ps}
