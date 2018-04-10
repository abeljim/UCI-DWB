"""
scale.py

Description: [DESCRIPTION]

Created on Apr 25, 2017

Data Format: Every message includes 6 bytes;
    a. No. 1: D0-D7 = 0FFH (Message Flag)
    b. No. 2: D0-D2 = Decimal point (0-5)
        D3-D4 = Current mode: 00-Weight; 01-Count; 10-Percent
        D5 = 1 means weight is negative, otherwise positive
        D6 = 1 means weight is stable, otherwise unstable
        D7 = 1 means weight is overflow, otherwise normal
    c. No. 3: D0-D7 = BCD1 (LSB)
    d. No. 4: D0-D7 = BCD2 (MSB)
    e. No. 5: D0-D7 = BCD3 (HSB)


Bytes 3-5 to Digits
D2: 0001 D1: 0000
D4: 0000 D3: 0000
D6: 0000 D5: 0000

IMPORTANT: Assumptions made on the hardware
Assuming that the scale runs in STB mode(send when stable)
Assuming that the units are in lbs
"""
import serial
# import time
import collections
import time
Reading = collections.namedtuple(
    'Reading', ['mode', 'stable', 'overflow', 'weight', 'units'])
baud_rate = 9600  # scale supports 1200, 2400, 4800, 9600

white = (255, 255, 255)
black = (0, 0, 0)


class Scale:
    def __init__(self) -> None:
        # create serial object using pyserial API
        self.ser = serial.Serial('/dev/SCALE', baud_rate)

        # safeguard, close port if not already closed
        if (self.ser.isOpen()):
            self.close()

        # open the port
        self.open()

        # last recorded stable value in lbs
        self.last_value = 0

        # last recorded raw value
        #self.raw = [0, 0, 0, 0, 0, 0]

        # minimum increase in weight to be counted as increased
        self.weight_threshold = 0.006

        self.trashbag_replaced_counter = 0
    # function to process data, input is 6 bytes read from serial port
    # ie scale.ser.read(6), meaning of each byte described at the top

    def check(self, raw: bytes) -> Reading:
        # flush all unread inputs to avoid overloading the port
        # with too much data
        self.ser.reset_input_buffer()

        # # this is the preliminary quick check to make sure that the
        # # value did change from last time
        # if not(raw[2] == self.raw[2] and raw[3] == self.raw[3] and raw[1] == self.raw[1] and raw[4] == self.raw[4]):

        # save the raw value for comparison next time
        #self.raw = raw

        # scale data parsing starts here

        decimal_point = raw[1] & 0b111
        # current_mode = (raw[1] & 0b11000) >> 3
        negative = (raw[1] & 0b100000)

        # self.stable = (raw[1] & 0b1000000) >> 6
        # overflow = (raw[1] & 0b10000000) >> 7

        # TODO: Handle third byte
        digit1 = raw[2] & 0b1111
        digit2 = (raw[2] & 0b11110000) >> 4

        # TODO: Handle fourth byte
        digit3 = raw[3] & 0b1111
        digit4 = (raw[3] & 0b11110000) >> 4

        # TODO: Handle fifth byte
        digit5 = raw[4] & 0b1111
        digit6 = (raw[4] & 0b11110000) >> 4

        # calculate the total value from interpreted digits
        result = float(digit1) + digit2 * 10 + digit3 * 100 + \
            digit4 * 1000 + digit5 * 10000 + digit6 * 100000
        result /= float(10 ** (decimal_point - 1))  # more precision

        result = result * (-1.0) if negative else result

        # Convert from lbs to ounce, which will be multiplied
        # with a conversion factor to determine the ounces of carbon
        # emission saved
        result *= 16

        # this is a check implemented to detect if the
        # trashbag has been replaced, if replaced
        # then reset the max value to zero
        if(self.last_value > 10 and result < 0.5):
            self.trashbag_replaced_counter += 1
            if self.trashbag_replaced_counter == 5:
                self.trashbag_replaced_counter = 0
                self.last_value = 0

        # if the current reading is bigger than last reading by a value
        # then output the difference
        if (self.last_value + self.weight_threshold) < result:

            difference = float(result) - float(self.last_value)
            self.last_value = result

            return difference  # return weight change between this and the last stable read in lbs

        else:
            return 0

    def open(self) -> None:
        self.ser.open()

    def close(self) -> None:
        self.ser.close()


if __name__ == '__main__':

    s = Scale()
    with open('/home/pi/UCI-Digital-Waste-Bin/v.01/result.json', 'w') as a:
        a.write("<result>" + "0" + "</result>")
    while(True):
        if s.ser.in_waiting >= 6:
            reading = s.ser.read(6)
            while((len(reading) != 6 or reading[0] != 0xff)):
                s.ser.close()
                s.ser.open()
                reading = s.ser.read(6)
            res = s.check(reading)
            if(res):
                with open('/home/pi/UCI-Digital-Waste-Bin/v.01/result.json', 'w') as a:
                    a.write("<result>" + str(res) + "</result>")
                print(res)
        time.sleep(0.1)
    s.close()
