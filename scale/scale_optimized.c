/**
 * @brief contain functions used for scale I/O
 * @file scale_optimized.c
 * @author Khoi Trinh
 * Contain all functions that work directly with the scale file desciptor
 */
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <sys/select.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#include "scale_optimized.h"
#include "scale_utils.h"

// #define SCALE_DEV_FILE "/dev/SCALE"
#define SCALE_DEV_FILE "/dev/ttyACM0"

#define SCALE_MESSAGE_SIZE 6  //!< defined by the manual
#define RECONNECT_ATTEMPTS \
  5  //!< how many times the code will try connecting to scale before giving up
#define LBS_TO_OUNCE_CONV 16.0
#define WEIGHT_THRESHOLD 0.1  //!< min increase in lbs before we consider it a change in weight

#define OPEN_SCALE_TRIAL 5   //!< how many times we try to open the scale before exit
#define CLOST_SCALE_TRIAL 6  //!< how many times we try to close the scale before exit

#define SCALE_SIGNATURE 255  //!< signature value of the first byte given by manufacturer

/**
 * @brief creat file descriptor for talking with scale
 * @param log this is the log file dedicated only to the scale
 * @return scale file descriptor that will be used for the rest of the communications or negative
 * error code
 *
 * The settings of the scale communications is as follow:
 * * 9600 baudrate, this is the max the scale can do
 * * No parity, the scale doesn't have error checking
 * * No output config since the scale doesn't receive command
 * * Canonical mode with Blocking read and wait until at least 6 bytes
 * * Data frame is 8 bit data, 1 stop bit
 */
int openScale(FILE *log)
{
  int scale;
  int count = 0;
  assert(log);
  while ((scale = open(SCALE_DEV_FILE, O_RDONLY | O_NOCTTY)) < 0)
    {
      ++count;
      if (count == OPEN_SCALE_TRIAL)
        {
          scaleLogging("ERROR", "can't open scale\n", log, "OPEN_SCALE");
          exit(-1);
        }
      sleep(1);
    }

  struct termios scale_settings;
  bzero(&scale_settings, sizeof(scale_settings));

  scale_settings.c_lflag = 0;                // set mode to be non-canonical
  scale_settings.c_cflag |= CLOCAL | CREAD;  // ignore modem line and enable receiver
  scale_settings.c_iflag |= IGNPAR;          // ignore parity error
  scale_settings.c_cflag |= CS8;             // 8 bit character, 1 stop bit

  scale_settings.c_cc[VMIN]  = 6;  // read will wait for at least 6 bytes
  scale_settings.c_cc[VTIME] = 0;  // disable timeout

  tcflush(scale, TCIFLUSH);
  if (!cfsetispeed(&scale_settings, B9600) && !tcsetattr(scale, TCSANOW, &scale_settings))
    {
      return scale;
    }
  else
    {
      scaleLogging("ERROR", "error while setting scale with error code \n", log, "OPEN_SCALE");
      scaleLogging("ERROR", strerror(errno), log, "OPEN_SCALE");
      return -1;
    }
}

/**
 * @brief read the scale if enough data is available
 * @param scale the scale descriptor
 * @param inputSet file descriptor set used with select
 * @param timeOut timeval struct containing timeout info
 *
 * @return float represents the increase in weight in lbs or 0 for scale weight remaining the same
 * or error code, all negative numbers returned are error code since weight decreasing is ignored
 * except for one case where the trashbag is detected to have been replaced, the function will
 * adjust the var that stored prev reading accordingly
 *
 * The function stores some data about the previous scale reading and compare with the current one
 * to decide if the data has changed, this reduced waste of time spent processing repeated data,
 * consult the scale manual for data frame example, once the scale has identified that the frame is
 * a valid one based on the flag, it will process the bits accordingly
 */
