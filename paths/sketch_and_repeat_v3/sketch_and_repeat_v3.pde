import processing.serial.*;
import java.util.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;

// Drawing state/mode variables
final int MODE_REPLAY = 1, MODE_LOOP = 2, MODE_BRUTE = 3;
final int DRAWING = 4, REPLAYING = 5, REVREPLAYING = 6;

int state = DRAWING;
int strokeStartTime;
int replayStartTime;
int replayIndex;
int revReplayStartTime;
int revReplayIndex;
int lastSentIndex = -1;  // Track last point we actually sent to motors
Table lookup;
boolean offlineMode = false;

// To store the current stroke
Doodle currentDoodle;

// and the other strokes
Doodle line;
Doodle triangle;
Doodle circle;
Doodle stamp;

Doodle preset1;
Doodle preset2;
Doodle preset3;
Doodle preset4;

// we automatically select the first preset at launch
int selectedPreset = 1; // -4 (stamp), -3 (circle), -2 (triangle), -1 (line)
                        // 1, 2, 3, 4 (custom presets)

// To communicate with the pen
MotorCommand penControl;

// Drawing bounds (of the grid)
final float DRAWING_MIN = -12.5;
final float DRAWING_MAX = 12.5;


void setup() {
  size(1000, 600);  // default android window
  background(200);
  //surface.setResizable(true);
  
  if (!offlineMode) {
    println("setting up serial");
    // Serial setup
    printArray(Serial.list());
    String portName = Serial.list()[3];  // Adjust index as needed
    myPort = new Serial(this, portName, 115200); //57600
    myPort.bufferUntil('\n');  // trigger serialEvent on newline
  }
    
  // Load lookup table
  println("loading lookup table");
  lookup = loadTable("lookup_table.csv", "header");
  
  //println("creating the currentDoodle");
  currentDoodle = new Doodle();
  
  println("creating the default doodles");
  createLine();
  createTriangle();
  createCircle();
  createStamp();
  
  println("creating the custom preset doodles");
  
  preset1 = new Doodle();
  preset2 = new Doodle();
  preset3 = new Doodle();
  preset4 = new Doodle();
  
  // To manage the motors
  penControl = new MotorCommand();
  
  // Draw controls
  println("drawing the controls");
  setupUI();
  
  println("Setup complete.");
}

void draw() {
  background(200);
  drawDrawingSquare();
  
  stroke(0, 150, 255);   // Bright blue border
  strokeWeight(5);
  noFill();
  
  // OPTIONAL: set the rotation angle via the potentiometer
  // penControl.getSetAngle();
  
  // highligh default preset
  if (selectedPreset <= -1 && selectedPreset >= -4) { 
    int x = controlX + (-selectedPreset - 1) * (imageSize + betweenControls);
    int y = outerOffsetY + spacer * 3 + betweenControls * 2 + font_size + betweenControls; // Same as buttonY
    rect(x, y, imageSize, imageSize);
  }

  // Highlight custom preset
  if (selectedPreset >= 1 && selectedPreset <= 4) {
    int x = controlX + (selectedPreset - 1) * (imageSize + betweenControls);
    int y = presetY;
    rect(x, y, imageSize, imageSize);
  }
  
  // Handle modes
  if (state != DRAWING) {
    if (currentDoodle.mode == 1) manageMode1(currentDoodle);
    if (currentDoodle.mode == 2) manageMode2(currentDoodle);
    if (currentDoodle.mode == 3) manageMode3(currentDoodle); // BRUTE FORCE
  }
}

// Input handlers
void mousePressed() {
  if (inBounds()) {
    // selectedPreset = 0;
    state = DRAWING;
    strokeStartTime = millis();
    clear();
  }
}

void mouseDragged() {
  if (state == DRAWING) {
    PVector pos = new PVector(mouseX, mouseY);
    float t = millis() - strokeStartTime;
    if (inBounds()) {
      currentDoodle.addPoint(new TimedPoint(currentDoodle.undoTransformations(toGrid(toSquare(pos))), t));
    }
  }
}

void mouseReleased() {
  // if (inBounds()) {
  if (currentDoodle.getCount() > 1 && state == DRAWING) {
    startReplay();
  }
}

// sends the next point given the mode
void manageMode1(Doodle doodle) {
  if (state == REPLAYING) {
    float currentTargetTime = (millis() - replayStartTime) * doodle.getReplaySpeed();
    
    int targetIndex = -1;
    for (int i = replayIndex; i < doodle.getCount(); i++) {
      if (doodle.getPoint(i).time <= currentTargetTime) {
        targetIndex = i;
      } else break;
    }
    
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      penControl.sendMotorCommand(doodle.getPoint(targetIndex).pos);
      lastSentIndex = targetIndex;
      replayIndex = targetIndex + 1;
    }
    
    if (replayIndex >= doodle.getCount()) {
      //delay(500);
      state = REVREPLAYING;
      revReplayStartTime = millis();
      lastSentIndex = -1;
      revReplayIndex = doodle.getCount() - 1;
    }
  }
  
  if (state == REVREPLAYING) {
    float currentTargetTime = (millis() - revReplayStartTime) * doodle.getReplaySpeed();
    float maxTime = doodle.getPoint(doodle.getCount() - 1).time;
    
    int targetIndex = -1;
    for (int i = revReplayIndex; i >= 0; i--) {
      if ((maxTime - doodle.getPoint(i).time) <= currentTargetTime) {
        targetIndex = i;
      } else break;
    }
    
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      penControl.sendMotorCommand(doodle.getPoint(targetIndex).pos);
      lastSentIndex = targetIndex;
      revReplayIndex = targetIndex - 1;
    }
    
    if (revReplayIndex < 0) {
      //delay(500);
      state = REPLAYING;
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }
}

void manageMode2(Doodle doodle) {
  if (state == REPLAYING) {
    float currentTargetTime = (millis() - replayStartTime) * doodle.getReplaySpeed();
    
    int targetIndex = -1;
    for (int i = replayIndex; i < doodle.getCount(); i++) {
      if (doodle.getPoint(i).time <= currentTargetTime) {
        targetIndex = i;
      } else break;
    }
    
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      penControl.sendMotorCommand(doodle.getPoint(targetIndex).pos);
      lastSentIndex = targetIndex;
      replayIndex = targetIndex + 1;
    }
    
    if (replayIndex >= doodle.getCount()) {
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }
}

void manageMode3(Doodle doodle) { // BRUTE FORCE
  if (state == REPLAYING) {
    penControl.sendMotorCommand(doodle.getPoint(replayIndex).pos);
    replayIndex++;
    int delayTime = int(doodle.getWaitTime() / doodle.getReplaySpeed());
    delay(delayTime);  // ensure delay is never 0
    if (replayIndex >= doodle.getCount()) {
      replayIndex = 0;
    }
  }
}
