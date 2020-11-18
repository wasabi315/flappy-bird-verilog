CSRCS = input.c
VSRCS = main.v
EXES = main input

all: $(EXES)

main: $(VSRCS)
	iverilog -o $@ $(VSRCS)

CC = gcc
CFLAGS = -Wall -Werror -O2

input: $(CSRCS)
	$(CC) $(CFLAGS) -o $@ $(CSRCS)

.PHONY: run clean
run:
	./input | ./main

clean:
	$(RM) -f $(EXES)
