CC = gcc 
CFLAGS= -O2 -Wall -std=c99
DEBUG= -g -DDEBUG
LKFLAG= -lm

# Non Debug targets
scale_main.out: scale_utils.o scale_optimized.o scale_main.o
	$(CC) $(CFLAGS) $(^) -o $(@) $(LKFLAG)

scale_main.o: scale_main.c scale_optimized.h scale_utils.h
	$(CC) -c $(CFLAGS) $(<)  -o $(@)

scale_optimized.o: scale_optimized.c scale_optimized.h scale_utils.h
	$(CC) -c $(CFLAGS) $(<) -o $(@)

scale_utils.o: scale_utils.c scale_utils.h
	$(CC) -c $(CFLAGS) $(<) -o $(@)

# Debug targets

scale_main_debug.out: scale_utils_debug.o scale_optimized_debug.o scale_main_debug.o
	$(CC) $(CFLAGS) $(DEBUG) $(^) -o $(@) $(LKFLAG)

scale_main_debug.o: scale_main.c scale_optimized.h scale_utils.h
	$(CC) -c $(CFLAGS) $(DEBUG) $(<) -o $(@)

scale_optimized_debug.o: scale_optimized.c scale_optimized.h 
	$(CC) -c $(CFLAGS) $(DEBUG) $(<) -o $(@)

scale_utils_debug.o: scale_utils.c scale_utils.h
	$(CC) -c $(CFLAGS) $(DEBUG) $(<) -o $(@)


clean: 
	rm -rf *.o *.out