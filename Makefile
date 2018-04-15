CC = gcc 
CFLAGS= -O2 -Wall -std=c99
DEBUG= -DDEBUG
LKFLAG= -lm

scale_optimized: scale_optimized.c scale_optimized.h 
	$(CC) $(CFLAGS) $(<) -o $(@) $(LKFLAG)
scale_optimized_debug: scale_optimized.c scale_optimized.h 
	$(CC) $(CFLAGS) $(DEBUG) $(<) -o $(@) $(LKFLAG)
clean: 
	rm -rf *.o scale_optimized