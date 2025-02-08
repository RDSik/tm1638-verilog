# tm1638-verilog
This is system verilog TM1638 LED driver for Tang Primer 20k Dock, based on https://github.com/chipdesignschool/basics-graphics-music/tree/main/peripherals and https://github.com/alangarf/tm1638-verilog.

TM1638 Pins | Tang Primer 20K Pins
------------ | -------------
CLK | M15
DIO | R11
STB | J16

* For building project (need Gowind IDE) use:
```bash
make project
```

* For program with openfpgaloader use:
```bash
make program
```

* For simulation with iverilog and gtkwave use:
```bash
make
```
