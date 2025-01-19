TOP := tm1638

SRC_DIR := src/
TB_DIR  := $(SRC_DIR)

SIM     := iverilog
WAVE    := gtkwave
PROGRAM := openFPGALoader

TCL   := project.tcl
BOARD := tangprimer20k

SRC_FILES += $(SRC_DIR)tm1638_sio.sv
SRC_FILES += $(TB_DIR)tm1638_tb.v

.PHONY: all clean

all: build run wave

build:
	$(SIM) -g2005-sv -o $(TOP) $(SRC_FILES)

run:
	vvp $(TOP)

wave: 
	$(WAVE) $(TOP)_tb.vcd

project:
	cd syn && \
	gw_sh $(TCL)

program:
	$(PROGRAM) -b $(BOARD) -m syn/project/impl/pnr/$(TOP).fs

clean:
	rm $(TOP)
	rm $(TOP).vcd
