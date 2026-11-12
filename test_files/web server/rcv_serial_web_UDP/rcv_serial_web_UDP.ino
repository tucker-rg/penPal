#include <DynamixelShield.h>
#include <SPI.h>
#include <WiFiNINA.h>
#include "arduino_secrets.h" 
#include <WiFiUdp.h>

WiFiUDP udp;
const int UDP_PORT = 4210;  // Pick any unused port (must match Android)
char udpBuffer[128];        // Buffer for incoming data

///////please enter your sensitive data in the Secret tab/arduino_secrets.h
char ssid[] = SECRET_SSID;        // your network SSID (name)
char pass[] = SECRET_PASS;    // your network password (use for WPA, or use as key for WEP)
int keyIndex = 0;                // your network key index number (needed only for WEP)

int status = WL_IDLE_STATUS;
WiFiServer server(80);

// Dynamixel setup
const uint8_t DXL0 = 1;
const uint8_t DXL1 = 4;
const uint8_t DXL2 = 7;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

using namespace ControlTableItem;

float input_0 = 0.0;
float input_1 = 0.0;
float input_2 = 0.0;

void setup() {
  Serial.begin(9600);
  while (!Serial);

  udp.begin(UDP_PORT);
  Serial.print("Listening for UDP on port ");
  Serial.println(UDP_PORT);

  Serial.println("Access Point Web Server");

  // check for the WiFi module:
  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("Communication with WiFi module failed!");
    // don't continue
    while (true);
  }

  String fv = WiFi.firmwareVersion();
  if (fv < WIFI_FIRMWARE_LATEST_VERSION) {
    Serial.println("Please upgrade the firmware");
  }

  // print the network name (SSID);
  Serial.print("Creating access point named: ");
  Serial.println(ssid);

  // WiFi Access Point
  status = WiFi.beginAP(ssid, pass);
  if (status != WL_AP_LISTENING) {
    Serial.println("Creating access point failed");
    // don't continue
    while (true);
  }

  // wait 10 seconds for connection:
  delay(10000);

  // start the web server on port 80
  server.begin();

  // you're connected now, so print out the status
  printWiFiStatus();


  // Dynamixel setup
  dxl.begin(1000000);
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);
  dxl.ping(DXL0);
  dxl.ping(DXL1);
  dxl.ping(DXL2);
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

unsigned long batchStartTime = 0;

void loop() {
  int packetSize = udp.parsePacket();
  if (packetSize) {
    int len = udp.read(udpBuffer, 128);
    if (len > 0) {
      udpBuffer[len] = 0;
      String command = String(udpBuffer);

      Serial.println("Batch received:");
      Serial.println(command);

      // Start time anchor for this batch
      batchStartTime = millis();

      int start = 0;
      while (start < command.length()) {
        int sep = command.indexOf(';', start);
        if (sep == -1) sep = command.length();
        String sub = command.substring(start, sep);

        // === Parse t,0,1,2 values ===
        float t = getValueFromUDP(sub, "t");
        float val0 = getValueFromUDP(sub, "0");
        float val1 = getValueFromUDP(sub, "1");
        float val2 = getValueFromUDP(sub, "2");

        // === Wait until timestamp matches ===
        while (millis() - batchStartTime < t) {
          delay(1);  // wait precisely
        }

        // === Execute motor command ===
        dxl.setGoalPosition(DXL0, val0, UNIT_DEGREE);
        dxl.setGoalPosition(DXL1, val1, UNIT_DEGREE);
        dxl.setGoalPosition(DXL2, val2, UNIT_DEGREE);

        start = sep + 1;
      }
    }
  }
}

void handleMoveRequest(String req) {
  float val0 = getValueFromRequest(req, "0");
  float val1 = getValueFromRequest(req, "1");
  float val2 = getValueFromRequest(req, "2");

  input_0 = val0;
  input_1 = val1;
  input_2 = val2;

  Serial.print("Received: ");
  Serial.print(val0); Serial.print(", ");
  Serial.print(val1); Serial.print(", ");
  Serial.println(val2);

  dxl.setGoalPosition(DXL0, input_0, UNIT_DEGREE);
  dxl.setGoalPosition(DXL1, input_1, UNIT_DEGREE);
  dxl.setGoalPosition(DXL2, input_2, UNIT_DEGREE);
}

float getValueFromRequest(String req, String key) {
  int start = req.indexOf(key + "=");
  if (start == -1) return 0;
  int end = req.indexOf('&', start);
  if (end == -1) end = req.indexOf(' ', start);  // handle end of line
  String valStr = req.substring(start + key.length() + 1, end);
  return valStr.toFloat();
}

float getValueFromUDP(String msg, String key) {
  int start = msg.indexOf(key + ":");
  if (start == -1) return 0;
  int end = msg.indexOf(',', start);
  if (end == -1) end = msg.length();  // last key
  String valStr = msg.substring(start + key.length() + 1, end);
  return valStr.toFloat();
}

void printWiFiStatus() {
  // print the SSID of the network you're attached to:
  Serial.print("SSID: ");
  Serial.println(WiFi.SSID());

  // print your WiFi shield's IP address:
  IPAddress ip = WiFi.localIP();
  Serial.print("IP Address: ");
  Serial.println(ip);

  // print where to go in a browser:
  Serial.print("To see this page in action, open a browser to http://");
  Serial.println(ip);

}
