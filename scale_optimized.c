#include <errno.h>
#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <termios.h>
#include <unistd.h>
#include <time.h>
#include <sys/select.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>

#include "scale_optimized.h"

// possible values are "compost", "landfill", "recycle", CASE SENSITIVE
#define MODE "compost"

#define SCALE_DEV_FILE "/dev/SCALE"
#define SAVE_DIR "/home/pi/UCI-Digital-Waste-Bin/final/";
#define SCALE_MESSAGE_SIZE 6
#define RECONNECT_ATTEMPTS 5
#define UNIT_CONVERSION 16.0
#define SELECT_TIMEOUT 4 // unit is second

#define OPEN_SCALE_TRIAL 5  // how many times we try to open the scale before exit
#define CLOST_SCALE_TRIAL 6 // how many times we try to close the scale before exit

#define SCALE_SIGNATURE 255 // signature value of the first byte given by manufacturer

// open file descriptor to writing to the scale
int openScale(FILE *log)
{
    int scale;
    int count = 0;
    assert(log);
    while ((scale = open(SCALE_DEV_FILE, O_RDONLY)) < 0)
    {
        ++count;
        sleep(1);
    }

    if (count == OPEN_SCALE_TRIAL)
    {
        errorLogging("can't open scale\n", log);
        exit(-1);
    }
    else
    {
        struct termios scale_settings;

        // this is the default settings for the serial port
        // (port=None, baudrate=9600, bytesize=EIGHTBITS, parity=PARITY_NONE, stopbits=STOPBITS_ONE,
        // timeout=None, xonxoff=False, rtscts=False, write_timeout=None, dsrdtr=False, inter_byte_timeout=None)¶
        scale_settings.c_iflag &= ~(IGNBRK | BRKINT | ICRNL | INLCR | PARMRK | INPCK | ISTRIP | IXON);
        scale_settings.c_oflag = 0;

        scale_settings.c_cflag &= ~(CSIZE | PARENB);
        scale_settings.c_cflag |= CS8;
        scale_settings.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN | ISIG);

        if (!cfsetospeed(&scale_settings, B9600) && !tcsetattr(scale, TCSANOW, &scale_settings))
        {
            // setup successful
        }
        else
        {
            errorLogging("error while setting scale with error code \n", log);
            errorLogging(strerror(errno), log);
        }
    }
}

void errorLogging(char *message, FILE *log)
{
    // setting up for printing systemt time
    time_t rawTime;
    time(&rawTime);
    struct tm *curTime = localtime(&rawTime);

    char errMessage[100];
    errMessage[0] = '\0';

    strcat(errMessage, message);
    strcat(errMessage, " at ");
    strcat(errMessage, asctime(curTime));

    fprintf(log, "%s", errMessage);
    fprintf(log, "\n");
}

// read the scale from file descriptor, select set and timeout struct
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

    uint8_t digit1, digit2, digit3, digit4, digit5, digit6;
    int temp;
    float decimal_point, difference;
    static float prevResult = 0; // unit is ounces
    float result;
    const float weight_threshold = 0.1; //unit is ounces
    if (select(scale, inputSet, NULL, NULL, timeOut))
    {
        temp = read(scale, buffer, SCALE_MESSAGE_SIZE);
        if (temp != 6 && temp >= 0)
        {
            return ERROR_NOT_ENOUGH_READ_BYTES;
        }
        else if (temp < 0)
        {
            errorLogging("failed to read scale\n", log);
            errorLogging(strerror(errno), log);
            return ERROR_SCALE_READ_FAILED;
        }
        else
        {
            if (buffer[0] != SCALE_SIGNATURE)
            {
                return ERROR_INVALID_SCALE_READING;
            }
            else
            {
                if (prevBuffer[0] == buffer[2] && prevBuffer[1] == buffer[3] && prevBuffer[2] == buffer[4])
                {
                    return SCALE_WEIGHT_SAME;
                }
                else
                {
                    decimal_point = buffer[1] & 0b00000111;
                    isNegative = buffer[1] & 0b00100000;
                    isOverflow = buffer[1] & 0b10000000;

                    digit1 = buffer[2] & 0b00001111;
                    digit2 = buffer[2] & 0b11110000 >> 4;
                    digit3 = buffer[3] & 0b00001111;
                    digit4 = buffer[3] & 0b11110000 >> 4;
                    digit5 = buffer[4] & 0b00001111;
                    digit6 = buffer[4] & 0b11110000 >> 4;

                    prevBuffer[0] = buffer[2];
                    prevBuffer[1] = buffer[3];
                    prevBuffer[2] = buffer[4];

                    result = digit1 + digit2 * 10 + digit3 * 100 + digit4 * 1000 + digit5 * 10000 + digit6 * 100000;
                    result = (result / (pow(10, decimal_point - 1))) * UNIT_CONVERSION;
                    result = isNegative ? -result : result;

                    if (!tcflush(scale, TCIFLUSH))
                    {

                        // check for trashbag change
                        difference = result - (prevResult + weight_threshold);
                        if (difference > 0 || difference <= -5 * 16)
                        {
                            prevResult = result;
                            return difference + weight_threshold;
                        }
                        else
                        {
                            return SCALE_WEIGHT_SAME;
                        }
                    }
                    else
                    {
                        errorLogging("failed to flush file\n", log);
                    }
                }
            }
        }
    }
}

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
        errorLogging("failed to load scale\n", log);
        exit(-1);
    }
}

#ifdef DEBUG
#endif

int main(void)
{
    char saveDir[100] = SAVE_DIR;
    struct timeval timeOut;
    strcat(saveDir, MODE);
    strcat(saveDir, "/result.json");
    FILE *saveFile = fopen(saveDir, "w");
    assert(saveFile);

    char logDir[100] = SAVE_DIR;
    strcat(logDir, "/log");
    FILE *log = fopen(logDir, "a");
    assert(log);

    timeOut.tv_sec = SELECT_TIMEOUT;
    timeOut.tv_usec = 0;
    fd_set inputSet;
    int scale = openScale(log);
    float result;

    for (;;)
    {
        FD_ZERO(&inputSet);
        FD_SET(scale, &inputSet);
        result = readScale(scale, &inputSet, &timeOut, log);

        if (result == ERROR_INVALID_SCALE_READING)
        {
            errorLogging("invalid reading\n", log);
        }
        else if (result == ERROR_NOT_ENOUGH_READ_BYTES)
        {
            errorLogging("not enough read bytes\n", log);
        }
        else if (result == SCALE_WEIGHT_SAME)
        {
            // does nothing since the weight doesn't change
        }
        else
        {
            fprintf(saveFile, "%f", result);
        }
    }

    closeScale(scale, log);
    return 0;
}
