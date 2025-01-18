create_project -name tm1638 -pn GW2A-LV18PG256C8/I7 -device_version C -force
add_file ../../src/top.v
add_file ../../src/tm1638.v
add_file ../top.sdc
add_file ../top.cst
set_option -top_module top
run all