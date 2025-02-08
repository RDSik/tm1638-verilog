TOP := tm1638

SRC_DIR     := src
TB_DIR      := $(SRC_DIR)
PROJECT_DIR := project

SIM     := iverilog
WAVE    := gtkwave
PROGRAM := openFPGALoader

TCL   := project.tcl
BOARD := tangprimer20k

SRC_FILES += $(SRC_DIR)/tm1638_sio.sv
SRC_FILES += $(TB_DIR)/tm1638_tb.v

.PHONY: all project program clean

all: build run wave

build:
	$(SIM) -g2005-sv -o $(TOP) $(SRC_FILES)

run:
	vvp $(TOP)

wave:
	$(WAVE) $(TOP)_tb.vcd

project: 
	gw_sh $(PROJECT_DIR)/$(TCL)

program:
	$(PROGRAM) -b $(BOARD) -m $(PROJECT_DIR)/$(TOP)/impl/pnr/$(TOP).fs

clean:
ifeq ($(OS), Windows_NT)
	del $(TOP)
	del $(TOP)_tb.vcd
	rmdir /s /q $(PROJECT_DIR)\$(TOP)
else
	rm $(TOP)
	rm $(TOP)_tb.vcd
	rm -rf $(PROJECT_DIR)/$(TOP)
endif