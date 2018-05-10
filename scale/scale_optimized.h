/**
 * @brief Header file containing ERROR codes and SCALE return code
 *
 * @file scale_optimized.h
 * @author Khoi Trinh
 */
#ifndef _SCALE_OPTIMIZED_H
#define _SCALE_OPTIMIZED_H
#include <stdio.h>
#include <stdlib.h>

#define ERROR_NOT_ENOUGH_READ_BYTES -1  //!< not enough data on the scale descriptor buffer
#define ERROR_SCALE_READ_FAILED -2
#define ERROR_INVALID_SCALE_READING -3  //!< the data frame has the wrong flag
#define ERROR_FLUSH_FAILED -4
#define ERROR_SCALE_OVERFLOW -5  //!< current weight heavier than scale can handle
#define ERROR_SAVE_FILE_INVALID -8
#define ERROR_FAIL_TO_CLOSE_FILE -9

#define SCALE_TIMEOUT -6
#define SCALE_WEIGHT_DECREASED -7
#define SCALE_WEIGHT_SAME 0

int openScale(FILE *log);

float readScale(int scale, fd_set *inputSet, struct timeval *timeOut, FILE *log);

int sendScaleResult(float scaleResult, char *saveFileName, FILE *log, const char *mode);

int closeScale(int scale, FILE *log);
#endif