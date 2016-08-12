onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbenchcommons/finished
add wave -noupdate /testbenchcommons/reset
add wave -noupdate /testbenchcommons/clk
add wave -noupdate -radix decimal /tb_fwdpathresolutionunit/inputArray
add wave -noupdate /tb_fwdpathresolutionunit/inputValidArray
add wave -noupdate -radix decimal -childformat {{/tb_fwdpathresolutionunit/wAdrArray(3) -radix decimal} {/tb_fwdpathresolutionunit/wAdrArray(2) -radix decimal} {/tb_fwdpathresolutionunit/wAdrArray(1) -radix decimal}} -expand -subitemconfig {/tb_fwdpathresolutionunit/wAdrArray(3) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/wAdrArray(2) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/wAdrArray(1) {-height 16 -radix decimal}} /tb_fwdpathresolutionunit/wAdrArray
add wave -noupdate -radix decimal /tb_fwdpathresolutionunit/readAdr
add wave -noupdate /tb_fwdpathresolutionunit/adrValidArray
add wave -noupdate /tb_fwdpathresolutionunit/nReady
add wave -noupdate -radix decimal /tb_fwdpathresolutionunit/output
add wave -noupdate /tb_fwdpathresolutionunit/ready
add wave -noupdate /tb_fwdpathresolutionunit/valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {65567 ps} 0}
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
WaveRestoreZoom {0 ps} {109056 ps}
