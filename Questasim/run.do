vdel -all
vlib work 
vlog  apb_slave.v apb_slave_tb.v +cover -covercells
vsim -voptargs=+acc work.apb_slave_tb -cover
add wave *
run -all