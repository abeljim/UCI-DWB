CC = gcc 
CFLAGS= -O2 -Wall -std=c99
DEBUG= -DDEBUG
LKFLAG= -lm

scale_optimized: scale_optimized.c scale_optimized.h 
	$(CC) $(CFLAGS) $(<) -o $(@) $(LKFLAGS)
scale_optimized_debug: scale_optimized.c scale_optimized.h 
	$(CC) $(CFLAGS) $(DEBUG) $(<) -o $(@) $(LKFLAGS)
clean: 
	rm -rf *.o scale_optimized