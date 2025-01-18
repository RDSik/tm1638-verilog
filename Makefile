TOP := tm1638

SRC_DIR := ./
TB_DIR  := SRC_DIR

SIM  := iverilog
WAVE := gtkwave

SRC_FILES += $(SRC_DIR)tm1638.v
SRC_FILES += $(TB_DIR)tm1638_tb.v

.PHONY: all clean

all: build run wave

build:
	$(SIM) -o $(TOP_NAME) $(SRC_FILES)

run:
	vvp $(TOP_NAME)

wave: 
	$(WAVE) $(TOP)_tb.vcd

clean:
	rm *.vcd
