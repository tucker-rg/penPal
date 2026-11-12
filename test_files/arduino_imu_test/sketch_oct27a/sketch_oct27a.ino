#include <Wire.h>
#include <SPI.h>
#include <Adafruit_BNO08x.h>
#include <Adafruit_Sensor.h>
#include <sh2.h>
#include <sh2_SensorValue.h>

#define BNO08X_CS   4    // Chip Select
#define BNO08X_INT  3    // Interrupt pin
#define BNO08X_RST  2    // Optional (reset)

Adafruit_BNO08x bno08x = Adafruit_BNO08x(BNO08X_RST);

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(10);
  Serial.println("\n=== BNO085 SPI Test ===");

  if (!bno08x.begin_SPI(BNO08X_CS, BNO08X_INT)) {
    Serial.println("❌ Could not find BNO085! Check wiring.");
    while (1) delay(10);
  }

  Serial.println("✅ BNO085 found over SPI!");
  delay(100);

  // Enable rotation vector (quaternion-based orientation)
  if (!bno08x.enableReport(SH2_ROTATION_VECTOR)) {
    Serial.println("❌ Failed to enable rotation vector report!");
  } else {
    Serial.println("✅ Rotation vector report enabled.");
  }

  Serial.println("Starting to read orientation data...\n");
}

void loop() {
  sh2_SensorValue_t sensorValue;

  // Check if new data is available
  if (bno08x.getSensorEvent(&sensorValue)) {
    if (sensorValue.sensorId == SH2_ROTATION_VECTOR) {
      float w = sensorValue.un.rotationVector.real;
      float x = sensorValue.un.rotationVector.i;
      float y = sensorValue.un.rotationVector.j;
      float z = sensorValue.un.rotationVector.k;

      // Quaternion → Euler conversion
      float ysqr = y * y;

      float t0 = +2.0 * (w * x + y * z);
      float t1 = +1.0 - 2.0 * (x * x + ysqr);
      float roll = atan2(t0, t1);

      float t2 = +2.0 * (w * y - z * x);
      t2 = constrain(t2, -1.0, 1.0);
      float pitch = asin(t2);

      float t3 = +2.0 * (w * z + x * y);
      float t4 = +1.0 - 2.0 * (ysqr + z * z);
      float yaw = atan2(t3, t4);

      // Convert radians to degrees
      roll *= 180.0 / PI;
      pitch *= 180.0 / PI;
      yaw *= 180.0 / PI;

      Serial.print("Yaw: ");   Serial.print(yaw, 2);
      Serial.print("  Pitch: "); Serial.print(pitch, 2);
      Serial.print("  Roll: ");  Serial.println(roll, 2);
    }
  }
}
