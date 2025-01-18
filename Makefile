TOP := tm1638

SRC_DIR := src/
TB_DIR  := $(SRC_DIR)

SIM     := iverilog
WAVE    := gtkwave
PROGRAM := openFPGALoader

BOARD := tangprimer20k

SRC_FILES += $(SRC_DIR)tm1638.v
SRC_FILES += $(TB_DIR)tm1638_tb.v

.PHONY: all clean

all: build run wave

build:
	$(SIM) -o $(TOP) $(SRC_FILES)

run:
	vvp $(TOP)

wave: 
	$(WAVE) $(TOP)_tb.vcd

program:
	$(PROGRAM) -b $(BOARD) -m syn/tm1638/impl/pnr/$(TOP).fs

clean:
	rm $(TOP)
	rm $(TOP).vcd
