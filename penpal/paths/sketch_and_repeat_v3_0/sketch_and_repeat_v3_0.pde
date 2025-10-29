import processing.serial.*;
import java.util.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;

// Timed drawing point
class TimedPoint {
  PVector pos;
  float time;
  TimedPoint(PVector p, float t) {
    pos = p;
    time = t;
  }
}

// To store the current stroke
TimedPoint[] stroke = new TimedPoint[1000];
int strokeCount = 0;

// State variables
int strokeStartTime;
boolean drawing = true;
boolean replaying = false;
boolean revReplaying = false;
int replayStartTime;
int replayIndex;
int revReplayStartTime;
int revReplayIndex;
int lastSentIndex = -1;  // Track last point we actually sent to motors
String lastCommand = "";
Table lookup;
boolean offlineMode = false;

// Controls
int mode = 1;  // 0: send live, 1: replay, 2: loop
float modalCutoff = 2.0; // out of the -12.5 to 12.5 square range
float replaySpeed = 1.0;
float size = 1.0;
int angle = 0;
int utilitySetting = 0;  // 0: self draw, 1: line, 2: triangle, 3: circle, 4: stamp (cat)\
boolean connectLastPoint = false;
int waitTime;

// Drawing bounds (of the grid)
final float DRAWING_MIN = -12.5;
final float DRAWING_MAX = 12.5;

void setup() {
  size(1000, 600);  // default android window
  //surface.setResizable(true);
  
  if (!offlineMode) {
    // Serial setup
    printArray(Serial.list());
    String portName = Serial.list()[3];  // Adjust index as needed
    myPort = new Serial(this, portName, 57600);
  }
    
  // Load lookup table
  lookup = loadTable("lookup_table.csv", "header");
  
  // Fill out the utility functions
  setupUtil();
  
  // Draw controls
  setupUI();
  
  println("Setup complete.");
}

void draw() {
  background(200);
  
  drawSquare();
  
  // Handle modes
  // We don't need anything for mode0
  if (mode == 1) manageMode1();
  if (mode == 2) manageMode2();
  if (mode == 3) manageMode3(waitTime); // BRUTE FORCE
}

// Input handlers
void mousePressed() {
  if (inBounds()) {
    strokeStartTime = millis();
    clear();
  }
}

void mouseDragged() {
  if (drawing) {
    PVector pos = new PVector(mouseX, mouseY);
    float t = millis() - strokeStartTime;
    if (strokeCount < stroke.length && inBounds()) {
      stroke[strokeCount++] = new TimedPoint(undoTransformations(toGrid(toSquare(pos))), t);
    }
    if (mode == 0 && inBounds()) {
      sendMotorCommand(pos);
    }
  }
}

void mouseReleased() {
  // if (inBounds()) {
  if (strokeCount > 1 && drawing) {
    if (mode != 0 && strokeCount > 0) {
      setMode1or2(); // we use this for normalizing the stroke
      setStrokeContents();
      setNormalize();
      startReplay();
    }
  }
}

void setMode1or2() {
  // Convert screen coordinates to real coordinates first
  PVector startPos = stroke[0].pos;
  PVector endPos = stroke[strokeCount - 1].pos;
  
  if (PVector.dist(startPos, endPos) > modalCutoff) {
    mode = 1;
    //easingAmount = fullEase;
    easingAmount = 0;
  } else {
    mode = 2;
    easingAmount = 0;
  }
  println("I set the mode to: ", mode, " because the distance between ", startPos, " and ", endPos, " is ", PVector.dist(startPos, endPos));
}

// Mode management
void manageMode1() {
  if (replaying) {
    float currentTargetTime = (millis() - replayStartTime) * replaySpeed;
    
    int targetIndex = -1;
    for (int i = replayIndex; i < strokeCount; i++) {
      if (stroke[i].time <= currentTargetTime) {
        targetIndex = i;
      } else break;
    }
    
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      sendMotorCommand(stroke[targetIndex].pos);
      lastSentIndex = targetIndex;
      replayIndex = targetIndex + 1;
    }
    
    if (replayIndex >= strokeCount) {
      //delay(500);
      replaying = false;
      revReplaying = true;
      revReplayStartTime = millis();
      lastSentIndex = -1;
      revReplayIndex = strokeCount - 1;
    }
  }
  
  if (revReplaying) {
    float currentTargetTime = (millis() - revReplayStartTime) * replaySpeed;
    float maxTime = stroke[strokeCount-1].time;
    
    int targetIndex = -1;
    for (int i = revReplayIndex; i >= 0; i--) {
      if ((maxTime - stroke[i].time) <= currentTargetTime) {
        targetIndex = i;
      } else break;
    }
    
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      sendMotorCommand(stroke[targetIndex].pos);
      lastSentIndex = targetIndex;
      revReplayIndex = targetIndex - 1;
    }
    
    if (revReplayIndex < 0) {
      //delay(500);
      revReplaying = false;
      replaying = true;
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }
}

void manageMode2() {
  if (replaying) {
    float currentTargetTime = (millis() - replayStartTime) * replaySpeed;
    
    int targetIndex = -1;
    for (int i = replayIndex; i < strokeCount; i++) {
      if (stroke[i].time <= currentTargetTime) {
        targetIndex = i;
      } else break;
    }
    
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      sendMotorCommand(stroke[targetIndex].pos);
      lastSentIndex = targetIndex;
      replayIndex = targetIndex + 1;
    }
    
    if (replayIndex >= strokeCount) {
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }
}

void manageMode3(int defaultWait) { // BRUTE FORCE
  if (replaying) {
    sendMotorCommand(stroke[replayIndex].pos);
    replayIndex++;
    int delayTime = int(defaultWait / replaySpeed);
    delay(delayTime);  // ensure delay is never 0
    if (replayIndex >= strokeCount) {
      replayIndex = 0;
    }
  }
}

// === MOTOR COMMAND ===

// sends grid coordinates to the pen
void sendMotorCommand(PVector cmd) {
  PVector transformedCmd = applyTransformations(cmd);
  PVector flippedCmd = new PVector(transformedCmd.x, -transformedCmd.y); // to account for how the pen is usually held "upside down"
  
  TableRow row = getExactRow(flippedCmd);
  
  if (row != null) {
    String data = String.format("0:%d,1:%d,2:%d\n", 
      row.getInt("servo_0"), 
      row.getInt("servo_1"), 
      row.getInt("servo_2"));
    
    if (!data.equals(lastCommand) && !offlineMode) {
      myPort.write(data);
      lastCommand = data;
    }
  }
}

TableRow getExactRow(PVector pos) {
  float rx = (round(pos.x * 2) / 2.0);
  float ry = (round(pos.y * 2) / 2.0) * -1;

  for (TableRow row : lookup.rows()) {
    if (row.getFloat("X") == rx && row.getFloat("Y") == ry) {
      return row;
    }
  }
  return null;
}
