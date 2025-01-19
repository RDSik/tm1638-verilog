create_project -name project -pn GW2A-LV18PG256C8/I7 -device_version C -force
add_file ../../src/tm1638_board_controller.sv
add_file ../../src/tm1638_sio.sv
add_file ../../src/tm1638_registers.sv
add_file ../top.sdc
add_file ../top.cst
set_option -top_module tm1638_board_controller
set_option -verilog_std sysv2017
run all