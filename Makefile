include .knightos/variables.make

# This is a list of files that need to be added to the filesystem when installing your program
ALL_TARGETS:=$(BIN)calendar $(APPS)calendar.app

# This is all the make targets to produce said files
$(BIN)calendar: *.asm
	mkdir -p $(BIN)
	$(AS) $(ASFLAGS) --listing $(OUT)main.list main.asm $(BIN)calendar

$(APPS)calendar.app: config/calendar.app
	mkdir -p $(APPS)
	cp config/calendar.app $(APPS)

include .knightos/sdk.make
