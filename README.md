# tm1638-verilog
This is system verilog TM1638 LED driver for Tang Primer 20k Dock, based on https://github.com/chipdesignschool/basics-graphics-music.git and https://github.com/alangarf/tm1638-verilog.

TM1638 Pins | Tang Primer 20K Pins
------------ | -------------
CLK | M15
DIO | R11
STB | J16


1. For building project use:
```bash
make project
```

2. For program with openfpgaloader use:
```bash
make program
```

3. For simulation with iverilog and gtkwave use:
```bash
make
```
