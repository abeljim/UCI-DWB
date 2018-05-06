/**
 * @brief Main process for scale
 * @file scale_main.c
 * @author Khoi Trinh
 *
 * This is the main process of the scale, the main process would be responsible for setting up
 * file handler for log, save files, as well as initilializing set used by select for multiplexing
 * file handler and keep checking select to log errors or write results to the save file used by
 * display
 */
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>

#include "scale_optimized.h"
#include "scale_utils.h"

#define TIMEOUT_LIMIT 5   // how many consecutive timeouts before we log an error
#define SELECT_TIMEOUT 4  // unit is second

/**
 * @brief the main function responsible for managing the scale
 * @return this should never return unless in special circumstances such as the physical scale or
 * the pi is damaged
 */
int main(void)
{
  // retrieve env var to get path for saving stuffs and determine the role of the bin
  const char *homeDir = getenv("HOME");
  assert(homeDir);
  const char *mode = getenv("MODE");  // the MODE env var is defined during the scale setup
  assert(mode);

  char saveDir[100] = "";
  strcat(saveDir, homeDir);
  strcat(saveDir, "/UCI-DWB/");
  strcat(saveDir, mode);
  strcat(saveDir, "/result.json");
  FILE *saveFile = fopen(saveDir, "w");
  assert(saveFile);

  char logDir[100] = "";
  strcat(logDir, homeDir);
  strcat(logDir, "/UCI-DWB/scale");
  strcat(logDir, "/scale_log.log");
  FILE *log = fopen(logDir, "a");
  scaleLogging("INFO", "Testing", log, "OPEN_FILE");
  uint8_t timeoutCounter = 0;
  assert(log);

  int   scale = openScale(log);
  float result;
#ifdef DEBUG
  printf("Preparing to jump in mainloop");
#endif
  for (;;)
    {
      struct timeval timeOut;
      timeOut.tv_sec  = SELECT_TIMEOUT;
      timeOut.tv_usec = 0;
      fd_set inputSet;
      FD_ZERO(&inputSet);
      FD_SET(scale, &inputSet);
      result = readScale(scale, &inputSet, &timeOut, log);
#ifdef DEBUG
      printf("\nThe scale reading is %f\n", result);
#endif
      if (result == ERROR_INVALID_SCALE_READING)
        {
          scaleLogging("ERROR", "invalid reading\n", log, "AFTER_READ");
        }
      else if (result == ERROR_NOT_ENOUGH_READ_BYTES)
        {
          scaleLogging("ERROR", "not enough read bytes\n", log, "AFTER_READ");
        }
      else if (result == SCALE_WEIGHT_SAME || result == SCALE_WEIGHT_DECREASED)
        {
#ifdef DEBUG
          printf("Scale weight stays the same\n");
#endif
        }
      else if (result == SCALE_TIMEOUT)
        {
#ifdef DEBUG
          printf("The scale timeout");
#endif
          ++timeoutCounter;
          if (timeoutCounter == TIMEOUT_LIMIT)
            {
              scaleLogging("ERROR", "Many Consecutive timeout", log, "AFTER_READ");
            }
        }
      else if (result == ERROR_FLUSH_FAILED)
        {
          scaleLogging("ERROR", "Failed serial flush", log, "AFTER_READ");
        }
      else
        {
          timeoutCounter = 0;
          fprintf(saveFile, "%f", result);
        }
    }

  closeScale(scale, log);
  return 0;
}
