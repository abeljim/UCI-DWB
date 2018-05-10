/**
 * @brief utilities used by the the I/O scale functions and main scale process
 *
 * @file scale_utils.c
 * @author Khoi Trinh
 */

#include <stdio.h>
#include <string.h>
#include <time.h>

#include "scale_utils.h"

/**
 * @brief log the messages from the scale
 * @param infoType would be like "ERROR", "INFO", "WARNINGS"
 * @param message would be like "failed after 5 times"
 * @param log file handler to log files
 * @param codeSection would be like "AFTER_PARSING", "AFTER_READ"
 *
 * The log format will be the same as that used by the shell_script, it is like this:
 * "time INFO_TYPE [CODE_SECTION] detailed_message"
 * the function will flush as soon as it's done writing to make sure log is as up to date as
 * possible
 *
 */
void scaleLogging(const char *infoType, const char *message, FILE *log, const char *codeSection)
{
  // setting up for printing systemt time
  time_t rawTime;
  time(&rawTime);
  struct tm *curTime = localtime(&rawTime);

  char  errMessage[100]          = "";
  char *tempTime                 = asctime(curTime);
  tempTime[strlen(tempTime) - 1] = 0;  // get rid of the \n at the end of asctime output
  strcat(errMessage, tempTime);
  strcat(errMessage, " ");
  strcat(errMessage, infoType);
  strcat(errMessage, " ");
  strcat(errMessage, "[");
  strcat(errMessage, codeSection);
  strcat(errMessage, "] ");
  strcat(errMessage, message);
  strcat(errMessage, "\n");

  fprintf(log, "%s", errMessage);
  fflush(log);
}
