SRC += ascal.vhd
SRC += avm_memory.vhd
SRC += tb_clk.vhd
SRC += gen_video.vhd
SRC += sys.vhd
SRC += tb.vhd

TB = tb

SRC += $(TB).vhd
WAVE = $(TB).ghw
SAVE = $(TB).gtkw

sim: $(SRC)
	ghdl -i --std=08 --work=work $(SRC)
	ghdl -m --std=08 -fexplicit $(TB)
	ghdl -r --std=08 $(TB) --assert-level=error --wave=$(WAVE) --stop-time=40us

show: $(WAVE)
	gtkwave $(WAVE) $(SAVE)


clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)

