#include <Wire.h>

#define FX29_ADDRESS 0x28

#define LOAD_RANGE_LBF 10.0 

#define SPAN_COUNT_MIN 14300
#define SPAN_COUNT_TYP 15000
#define SPAN_COUNT_MAX 15700

#define FULL_SCALE_SPAN SPAN_COUNT_TYP

uint16_t ZERO_OFFSET = 1117;

void setup() {
  Serial.begin(115200);
  Wire.begin();
  
  Serial.println("FX29 Force Sensor - I2C Interface");
  Serial.print("I2C Address: 0x");
  Serial.println(FX29_ADDRESS, HEX);
  Serial.print("Load Range: ");
  Serial.print(LOAD_RANGE_LBF);
  Serial.println(" lbf");
  Serial.println("----------------------------");
  
  delay(2);
  ZERO_OFFSET = calibrateZero();
  Serial.print("New zero offset: "); Serial.println(ZERO_OFFSET);
}

void loop() {
  uint16_t rawCounts = readFX29();
  
  if (rawCounts != 0xFFFF) { // Check if read was successful
    float force = convertToForce(rawCounts);
    // float percentage = convertToPercentage(rawCounts);
    
    // Serial.print("Raw Counts:");
    Serial.println(rawCounts); 
    // Serial.print(",");
    // Serial.print(" (0x");
    // Serial.print(rawCounts, HEX);
    // Serial.print("min:"); Serial.print(0); Serial.print(",");
    // Serial.print("max:"); Serial.print(15000); Serial.print("\n");
    // Serial.print("Force:");
    // Serial.println(force, 3);
    // Serial.print(" lbf  |  Load: ");
    // Serial.print(percentage, 1);
    // Serial.println("%");
  } else {
    Serial.println(999999); //this can easily be found and removed from the data.
  }
  delay(3); //This number needs to be checked. We want to run this as fast as possible.
}

/*
 * Read 14-bit force measurement from FX29
 * Returns raw count value (0-16383) or 0xFFFF on error
 */
uint16_t readFX29() {
  Wire.requestFrom(FX29_ADDRESS, 2); // Request 2 bytes
  
  if (Wire.available() >= 2) {
    uint8_t msb = Wire.read(); // Most significant byte
    uint8_t lsb = Wire.read(); // Least significant byte
    
    // Combine bytes into 14-bit value (bits 13:0 contain data)
    uint16_t rawValue = ((uint16_t)msb << 8) | lsb;
    
    // Mask to 14 bits (in case upper bits are not zero)
    rawValue &= 0x3FFF;
    
    return rawValue;
  }
  
  return 0xFFFF; // Error indicator
}

/*
 * Convert raw counts to force in pounds-force
 * Formula from datasheet: OUTPUT = ((FORCE * RANGE) / 14000) + 1000
 * Solving for FORCE: FORCE = ((OUTPUT - ZERO_OFFSET) * 14000) / SPAN_COUNT
 */
float convertToForce(uint16_t counts) {
  float normalized = (float)(counts - ZERO_OFFSET);
  float force = (normalized * LOAD_RANGE_LBF) / (FULL_SCALE_SPAN - ZERO_OFFSET);
  
  return force;
}

float convertToPercentage(uint16_t counts) {
  if (counts < ZERO_OFFSET) return 0.0;
  
  float normalized = (float)(counts - ZERO_OFFSET);
  float percentage = (normalized / (FULL_SCALE_SPAN - ZERO_OFFSET)) * 100.0;
  
  // Clamp to 0-100%
  if (percentage < 0.0) percentage = 0.0;
  if (percentage > 100.0) percentage = 100.0;
  
  return percentage;
}

uint16_t calibrateZero() {
  uint32_t sum = 0;
  int numSamples = 50;
  
  Serial.println("Calibrating zero... Remove all loads.");
  delay(1000);
  
  for (int i = 0; i < numSamples; i++) {
    uint16_t reading = readFX29();
    if (reading != 0xFFFF) {
      sum += reading;
    }
    delay(20);
  }
  
  uint16_t newZero = sum / numSamples;
  return newZero;
}