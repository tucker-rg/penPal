import processing.serial.*;
import java.util.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;

// Replacement for PVector
class Vec2 {
  float x, y;
  Vec2(float x, float y) {
    this.x = x;
    this.y = y;
  }
}

// Timed drawing point
class TimedPoint {
  Vec2 pos;
  float time;
  TimedPoint(Vec2 p, float t) {
    pos = p;
    time = t;
  }
}

// Custom array list for TimedPoints
TimedPoint[] stroke = new TimedPoint[1000];
int strokeCount = 0;

int strokeStartTime;
boolean drawing = true;
boolean replaying = false;
boolean revReplaying = false;
int replayStartTime;
int replayIndex;
int revReplayStartTime;
int revReplayIndex;
int lastSentIndex = -1;  // Track last point we actually sent to motors

int mode = 1;  // 0: send live, 1: replay 
String lastCommand = "";
Table lookup;

final float DRAWING_MIN_X = -12.5;
final float DRAWING_MAX_X = 12.5;
final float DRAWING_MIN_Y = -12.5;
final float DRAWING_MAX_Y = 12.5;

//for the buttons: 
float replaySpeed = 1.0;  // Default normal speed (1.0 = 100%)
final float SPEED_INCREMENT = 0.25;  // How much to change speed with each button press
final float MIN_SPEED = 0.25;  // Minimum speed (25%)
final float MAX_SPEED = 5.0;   // Maximum speed (200%)

// Button dimensions and positions (updated)
final int BUTTON_WIDTH = 80;  // Wider buttons
final int BUTTON_HEIGHT = 30;
final int BUTTON_SPACING = 20;  // Space between buttons
int slowButtonX, fastButtonX, speedDisplayX;
int BUTTON_Y;  // Now a variable since we might adjust it

void setup() {
  size(400, 440);  // Added 40px at the top for controls
  
  // Serial setup
  printArray(Serial.list());
  String portName = Serial.list()[3];  // Adjust index as needed
  myPort = new Serial(this, portName, 57600);
  
  cp5 = new ControlP5(this);
  
  // Load lookup table (and upper lookup table)
  lookup = loadTable("lookup_table.csv", "header");
  
  // Center buttons in their respective halves
  slowButtonX = width/4 - BUTTON_WIDTH/2;    // Left half center
  fastButtonX = 3*width/4 - BUTTON_WIDTH/2;  // Right half center
  speedDisplayX = width/2;                   // Center
  BUTTON_Y = 5;  // Top padding
  
  println("Setup complete.");
}

void draw() {
  background(255);
  
  // Draw the speed control panel
  drawSpeedControls();
  
  // Draw the drawing area (shifted down by 40px)
  pushMatrix();
  translate(0, 40);  // Shift everything below the control panel
  
  stroke(0);
  noFill();
  beginShape();
  for (int i = 0; i < strokeCount; i++) {
    Vec2 p = stroke[i].pos;
    vertex(p.x, p.y);
  }
  endShape();

  if (mode == 1) {
    manageMode1();
  }
  
  popMatrix();
  
  if (mousePressed && mouseY >= 40) {  // Only show in drawing area
    float realX = map(mouseX, 0, width, DRAWING_MIN_X, DRAWING_MAX_X);
    float realY = map(mouseY - 40, 0, height - 40, DRAWING_MIN_Y, DRAWING_MAX_Y);
    
    if (realX < DRAWING_MIN_X || realX > DRAWING_MAX_X || 
        realY < DRAWING_MIN_Y || realY > DRAWING_MAX_Y) {
      fill(255, 0, 0, 100);
      noStroke();
      ellipse(mouseX, mouseY, 30, 30);
      fill(0);
      textAlign(CENTER, CENTER);
      text("OUT OF BOUNDS", mouseX, mouseY);
    }
  }
}

void drawSpeedControls() {
  // Control panel background
  fill(240);
  noStroke();
  rect(0, 0, width, 40);
  
  // Draw slow button (left half)
  fill(200);
  rect(slowButtonX, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, 5);
  fill(0);
  textAlign(CENTER, CENTER);
  text("SLOWER", slowButtonX + BUTTON_WIDTH/2, BUTTON_Y + BUTTON_HEIGHT/2);
  
  // Draw speed display (center)
  fill(255);
  rect(speedDisplayX - BUTTON_WIDTH/2, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, 5);
  fill(0);
  text(nf(replaySpeed, 1, 2) + "x", speedDisplayX, BUTTON_Y + BUTTON_HEIGHT/2);
  
  // Draw fast button (right half)
  fill(200);
  rect(fastButtonX, BUTTON_Y, BUTTON_WIDTH, BUTTON_HEIGHT, 5);
  fill(0);
  text("FASTER", fastButtonX + BUTTON_WIDTH/2, BUTTON_Y + BUTTON_HEIGHT/2);
  
  // Add dividing lines for visual separation
  stroke(150);
  line(width/2 - 50, BUTTON_Y + 5, width/2 - 50, BUTTON_Y + BUTTON_HEIGHT - 5);
  line(width/2 + 50, BUTTON_Y + 5, width/2 + 50, BUTTON_Y + BUTTON_HEIGHT - 5);
  noStroke();
}

