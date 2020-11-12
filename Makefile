SRCS = $(wildcard *.v)
PROG = main

$(PROG): $(SRCS)
	iverilog -o $@ $(SRCS)

.PHONY: clean
clean:
	$(RM) -f $(PROG)

