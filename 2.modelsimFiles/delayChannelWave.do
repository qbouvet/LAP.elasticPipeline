onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_delaychannel/currenttime
add wave -noupdate /tb_delaychannel/finished
add wave -noupdate /tb_delaychannel/reset
add wave -noupdate /tb_delaychannel/clk
add wave -noupdate -radix decimal /tb_delaychannel/d_in
add wave -noupdate -radix decimal -childformat {{/tb_delaychannel/d_out(0) -radix decimal} {/tb_delaychannel/d_out(1) -radix decimal} {/tb_delaychannel/d_out(2) -radix decimal} {/tb_delaychannel/d_out(3) -radix decimal}} -expand -subitemconfig {/tb_delaychannel/d_out(0) {-radix decimal} /tb_delaychannel/d_out(1) {-radix decimal} /tb_delaychannel/d_out(2) {-radix decimal} /tb_delaychannel/d_out(3) {-radix decimal}} /tb_delaychannel/d_out
add wave -noupdate /tb_delaychannel/p_valid
add wave -noupdate /tb_delaychannel/n_ready
add wave -noupdate /tb_delaychannel/ready
add wave -noupdate /tb_delaychannel/valid
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {6051 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 210
configure wave -valuecolwidth 127
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
WaveRestoreZoom {0 ps} {118266 ps}
