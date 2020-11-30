CSRCS = io.c
VSRCS = main.v
EXES = main io

all: $(EXES)

VC = iverilog
VFLAGS = -Wall

main: $(VSRCS)
	$(VC) $(VFLAGS) -o $@ $(VSRCS)

CC = gcc
CFLAGS = -Wall -Werror -O2

io: $(CSRCS)
	$(CC) $(CFLAGS) -o $@ $(CSRCS)

.PHONY: run clean
run:
	./io | ./main

clean:
	$(RM) -f $(EXES)
