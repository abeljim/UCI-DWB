/**
 * @brief scale emulator
 * @file serial_test.ino
 * @author Khoi Trinh
 *
 * Used to emulate a real scale
 */

#define SENDING_PERIOD_MS 4000  //!< should be decreased to increase pressure on the code

void setup()
{
  Serial.begin(9600);
}

void loop()
{
  delay(SENDING_PERIOD_MS);
  printScaleMessage();
}

/**
 * @brief print scale message
 *
 * Consult the manual for detailed bit ordering, use program like moserial to see the bit patterns
 * sent, the Arduino usually appears as /dev/ttyACM0 or /dev/ttyUSB0
 */
void printScaleMessage(void)
{
  Serial.write(255);  // message flag of the scale
  Serial.write(36);   // 3rd decimal place, scale stable

  // write the number 617593
  Serial.write(147);
  Serial.write(117);
  Serial.write(97);

  Serial.write(1);  // lbs as unit
}
