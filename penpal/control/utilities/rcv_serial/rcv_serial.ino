#include <Adafruit_BNO08x.h>
#include <sh2.h>
#include <sh2_SensorValue.h>
#include <sh2_err.h>
#include <sh2_hal.h>
#include <sh2_util.h>
#include <shtp.h>

#include <DynamixelShield.h>
#include <Bounce2.h>
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO08x.h>
#include <SPI.h>

#define BNO08X_CS   4
#define BNO08X_INT  7
#define BNO08X_RST  6

Adafruit_BNO08x bno08x = Adafruit_BNO08x(BNO08X_RST);

sh2_SensorValue_t sensorValue;

#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #include <SoftwareSerial.h>
  SoftwareSerial soft_serial(7, 8);
  #define DEBUG_SERIAL soft_serial
#elif defined(ARDUINO_SAM_DUE) || defined(ARDUINO_SAM_ZERO)
  #define DEBUG_SERIAL SerialUSB    
#else
  #define DEBUG_SERIAL Serial
#endif

Bounce bounce = Bounce();

const uint8_t DXL0 = 4;
const uint8_t DXL1 = 7;
const uint8_t DXL2 = 6;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

using namespace ControlTableItem;

unsigned long controlTimer;
unsigned long lastReceivedTimer;
unsigned long lastSentTimer;
unsigned long INTERVAL = 10;

float input_0 = 0.0;
float input_1 = 0.0;
float input_2 = 0.0;

void setup() {
  Serial.begin(115200);  // For communication with Processing
  dxl.begin(1000000); // instead of 57600
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);

  SPI.begin();
  delay(10); 
  
  while (!Serial) delay(10);
  Serial.println("You're connected to the pen");

  if (!bno08x.begin_SPI(BNO08X_CS, BNO08X_INT)) {
    Serial.println("❌ Could not find BNO085! Check wiring.");
    while (1) delay(10);
  }

  Serial.println("BNO085 found! (SPI)");
  delay(100);

  dxl.ping(DXL0);
  dxl.ping(DXL1);
  dxl.ping(DXL2);

  // bno08x.enableReport(SH2_ACCELEROMETER);
  // bno08x.enableReport(SH2_GYROSCOPE_CALIBRATED);
  if (!bno08x.enableReport(SH2_ROTATION_VECTOR)) {
    Serial.println("❌ Failed to enable rotation vector report!");
  } else {
    Serial.println("✅ Rotation vector report enabled.");
  }

  Serial.println("Starting to read orientation data...\n");
  dxl.torqueOff(DXL0);
  dxl.torqueOff(DXL1);
  dxl.torqueOff(DXL2);
  dxl.setOperatingMode(DXL0, OP_POSITION);
  dxl.setOperatingMode(DXL1, OP_POSITION);
  dxl.setOperatingMode(DXL2, OP_POSITION);
  dxl.torqueOn(DXL0);
  dxl.torqueOn(DXL1);
  dxl.torqueOn(DXL2);
}

void loop() {
  unsigned long now = millis();

    sh2_SensorValue_t sensorValue;


  // Update servo goal positions every 10 ms
  if (now - lastReceivedTimer >= INTERVAL) {
    lastReceivedTimer = now;
    dxl.setGoalPosition(DXL0, input_0, UNIT_DEGREE);
    dxl.setGoalPosition(DXL1, input_1, UNIT_DEGREE);
    // dxl.setGoalPosition(DXL2, input_2, UNIT_DEGREE);
    dxl.setGoalPosition(DXL2, input_2, UNIT_DEGREE); // to account for weirdness with this new motor six
  }

  // Read IMU and print every 10 * 5 ms if data available
  if (now - lastSentTimer >= INTERVAL * 5) {
    lastSentTimer = now;

    // Only process if data is ready (non-blocking)
    if (bno08x.wasReset()) {
      Serial.println("IMU was reset!");
      bno08x.enableReport(SH2_ROTATION_VECTOR);
    }

    if (bno08x.getSensorEvent(&sensorValue)) {
      if (sensorValue.sensorId == SH2_ROTATION_VECTOR) {
        float w = sensorValue.un.rotationVector.real;
        float x = sensorValue.un.rotationVector.i;
        float y = sensorValue.un.rotationVector.j;
        float z = sensorValue.un.rotationVector.k;

        // Quaternion → Euler
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

        // Convert to degrees
        roll *= 180.0 / PI;
        pitch *= 180.0 / PI;
        yaw *= 180.0 / PI;

        Serial.print("Yaw: "); Serial.print(yaw, 2);
        Serial.print(" Pitch: "); Serial.print(pitch, 2);
        Serial.print(" Roll: "); Serial.println(roll, 2);
      }
    }
  }

  // Always check for new input
  receiveDataFromProcessing();
}

// Read serial data from Processing and update inputs
void receiveDataFromProcessing() {
  if (Serial.available() > 0) {
    String receivedData = Serial.readStringUntil('\n');
    parseReceivedData(receivedData);
  }
}

// Parse the received string in the format "0:value,1:value,2:value"
void parseReceivedData(String data) {
  int index0 = data.indexOf("0:");
  int index1 = data.indexOf("1:");
  int index2 = data.indexOf("2:");

  if (index0 != -1 && index1 != -1 && index2 != -1) {
    input_0 = data.substring(index0 + 2, index1 - 1).toFloat();
    input_1 = data.substring(index1 + 2, index2 - 1).toFloat();
    input_2 = data.substring(index2 + 2).toFloat();

    // Serial.print("Received - Input 0: "); Serial.print(input_0);
    // Serial.print(", Input 1: "); Serial.print(input_1);
    // Serial.print(", Input 2: "); Serial.println(input_2);
  }
}
