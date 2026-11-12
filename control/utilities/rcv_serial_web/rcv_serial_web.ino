#include <DynamixelShield.h>
#include <Bounce2.h>

#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #include <SoftwareSerial.h>
  SoftwareSerial soft_serial(7, 8);
  #define DEBUG_SERIAL soft_serial
#elif defined(ARDUINO_SAM_DUE) || defined(ARDUINO_SAM_ZERO)
  #define DEBUG_SERIAL SerialUSB    
#else
  #define DEBUG_SERIAL Serial
#endif

// new web server stuff
#include <SPI.h>
#include <WiFiNINA.h>
#include "arduino_secrets.h" 
char ssid[] = "arduinowifi";        // your network SSID (name)
char pass[] = "password";    // your network password (use for WPA, or use as key for WEP)
int keyIndex = 0;                // your network key index number (needed only for WEP)

int status = WL_IDLE_STATUS;
WiFiServer server(80);
// end of web server stuff

Bounce bounce = Bounce();

const uint8_t DXL0 = 1;
const uint8_t DXL1 = 4;
const uint8_t DXL2 = 7;
const float DXL_PROTOCOL_VERSION = 2.0;
DynamixelShield dxl;

using namespace ControlTableItem;

unsigned long controlTimer;
unsigned long lastTimer;
unsigned long INTERVAL = 10;

float input_0 = 0.0;
float input_1 = 0.0;
float input_2 = 0.0;

void setup() {
  Serial.begin(57600);  // For communication with Processing
  while (!Serial) {
    ; // wait for serial port to connect. Needed for native USB port only
  }

  // web server stuff
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
  // Create open network. Change this line if you want to create an WEP network:
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
  // end of web server stuff

  dxl.begin(1000000); // instead of 57600
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);

  Serial.println("You're connected to the network");

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
  // compare the previous status to the current status
  if (status != WiFi.status()) {
    // it has changed update the variable
    status = WiFi.status();

    if (status == WL_AP_CONNECTED) {
      // a device has connected to the AP
      Serial.println("Device connected to AP");
    } else {
      // a device has disconnected from the AP, and we are back in listening mode
      Serial.println("Device disconnected from AP");
    }
  }
  
  WiFiClient client = server.available();   // listen for incoming clients

  if (client) {                             // if you get a client,
    Serial.println("new client");           // print a message out the serial port
    String currentLine = "";                // make a String to hold incoming data from the client
    while (client.connected()) {            // loop while the client's connected
      delayMicroseconds(10);                // This is required for the Arduino Nano RP2040 Connect - otherwise it will loop so fast that SPI will never be served.
      if (client.available()) {             // if there's bytes to read from the client,
        char c = client.read();             // read a byte, then
        Serial.write(c);                    // print it out to the serial monitor
        if (c == '\n') {                    // if the byte is a newline character

          // if the current line is blank, you got two newline characters in a row.
          // that's the end of the client HTTP request, so send a response:
          if (currentLine.length() == 0) {
            // HTTP headers always start with a response code (e.g. HTTP/1.1 200 OK)
            // and a content-type so the client knows what's coming, then a blank line:
            client.println("HTTP/1.1 200 OK");
            client.println("Content-type:text/html");
            client.println();

            // // the content of the HTTP response follows the header:
            // client.print("Click <a href=\"/H\">here</a> turn the LED on<br>");
            // client.print("Click <a href=\"/L\">here</a> turn the LED off<br>");

            // // The HTTP response ends with another blank line:
            // client.println();
            // break out of the while loop:
            break;
          }
          else {      // if you got a newline, then clear currentLine:
            currentLine = "";
          }
        }
        else if (c != '\r') {    // if you got anything else but a carriage return character,
          currentLine += c;      // add it to the end of the currentLine
        }

        // Check to see if the client request was "GET /H" or "GET /L":
        if (currentLine.endsWith("done")) {
          receiveDataFromProcessing(currentLine);
        }
      }
    }
    // close the connection:
    client.stop();
    Serial.println("client disconnected");
  }

  controlTimer = millis();
  
  if (controlTimer - lastTimer > INTERVAL) {
    lastTimer = controlTimer;
    dxl.setGoalPosition(DXL0, input_0, UNIT_DEGREE);
    dxl.setGoalPosition(DXL1, input_1, UNIT_DEGREE);
    dxl.setGoalPosition(DXL2, input_2, UNIT_DEGREE);
  }

  
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

    Serial.print("Received - Input 0: "); Serial.print(input_0);
    Serial.print(", Input 1: "); Serial.print(input_1);
    Serial.print(", Input 2: "); Serial.println(input_2);
  }
}
