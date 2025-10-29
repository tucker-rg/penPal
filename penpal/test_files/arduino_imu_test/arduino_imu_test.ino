#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO08x.h>

Adafruit_BNO08x  bno08x = Adafruit_BNO08x();

sh2_SensorValue_t sensorValue;

void setup() {
  Serial.begin(115200);
  while (!Serial) delay(100);
  
  Serial.println("Adafruit BNO085 test!");

  if (!bno08x.begin_I2C()) {
    Serial.println("Failed to find BNO085 chip");
    while (1) delay(10);
  }

  Serial.println("BNO085 found!");

  // Enable reports
  bno08x.enableReport(SH2_ACCELEROMETER);
  bno08x.enableReport(SH2_GYROSCOPE_CALIBRATED);
  bno08x.enableReport(SH2_ROTATION_VECTOR);
}

// calibration code
// void loop() {
//   sh2_SensorValue_t event;
//   if (bno08x.getSensorEvent(&event)) {
//     if (event.sensorId == SH2_ROTATION_VECTOR) {
//       uint8_t systemCal, gyroCal, accelCal, magCal;
//       bno08x.getCalibration(&systemCal, &gyroCal, &accelCal, &magCal);

//       Serial.print("System:");
//       Serial.print(systemCal);
//       Serial.print(" Gyro:");
//       Serial.print(gyroCal);
//       Serial.print(" Accel:");
//       Serial.print(accelCal);
//       Serial.print(" Mag:");
//       Serial.println(magCal);
//     }
//   }
// }

void loop() {
  if (bno08x.getSensorEvent(&sensorValue)) {
    switch (sensorValue.sensorId) {
      // case SH2_ACCELEROMETER:
      //   Serial.print("Accel: ");
      //   Serial.print(sensorValue.un.accelerometer.x);
      //   Serial.print(", ");
      //   Serial.print(sensorValue.un.accelerometer.y);
      //   Serial.print(", ");
      //   Serial.println(sensorValue.un.accelerometer.z);
      //   break;

      // case SH2_GYROSCOPE_CALIBRATED:
      //   Serial.print("Gyro: ");
      //   Serial.print(sensorValue.un.gyroscope.x);
      //   Serial.print(", ");
      //   Serial.print(sensorValue.un.gyroscope.y);
      //   Serial.print(", ");
      //   Serial.println(sensorValue.un.gyroscope.z);
      //   break;

      case SH2_ROTATION_VECTOR:
      //   Serial.print("Quat: ");
      //   Serial.print(sensorValue.un.rotationVector.real);
      //   Serial.print(", ");
      //   Serial.print(sensorValue.un.rotationVector.i);
      //   Serial.print(", ");
      //   Serial.print(sensorValue.un.rotationVector.j);
      //   Serial.print(", ");
      //   Serial.println(sensorValue.un.rotationVector.k);
      //   break;

          float w = sensorValue.un.rotationVector.real;
          float x = sensorValue.un.rotationVector.i;
          float y = sensorValue.un.rotationVector.j;
          float z = sensorValue.un.rotationVector.k;

          // Convert quaternion to Euler angles (radians)
          float ysqr = y * y;

          float t0 = +2.0 * (w * x + y * z);
          float t1 = +1.0 - 2.0 * (x * x + ysqr);
          float roll = atan2(t0, t1);

          float t2 = +2.0 * (w * y - z * x);
          t2 = t2 > 1.0 ? 1.0 : t2;
          t2 = t2 < -1.0 ? -1.0 : t2;
          float pitch = asin(t2);

          float t3 = +2.0 * (w * z + x * y);
          float t4 = +1.0 - 2.0 * (ysqr + z * z);
          float yaw = atan2(t3, t4);

          // Convert to degrees
          roll *= 180.0 / PI;
          pitch *= 180.0 / PI;
          yaw *= 180.0 / PI;

          Serial.print("Yaw: "); Serial.print(yaw);
          Serial.print(" Pitch: "); Serial.print(pitch);
          Serial.print(" Roll: "); Serial.println(roll);
    }
  }
  delay(10);
}