void mousePressed() {
  // First check if clicking in control area (y < 40)
  if (mouseY < 40) {
    if (mouseX >= slowButtonX && mouseX <= slowButtonX + BUTTON_WIDTH) {
      // Slow down button
      replaySpeed = max(MIN_SPEED, replaySpeed - SPEED_INCREMENT);
    } else if (mouseX >= fastButtonX && mouseX <= fastButtonX + BUTTON_WIDTH) {
      // Speed up button
      replaySpeed = min(MAX_SPEED, replaySpeed + SPEED_INCREMENT);
    }
    return;  // Don't start new stroke if clicking controls
  }
  
  // Original mousePressed code (using drawingMouseY if needed)
  strokeCount = 0;
  strokeStartTime = millis();
  drawing = true;
  replaying = false;
  revReplaying = false;
}

void mouseDragged() {
  // Only draw if in drawing area (y >= 40)
  if (mouseY < 40) return;
  
  if (drawing) {
    Vec2 pos = new Vec2(mouseX, mouseY - 40);  // Adjust for control panel
    float t = millis() - strokeStartTime;
    if (strokeCount < stroke.length) {
      stroke[strokeCount++] = new TimedPoint(pos, t);
    }

    if (mode == 0 && inBounds(pos.x, pos.y)) {
      sendMotorCommand(pos.x, pos.y);
    }
  }
}

void mouseReleased() {
  if (mode == 1) {
    drawing = false;
    replaying = true;
    revReplaying = false;
    replayStartTime = millis();
    replayIndex = 0;
  }
}

void manageMode1() {
  if (replaying) {
    float currentTargetTime = (millis() - replayStartTime) * replaySpeed;
    
    // Find the most recent point that should have been displayed by now
    int targetIndex = -1;
    for (int i = replayIndex; i < strokeCount; i++) {
      if (stroke[i].time <= currentTargetTime) {
        targetIndex = i;
      } else {
        break;
      }
    }
    
    // If we found a point to display
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      if (inBounds(stroke[targetIndex].pos.x, stroke[targetIndex].pos.y)) {
        sendMotorCommand(stroke[targetIndex].pos.x, stroke[targetIndex].pos.y);
      }
      lastSentIndex = targetIndex;
      replayIndex = targetIndex + 1;
    }
    
    // Check if we've reached the end
    if (replayIndex >= strokeCount) {
      replaying = false;
      revReplaying = true;
      replayStartTime = millis();
      lastSentIndex = -1;
      revReplayIndex = strokeCount - 1;
    }
  }
  
  if (revReplaying) {
    float currentTargetTime = (millis() - replayStartTime) * replaySpeed;
    float maxTime = stroke[strokeCount-1].time;
    
    // Find the most recent point that should have been displayed in reverse
    int targetIndex = -1;
    for (int i = revReplayIndex; i >= 0; i--) {
      if ((maxTime - stroke[i].time) <= currentTargetTime) {
        targetIndex = i;
      } else {
        break;
      }
    }
    
    // If we found a point to display
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      if (inBounds(stroke[targetIndex].pos.x, stroke[targetIndex].pos.y)) {
        sendMotorCommand(stroke[targetIndex].pos.x, stroke[targetIndex].pos.y);
      }
      lastSentIndex = targetIndex;
      revReplayIndex = targetIndex - 1;
    }
    
    // Check if we've reached the beginning
    if (revReplayIndex < 0) {
      revReplaying = false;
      replaying = true;
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }
}

// === CSV LOADING ===

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

// === MOTOR COMMAND ===

boolean inBounds(float x, float y) {
  if (0 <= x && x <= 400 && 0 <= y && y <= 400) {
    return true;
  }
  return false;
}

void sendMotorCommand(float x, float y) {
  float realX = map(x, 0, width, -12.5, 12.5);
  float realY = map(y, 0, height, -12.5, 12.5);
  
  TableRow row = getExactRow(realX, realY);
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
  }
}

void keyPressed() {
  if (key == 'c' || key == 'C') {
    strokeCount = 0;
    drawing = true;
    replaying = false;
    revReplaying = false;
    println("Cleared.");
  }
}
