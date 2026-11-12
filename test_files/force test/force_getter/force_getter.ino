#include <Wire.h>

#define DEV_ADDR 0x28
const int MIN_COUNTS = 1638;
const int MAX_COUNTS = 14745;

void setup() {
  Serial.begin(115200);
  Wire.begin();
}

void loop() {
  Wire.requestFrom(DEV_ADDR, (uint8_t)4);

  if (Wire.available() >= 4) {
    uint8_t b0 = Wire.read();
    uint8_t b1 = Wire.read();
    Wire.read(); // ignore temperature MSB
    Wire.read(); // ignore temperature LSB

    uint16_t raw = ((uint16_t)(b0 & 0x3F) << 8) | b1;

    Serial.println(raw);  // <-- this is ALL we send to Processing
  }

  delay(20); // 50 Hz sample rate
}
