#include <stdio.h>
#include <string.h>
#include <time.h>

#include "scale_utils.h"

void scaleLogging(const char *infoType, const char *message, FILE *log, const char *code_section)
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
  strcat(errMessage, code_section);
  strcat(errMessage, "] ");
  strcat(errMessage, message);
  strcat(errMessage, "\n");

  fprintf(log, "%s", errMessage);
  fflush(log);
}
