import controlP5.*;
import java.util.*;

ControlP5 cp5;

class TimedPoint {
  PVector pos;
  float time;
  TimedPoint(PVector p, float t) {
    pos = p;
    time = t;
  }
}

//ArrayList<PVector> points = new ArrayList<PVector>();  // Store drawing

// New for timed points
ArrayList<TimedPoint> stroke = new ArrayList<TimedPoint>();

int strokeStartTime;
boolean drawing = true;
boolean replaying = false;
boolean revReplaying = false;
int replayStartTime;
int replayIndex;
int revReplayStartTime;
int revReplayIndex;

// int speed = 3;

int mode = 1;
// 0: copy motion; 1: repeat forward/reverse

Table lookup;
PVector lastSent = new PVector(-9999, -9999);
String lastCommand = "";

String arduinoIP = "http://192.168.4.1";

void setup() {
  size(400, 400);
  
  cp5 = new ControlP5(this);
  
  // Load lookup table
  lookup = loadTable("lookup_table.csv", "header");

  println("Setup complete.");
}

void draw() {
  background(255);

  stroke(0);
  noFill();
  beginShape();
  for (TimedPoint tp : stroke) {
    PVector p = tp.pos;
    vertex(p.x, p.y);
  }
  endShape(); 
  
  //println("stroke.size(): " + stroke.size());
  
  if (mode == 1) {
    manageMode1();
  }
}

void manageMode1() {
  if (replaying && replayIndex < stroke.size()) {
    println("replaying point " + replayIndex + " of " + stroke.size());
    int elapsed = millis() - replayStartTime;
    TimedPoint nextPoint = stroke.get(replayIndex);
    
    if (elapsed >= nextPoint.time) {
      // Draw the point
      sendMotorCommand(nextPoint.pos.x, nextPoint.pos.y);
      
      // Move to the next point
      replayIndex++;
    }
  }
  
  if (replaying && replayIndex == stroke.size()) {
    println("done replaying, now revReplaying");
    drawing = false;
    replaying = false;
    revReplaying = true;
    revReplayStartTime = millis();
    revReplayIndex = stroke.size() - 1;
  }
  
  if (revReplaying && revReplayIndex >= 0) {
    println("revReplaying point " + revReplayIndex + " of " + stroke.size());
    int elapsed = millis() - replayStartTime;
    TimedPoint nextPoint = stroke.get(revReplayIndex);
    
    if (elapsed >= nextPoint.time) {
      // Draw the point
      sendMotorCommand(nextPoint.pos.x, nextPoint.pos.y);
      
      // Move to the next point
      revReplayIndex--;
    }
  }
  
  if (revReplaying && revReplayIndex < 0) {
    println("done revReplaying, now replaying");
    drawing = false;
    replaying = true;
    revReplaying = false;
    replayStartTime = millis();
    replayIndex = 0;
  }
}

void mousePressed() {
  println("drawing now");
  stroke.clear();
  strokeStartTime = millis();  // reset stroke start time
  drawing = true;
  replaying = false;
  revReplaying = false;
  
}

void mouseDragged() {
  if (drawing) {
    PVector pos = new PVector(mouseX, mouseY);
    float t = millis() - strokeStartTime;
    stroke.add(new TimedPoint(pos, t));
    
    if (mode == 0) {
      sendMotorCommand(pos.x, pos.y);
    }
  }
}

void mouseReleased() {
  if (mode == 0) {
    println("done drawing");
  }
  if (mode == 1) {
    println("done drawing, now replaying");
  }
  
  drawing = false;
  replaying = true;
  revReplaying = false;
  
  replayStartTime = millis();
  replayIndex = 0;
}

// Normalize mouseX/mouseY to match lookup table range
void sendMotorCommand(float x, float y) {
  TableRow row = null;
  
  println("x: " + x);
 
  float realX = map(x, 0, width, -12.5, 12.5);
  float realY = map(y, 0, height, -12.5, 12.5);

  row = getExactRow(realX, realY);
  
  if (row != null) {
    int s0 = row.getInt("servo_0");
    int s1 = row.getInt("servo_1");
    int s2 = row.getInt("servo_2");

    String data = "0:" + s0 + ",1:" + s1 + ",2:" + s2 + "\n";

    if (!data.equals(lastCommand)) {
      sendViaHttp(data);
      print("Sent: " + data);
      lastCommand = data;
    } else {
      println("Skipping duplicate command: " + data.trim());
    }
  } else {
    //println("No exact match found in table for rounded coordinates.");
  }
}

// Find closest matching X, Y in table
TableRow getExactRow(float x, float y) {
  float rx = (round(x * 2) / 2.0);  // round to nearest 0.5 
  float ry = (round(y * 2) / 2.0) * -1; // flip this one

  //println("Rounded to: X = " + rx + ", Y = " + ry);

  for (TableRow row : lookup.rows()) {
    if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
      return row;
    }
  }

  return null;  // no exact match found
}

// Find closest matching X, Y in table
TableRow getExactRowUpper(float x, float y) {
  float rx = round(x / 6.25) * 6.25;
  float ry = round(y / 6.25) * 6.25 * -1; // flip this one
  
  //println("Rounded to: X = " + rx + ", Y = " + ry);

  for (TableRow row : lookup.rows()) {
    if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
      return row;
    }
  }

  return null;  // no exact match found
}

void sendMotorCommandManual(float s0, float s1, float s2) {
  String data = "0:" + s0 + ",1:" + s1 + ",2:" + s2 + "\n";

  if (!data.equals(lastCommand)) {
    sendViaHttp(data);
    print("Manually Sent: " + data);
    lastCommand = data;
  } else {
    println("Skipping duplicate manual command: " + data.trim());
  }
}

void sendViaHttp(String data) {
  try {
    // Extract servo values
    String[] parts = data.trim().split(",");
    float[] values = new float[3];
    for (int i = 0; i < parts.length; i++) {
      String[] kv = parts[i].split(":");
      values[i] = Float.parseFloat(kv[1]);
    }

    // Build request
    String url = "http://192.168.4.1/move?0=" + values[0] + "&1=" + values[1] + "&2=" + values[2];
    println("Sending HTTP GET: " + url);

    String[] response = loadStrings(url);
    if (response != null) {
      println("Response: " + join(response, "\n"));
    }
  } catch (Exception e) {
    println("Error sending HTTP: " + e.getMessage());
  }
}


void keyPressed() {
  if (key == 'c' || key == 'C') {
    stroke.clear();
    drawing = true;
    replaying = false;
    revReplaying = false;
    println("Cleared, mode set to drawing");
  }
}
