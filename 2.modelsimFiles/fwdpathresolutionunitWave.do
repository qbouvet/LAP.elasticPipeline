onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbenchcommons/finished
add wave -noupdate /testbenchcommons/reset
add wave -noupdate /testbenchcommons/clk
add wave -noupdate -radix decimal -childformat {{/tb_fwdpathresolutionunit/inputArray(4) -radix decimal} {/tb_fwdpathresolutionunit/inputArray(3) -radix decimal} {/tb_fwdpathresolutionunit/inputArray(2) -radix decimal} {/tb_fwdpathresolutionunit/inputArray(1) -radix decimal} {/tb_fwdpathresolutionunit/inputArray(0) -radix decimal}} -expand -subitemconfig {/tb_fwdpathresolutionunit/inputArray(4) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/inputArray(3) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/inputArray(2) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/inputArray(1) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/inputArray(0) {-height 16 -radix decimal}} /tb_fwdpathresolutionunit/inputArray
add wave -noupdate -radix decimal -childformat {{/tb_fwdpathresolutionunit/wAdrArray(4) -radix decimal} {/tb_fwdpathresolutionunit/wAdrArray(3) -radix decimal} {/tb_fwdpathresolutionunit/wAdrArray(2) -radix decimal}} -expand -subitemconfig {/tb_fwdpathresolutionunit/wAdrArray(4) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/wAdrArray(3) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/wAdrArray(2) {-height 16 -radix decimal}} /tb_fwdpathresolutionunit/wAdrArray
add wave -noupdate -radix decimal /tb_fwdpathresolutionunit/readAdrB
add wave -noupdate -radix decimal /tb_fwdpathresolutionunit/readAdrA
add wave -noupdate /tb_fwdpathresolutionunit/inputValidArray
add wave -noupdate /tb_fwdpathresolutionunit/adrValidArray
add wave -noupdate -radix decimal -childformat {{/tb_fwdpathresolutionunit/outputArray(1) -radix decimal} {/tb_fwdpathresolutionunit/outputArray(0) -radix decimal}} -expand -subitemconfig {/tb_fwdpathresolutionunit/outputArray(1) {-height 16 -radix decimal} /tb_fwdpathresolutionunit/outputArray(0) {-height 16 -radix decimal}} /tb_fwdpathresolutionunit/outputArray
add wave -noupdate /tb_fwdpathresolutionunit/nReadyArray
add wave -noupdate /tb_fwdpathresolutionunit/validArray
add wave -noupdate /tb_fwdpathresolutionunit/readyArray
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {126292 ps} 0}
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
WaveRestoreZoom {9955 ps} {152108 ps}
