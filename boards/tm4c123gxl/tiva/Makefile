include ../solution.mk

export PATH := $(ELDS)/toolchain/$(BOARD_CROSS_TUPLE)/bin:$(PATH)

TARGET_NAME = tiva-$(BOARD_TYPE)

TARGET_ELF = $(TARGET_NAME).elf
TARGET_BIN = $(TARGET_NAME).axf
TARGET_HEX = $(TARGET_NAME).hex
TARGET_MAP = $(TARGET_NAME).map

CFLAGS = -march=armv7e-m -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb
CFLAGS += -MD -std=c99 -Wall -ffunction-sections -fdata-sections -pedantic
CFLAGS += -DPART_$(shell echo $(BOARD_MCU) | tr '[:lower:]' '[:upper:]') -DTARGET_IS_TM4C123_RB1
CFLAGS += -I$(BOARD_SCM)/tivaware
ifdef DEBUG
CFLAGS += -Og -g3 -gdwarf
else
CFLAGS += -Os
endif

CC = $(BOARD_CROSS_TUPLE)-gcc
LD = $(BOARD_CROSS_TUPLE)-ld
GDB = $(BOARD_CROSS_TUPLE)-gdb
SIZE = $(BOARD_CROSS_TUPLE)-size
OBJCOPY = $(BOARD_CROSS_TUPLE)-objcopy
OBJDUMP = $(BOARD_CROSS_TUPLE)-objdump

MKDIR = mkdir -p

OUTPUT = build

LDFLAGS = -Wl,-T$(BOARD_MCU).ld \
	  -Wl,--entry=ResetISR \
	  -Wl,--static \
	  -Wl,--gc-sections \
	  -Wl,-Map=$(OUTPUT)/$(TARGET_MAP)

LDLIBS = $(BOARD_SCM)/tivaware/driverlib/gcc/libdriver.a

SOURCES = $(shell find src/ -name "*.c" -print)
ifdef DEBUG
OBJECTS = $(addprefix $(OUTPUT)/,$(notdir $(SOURCES:.c=.s)))
else
OBJECTS = $(addprefix $(OUTPUT)/,$(notdir $(SOURCES:.c=.o)))
endif

all: $(TARGET_ELF) $(TARGET_HEX) $(TARGET_BIN)

$(TARGET_ELF): $(OUTPUT)/$(TARGET_ELF)
$(OUTPUT)/$(TARGET_ELF): $(OBJECTS)
	$(CC) $(LDFLAGS) $^ -o $@ $(LDLIBS)
	@$(SIZE) $@
ifdef DEBUG
	@$(OBJDUMP) -S --disassemble $@ > $@.lst 2> $@-error.lst
endif

$(TARGET_HEX): $(OUTPUT)/$(TARGET_HEX)
$(OUTPUT)/$(TARGET_HEX): $(OUTPUT)/$(TARGET_ELF)
	$(OBJCOPY) -O ihex $< $@

$(TARGET_BIN): $(OUTPUT)/$(TARGET_BIN)
$(OUTPUT)/$(TARGET_BIN): $(OUTPUT)/$(TARGET_ELF)
	$(OBJCOPY) -O binary $< $@

ifdef DEBUG
$(OUTPUT)/%.s: src/%.c | $(OUTPUT)
	$(CC) $(CFLAGS) -S $^ -o $@
else
$(OUTPUT)/%.o: src/%.c | $(OUTPUT)
	$(CC) $(CFLAGS) -c $^ -o $@
endif

$(OUTPUT):
	@$(MKDIR) $(OUTPUT)

clean:
	$(RM) -r $(OUTPUT) *.log

flash: $(OUTPUT)/$(TARGET_BIN)
	@lm4flash $<

gdb: $(OUTPUT)/$(TARGET_ELF)
	@$(GDB) \
		-ex 'target remote | openocd -f board/ek-tm4c123gxl.cfg -c "gdb_port pipe; log_output openocd.log"; monitor reset halt' \
		$<

.PHONY: all clean flash gdb $(TARGET_ELF) $(TARGET_HEX) $(TARGET_BIN)
