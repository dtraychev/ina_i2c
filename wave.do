onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/tx_data
add wave -noupdate /tb/rx_data
add wave -noupdate /tb/start
add wave -noupdate /tb/eot
add wave -noupdate -divider Master
add wave -noupdate /tb/tb_master/sm
add wave -noupdate /tb/tb_master/sda
add wave -noupdate /tb/tb_master/scl
add wave -noupdate /tb/tb_master/clk
add wave -noupdate /tb/tb_master/sda_oe
add wave -noupdate /tb/tb_master/slv_addr_in
add wave -noupdate /tb/tb_master/pointer_addr
add wave -noupdate /tb/tb_master/data_valid
add wave -noupdate /tb/tb_master/count
add wave -noupdate /tb/tb_master/data_out
add wave -noupdate -divider Slave
add wave -noupdate /tb/dut/slv_interface/sm
add wave -noupdate /tb/dut/slv_interface/sda
add wave -noupdate /tb/dut/slv_interface/scl
add wave -noupdate /tb/dut/slv_interface/rst
add wave -noupdate /tb/dut/slv_interface/sda_oe
add wave -noupdate /tb/dut/slv_interface/data_out
add wave -noupdate /tb/dut/slv_interface/data_in
add wave -noupdate /tb/dut/slv_interface/addr
add wave -noupdate /tb/dut/slv_interface/data_rdy
add wave -noupdate /tb/dut/slv_interface/addr_pointer
add wave -noupdate /tb/dut/slv_interface/count
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1033 ns} 0} {{Cursor 2} {2203 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 211
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {2340 ns}
