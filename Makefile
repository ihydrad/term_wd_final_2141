MCU     = attiny2313
F_CPU   = 4000000UL
TARGET  = main

CC      = avr-gcc
OBJCOPY = avr-objcopy
SIZE    = avr-size
AVRDUDE = avrdude

CFLAGS  = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os -Wall -Wextra -std=c99

# Программатор: замени на свой (usbasp / arduino / stk500v1 ...)
PROGRAMMER = usbasp
PORT       =

all: $(TARGET).hex

$(TARGET).elf: $(TARGET).c
	$(CC) $(CFLAGS) -o $@ $<

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@
	$(SIZE) --format=avr --mcu=$(MCU) $<

flash: $(TARGET).hex
	$(AVRDUDE) -c $(PROGRAMMER) -p $(MCU) $(if $(PORT),-P $(PORT),) \
	           -U flash:w:$(TARGET).hex:i

clean:
	-del /Q $(TARGET).elf $(TARGET).hex 2>NUL

.PHONY: all flash clean