float readScale(int scale, fd_set *inputSet, struct timeval *timeOut, FILE *log)
{
  assert(scale >= 0);
  assert(inputSet);
  assert(timeOut);

  uint8_t buffer[SCALE_MESSAGE_SIZE];
  uint8_t isNegative;
  uint8_t isOverflow;
  // digits starting from LSB to MSB
  static uint8_t prevBuffer[3];

  uint8_t      digitList[6];
  int          temp;
  int          decimal_point;
  float        difference;
  static float prevScaleResult = 0;  // unit is ounces
  float        scaleResult;

  if (select(scale + 1, inputSet, NULL, NULL, timeOut))
    {
      temp = read(scale, buffer, SCALE_MESSAGE_SIZE);
#ifdef DEBUG
      printf("Temp is %d", temp);
#endif
      if (temp != 6 && temp >= 0)
        {
          return ERROR_NOT_ENOUGH_READ_BYTES;
        }
      else if (temp < 0)
        {
          scaleLogging("ERROR", "failed to read scale\n", log, "READ_RAW");
          scaleLogging("ERROR", strerror(errno), log, "READ_RAW");
          return ERROR_SCALE_READ_FAILED;
        }
      else
        {
          if (buffer[0] != SCALE_SIGNATURE)
            {
#ifdef DEBUG
              printf("Invalid scale reading\n");
#endif
              return ERROR_INVALID_SCALE_READING;
            }
          else
            {
              if (prevBuffer[0] == buffer[2] && prevBuffer[1] == buffer[3] &&
                  prevBuffer[2] == buffer[4])
                {
                  return SCALE_WEIGHT_SAME;
                }
              else
                {
#ifdef DEBUG
                  printf("Computing Scale Reading\n");
                  for (int bufferIndex = 0; bufferIndex < 6; ++bufferIndex)
                    {
                      printf("Buffer number %d is %d\n", bufferIndex, buffer[bufferIndex]);
                    }
                  printf("\n");
#endif
                  decimal_point = buffer[1] & 0b00000111;
                  isNegative    = buffer[1] & 0b00100000;

                  isOverflow = buffer[1] & 0b10000000;
                  if (isOverflow)
                    {
                      scaleLogging("ERROR", "Scale overflow", log, "READING_PARSING");
                      return ERROR_SCALE_OVERFLOW;
                    }

                  digitList[0] = buffer[2] & 0b00001111;
                  digitList[1] = (buffer[2] & 0b11110000) >> 4;
                  digitList[2] = buffer[3] & 0b00001111;
                  digitList[3] = (buffer[3] & 0b11110000) >> 4;
                  digitList[4] = buffer[4] & 0b00001111;
                  digitList[5] = (buffer[4] & 0b11110000) >> 4;

#ifdef DEBUG
                  for (int digitIndex = 0; digitIndex < 6; ++digitIndex)
                    {
                      printf("Digit number %d is %d\n", digitIndex, digitList[digitIndex]);
                    }
                  printf("\n");
#endif
                  // save current reading to compare to the next one
                  prevBuffer[0] = buffer[2];
                  prevBuffer[1] = buffer[3];
                  prevBuffer[2] = buffer[4];

                  scaleResult = digitList[0] + digitList[1] * 10 + digitList[2] * 100 +
                                digitList[3] * 1000 + digitList[4] * 10000 + digitList[5] * 100000;
                  scaleResult = (scaleResult / (pow(10.0, decimal_point - 1))) * LBS_TO_OUNCE_CONV;
                  scaleResult = isNegative ? -scaleResult : scaleResult;

                  if (!tcflush(scale, TCIFLUSH))
                    {
                      // check for trashbag change
                      difference = scaleResult - (prevScaleResult + WEIGHT_THRESHOLD);
                      if (difference > 0 || difference <= -5 * LBS_TO_OUNCE_CONV)
                        {
                          prevScaleResult = scaleResult;
                          return difference + WEIGHT_THRESHOLD;
                        }
                      else
                        {
                          return SCALE_WEIGHT_DECREASED;
                        }
                    }
                  else
                    {
                      scaleLogging("ERROR", "failed to flush file\n", log, "PARSING_CLEANUP");
                      return ERROR_FLUSH_FAILED;
                    }
                }
            }
        }
    }

  else
    {
      return SCALE_TIMEOUT;
    }
}

/**
 * @brief close the scale and the log associated with it
 * @param scale file descriptor for the scale
 * @param log file descriptor for log
 * @return error code or 0 for success
 */
int closeScale(int scale, FILE *log)
{
  assert(scale >= 0);
  assert(log);

  int count = 0;
  while (close(scale) < 0)
    {
      ++count;
    }

  if (count == CLOST_SCALE_TRIAL)
    {
      scaleLogging("ERROR", "failed to load scale\n", log, "CLOSE_SCALE");
      exit(-1);
    }
  fclose(log);
  return 0;
}
