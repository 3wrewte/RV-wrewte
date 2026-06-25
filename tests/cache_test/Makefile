VERILATOR ?= verilator
SRC_DIR := ../../RV-wrewte.srcs/sources_1/new
VFLAGS := --cc --exe -Wno-fatal -Wno-WIDTH -Wno-UNOPTFLAT -Wno-UNUSED \
          -Wno-PINMISSING -Wno-WIDTHCONCAT -Wno-INITIALDLY \
          --top-module cache -Mdir obj_dir
VSRC := $(SRC_DIR)/cache.v $(SRC_DIR)/realloc.v $(SRC_DIR)/LSB.v

# openSUSE puts includes here instead of /usr/share/verilator/include/
VINC := /usr/include/verilator

CXX ?= g++
CXXFLAGS := -O2 -std=c++17 -I$(VINC) -Iobj_dir
LDFLAGS := -lpthread

OBJ_DIR := obj_dir
TARGET := $(OBJ_DIR)/cache_test

.PHONY: all clean run

all: $(TARGET)

$(OBJ_DIR)/Vcache.h: $(VSRC) tb.cpp
	$(VERILATOR) $(VFLAGS) $(VSRC) tb.cpp

$(TARGET): $(OBJ_DIR)/Vcache.h tb.cpp
	$(CXX) $(CXXFLAGS) $(OBJ_DIR)/Vcache*.cpp $(VINC)/verilated.cpp tb.cpp -o $@ $(LDFLAGS)

run: $(TARGET)
	./$(TARGET)

clean:
	rm -rf $(OBJ_DIR)
