#include <DynamixelShield.h>
#include <SPI.h>
#include <WiFiNINA.h>
#include "arduino_secrets.h" 

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

void loop() {
  WiFiClient client = server.available();
  if (client) {
    String request = "";
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        request += c;
        if (request.endsWith("\r\n\r\n")) break;
      }
    }

    if (request.indexOf("GET /move?") != -1) {
      handleMoveRequest(request);
    }

    client.println("HTTP/1.1 200 OK");
    client.println("Content-Type: text/html");
    client.println();
    client.println("Command received.");
    client.stop();
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
