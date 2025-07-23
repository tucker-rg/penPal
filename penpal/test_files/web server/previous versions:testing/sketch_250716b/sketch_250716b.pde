import http.requests.*;  // You'll need the HTTP Requests for Processing library

String arduinoIP = "http://192.168.4.1";  // Replace with the IP printed by your Arduino
boolean ledOn = false;

void setup() {
  size(200, 100);
  textAlign(CENTER, CENTER);
  textSize(20);
}

void draw() {
  background(ledOn ? color(0, 200, 0) : color(200, 0, 0));
  fill(255);
  text(ledOn ? "LED ON" : "LED OFF", width/2, height/2);
}

void mousePressed() {
  ledOn = !ledOn;

  String url = arduinoIP + (ledOn ? "/H" : "/L");
  GetRequest get = new GetRequest(url);
  get.send();  // sends the GET request to your Arduino

  println("Sent request: " + url);
}
