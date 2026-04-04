# Verilator simulation for game_clock (C++ testbench; Verilator 4.x cannot run the SV TB).
VERILATOR ?= verilator
SRC_DIR := ../sv/src
TB_CPP := tb_game_clock.cpp
OBJ_DIR := obj_dir
EXE := $(OBJ_DIR)/Vgame_clock

.PHONY: all run clean

all: run

$(EXE): $(SRC_DIR)/game_clock.sv $(TB_CPP)
	$(VERILATOR) --cc --exe -Mdir $(OBJ_DIR) \
		-Wall -Wno-fatal \
		$(TB_CPP) \
		$(SRC_DIR)/game_clock.sv \
		--top-module game_clock
	$(MAKE) -C $(OBJ_DIR) -f Vgame_clock.mk Vgame_clock

run: $(EXE)
	./$(EXE)

clean:
	rm -rf $(OBJ_DIR)
