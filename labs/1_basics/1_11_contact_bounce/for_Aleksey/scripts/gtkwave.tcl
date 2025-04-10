# gtkwave::loadFile "dump.vcd"

set all_signals [list]

lappend all_signals testbench.clk
lappend all_signals testbench.rst
lappend all_signals testbench.key
lappend all_signals testbench.i_lab_top.cnt
lappend all_signals testbench.i_lab_top.led
lappend all_signals testbench.i_lab_top.abcdefgh
lappend all_signals testbench.i_lab_top.digit

set num_added [ gtkwave::addSignalsFromList $all_signals ]

gtkwave::/Time/Zoom/Zoom_Full
