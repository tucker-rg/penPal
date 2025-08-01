import android.net.wifi.WifiManager;
import android.content.Context;
import java.io.*;
import java.net.*;
import java.util.*;
import controlP5.*;

DatagramSocket udpSocket;
InetAddress arduinoIP;
ControlP5 cp5;

// Timed drawing point using PVector
class TimedPoint {
  PVector pos;
  float time;
  TimedPoint(PVector p, float t) {
    pos = p;
    time = t;
  }
}

// Custom array for TimedPoints
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
int lastSentIndex = -1;

// Controls
int mode = 1;  // 0: send live, 1: replay, 2: loop
float modalCutoff = 2.0; // out of the -12.5 to 12.5 square range
float replaySpeed = 1.0;
String lastCommand = "";
Table lookup;
float size = 1.0;

// UI
int outerOffsetX = 100;
int outerOffsetY = 70;
int innerOffset = 50;
int squareSize;
int controlHeight = 60;
float replay_speed = 1.0;
int controlX, controlW, controlH, spacer;

// Drawing bounds (of the grid)
final float DRAWING_MIN = -12.5;
final float DRAWING_MAX = 12.5;

void setup() {
  //size(400, 400); 
  fullScreen();
  orientation(LANDSCAPE);
  setupUI();
  
  // Load lookup table
  lookup = loadTable("lookup_table.csv", "header");
  
  // UDP setup
  try {
    udpSocket = new DatagramSocket();
    arduinoIP = InetAddress.getByName("192.168.4.1");
  } catch (Exception e) {
    e.printStackTrace();
  }
  
  
}

void draw() {
  // drawing square
  stroke(0);
  fill(255);
  strokeWeight(0);
  rect(outerOffsetX, outerOffsetY, squareSize, squareSize);
  
  // constrain drawing to inside the square
  pushMatrix();
  translate(outerOffsetX, outerOffsetY);
  clip(0, 0, squareSize, squareSize);
  
  // Draw stroke
  stroke(0);
  strokeWeight(5);
  noFill();
  
  if (strokeCount > 0) {
    beginShape();
    for (int i = 0; i < strokeCount; i++) {
      vertex(stroke[i].pos.x, stroke[i].pos.y);
    }
    endShape();
  }
  
  popMatrix();

  // Handle current mode
  if (mode == 1) manageMode1();
  if (mode == 2) manageMode2();
}

void setupUI() {
  cp5 = new ControlP5(this);
  
  background(200);
  
  PFont font = createFont("Arial", 10);
  cp5.setFont(font);
  
  squareSize = height - 2 * outerOffsetY;
  controlX = outerOffsetX + squareSize + innerOffset;
  controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
  controlH = controlHeight;
  spacer = controlH + innerOffset; 

  // Replay speed slider
  cp5.addSlider("replaySpeed")
     .setPosition(controlX, outerOffsetY + innerOffset)
     .setRange(0.1, 3.0)
     .setValue(replay_speed)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label

  // Size slider
  cp5.addSlider("size")
     .setPosition(controlX, outerOffsetY + innerOffset + spacer)
     .setRange(0.1, 3.0)
     .setValue(size)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label
}

// Input handlers
void mousePressed() {
  strokeCount = 0;
  strokeStartTime = millis();
  drawing = true;
  replaying = false;
  revReplaying = false;
}

void mouseDragged() {
  if (drawing) {
    PVector pos = new PVector(mouseX, mouseY);
    float t = millis() - strokeStartTime;
    if (strokeCount < stroke.length && inBounds()) {
      stroke[strokeCount++] = new TimedPoint(toSquare(pos), t);
    }
    if (mode == 0 && inBounds()) {
      sendMotorCommand(pos);
    }
  }
}

void mouseReleased() {
  if (mode != 0 && strokeCount > 0) {
    // Convert screen coordinates to real coordinates first
    PVector startPos = toGrid(stroke[0].pos);
    PVector endPos = toGrid(stroke[strokeCount - 1].pos);
    
    if (PVector.dist(startPos, endPos) > modalCutoff) {
      mode = 1;
    } else {
      mode = 2;
    }
    
    // Start replay
    drawing = false;
    replaying = true;
    revReplaying = false;
    replayStartTime = millis();
    replayIndex = 0;
    lastSentIndex = -1;
  }
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
      delay(100);
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
      delay(100);
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

// Helper methods (unchanged)

// returns if the mouse is currently within the square
boolean inBounds() {
  float localX = mouseX - outerOffsetX;
  float localY = mouseY - outerOffsetY;

  // Are we in the square
  if (localX >= 0 && localX <= squareSize &&
      localY >= 0 && localY <= squareSize) {
    return true;
  } else {
    return false;
  }
}

// converts screen coordinates to square coordinates
PVector toSquare(PVector pos) {
  float localX = pos.x - outerOffsetX;
  float localY = pos.y - outerOffsetY;

  PVector returns = new PVector(localX, localY);
  return returns;
}

// converts square coordinates to grid coordinates
PVector toGrid(PVector pos) {
  float gridX = map(pos.x, 0, squareSize, DRAWING_MIN, DRAWING_MAX);
  float gridY = map(pos.y, 0, squareSize, DRAWING_MIN, DRAWING_MAX);
  PVector gridCoord = new PVector(gridX, gridY);
  
  return gridCoord;
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

void sendMotorCommand(PVector cmd) {
  PVector gridCmd = toGrid(cmd);
  TableRow row = getExactRow(gridCmd);
  
  if (row != null) {
    String data = String.format("0=%d,1=%d,2=%d\n", 
      row.getInt("servo_0"), 
      row.getInt("servo_1"), 
      row.getInt("servo_2"));
    
    if (!data.equals(lastCommand)) {
      sendViaUDP(data);
      lastCommand = data;
    }
  }
}

void sendViaUDP(String data) {
  try {
    byte[] sendData = data.getBytes();
    DatagramPacket sendPacket = new DatagramPacket(
      sendData, sendData.length, arduinoIP, 8888);
    udpSocket.send(sendPacket);
  } catch (Exception e) {
    println("UDP Error: " + e.getMessage());
  }
}

void keyPressed() {
  if (key == 'c' || key == 'C') clear();
}
