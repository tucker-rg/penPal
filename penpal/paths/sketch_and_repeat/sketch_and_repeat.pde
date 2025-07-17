import controlP5.*;
import processing.serial.*;
import java.util.*;

ControlP5 cp5;
Serial myPort;

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
// 0: copy motion; 1: repeat forward/reverse; 2: repeat up/down

Table lookup;
Table lookupUpper;
PVector lastSent = new PVector(-9999, -9999);
String lastCommand = "";

void setup() {
  size(400, 400);
  
  // Serial setup
  printArray(Serial.list());
  String portName = Serial.list()[3];  // Adjust index as needed
  myPort = new Serial(this, portName, 57600);

  cp5 = new ControlP5(this);
  
  // Load lookup table (and upper lookup table)
  lookup = loadTable("lookup_table.csv", "header");
  lookupUpper = loadTable("july mapping (upper) - Sheet1.csv", "header");

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
  
  if (mode == 2) {
    manageMode2();
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

void manageMode2() {
  if (replaying && replayIndex < stroke.size()) {
    //println("replaying point " + replayIndex + " of " + stroke.size());
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
    println("done replaying, now replaying");
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
  if (mode == 1 || mode == 2) {
    println("done drawing, now replaying");
  }
    
  if (mode == 2) {
    PVector initialPos = stroke.get(0).pos;
    PVector finalPos = stroke.get(stroke.size() - 1).pos;
    double deltaX = abs(initialPos.x - finalPos.x);
    double deltaY = abs(initialPos.y - finalPos.y);
    double dist = Math.hypot(deltaX, deltaY);
    int endTime = millis() - strokeStartTime;
  
    PVector transitionStart = initialPos.copy().add(500, 500);
    PVector transitionEnd = finalPos.copy().add(500, 500);
  
    int numSamples = round((float)dist / 50);
    println("numSamples: " + numSamples);
  
    float xStepDist = (transitionEnd.x - transitionStart.x) / numSamples;
    float yStepDist = (transitionEnd.y - transitionStart.y) / numSamples;
  
    PVector step = new PVector(xStepDist, yStepDist);
    PVector current = transitionStart.copy();
  
    for (int i = 0; i < numSamples; i++) {
      stroke.add(new TimedPoint(current.copy(), endTime + 500 * (i + 1)));
      println("added a transition point: " + current.x + " " + current.y + ", at time: " + (endTime + 500 * (i + 1)));
      current.add(step);
    }

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
  if (x < 450) { // i.e. a lower coordinate
    println("this is a lower coordinate");
    float realX = map(x, 0, width, -12.5, 12.5);
    float realY = map(y, 0, height, -12.5, 12.5);
  
    //println("Sending for screen (" + x + "," + y + ") -> real (" + realX + "," + realY + ")");
  
    row = getExactRow(realX, realY);
  }
  
  if (x > 450) { // i.e. an upper coordinate
    println("this is an upper coordinate");
    float realX = map(x - 500, 0, width, -12.5, 12.5);
    float realY = map(y - 500, 0, height, -12.5, 12.5);
  
    println("Sending for screen (" + x + "," + y + ") -> real (" + realX + "," + realY + ")");
  
    row = getExactRowUpper(realX, realY);
  }
  
  if (row != null) {
    int s0 = row.getInt("servo_0");
    int s1 = row.getInt("servo_1");
    int s2 = row.getInt("servo_2");

    String data = "0:" + s0 + ",1:" + s1 + ",2:" + s2 + "\n";

    if (!data.equals(lastCommand)) {
      myPort.write(data);
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

  for (TableRow row : lookupUpper.rows()) {
    if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
      return row;
    }
  }

  return null;  // no exact match found
}

void sendMotorCommandManual(float s0, float s1, float s2) {
  String data = "0:" + s0 + ",1:" + s1 + ",2:" + s2 + "\n";

  if (!data.equals(lastCommand)) {
    myPort.write(data);
    print("Manually Sent: " + data);
    lastCommand = data;
  } else {
    println("Skipping duplicate manual command: " + data.trim());
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
