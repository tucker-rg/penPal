import processing.serial.*;
import java.util.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;

// Button images
PGraphics lineImg, triangleImg, circleImg;
PImage stampImg;

// Timed drawing point using PVector
class TimedPoint {
  PVector pos;
  float time;
  TimedPoint(PVector p, float t) {
    pos = p;
    time = t;
  }
}
// Custom array list for TimedPoints
TimedPoint[] stroke = new TimedPoint[1000];
int strokeCount = 0;

// Also three custom presets
TimedPoint[] preset1 = new TimedPoint[1000];
TimedPoint[] preset2 = new TimedPoint[1000];
TimedPoint[] preset3 = new TimedPoint[1000];
int preset1Length = 0;
int preset2Length = 0;
int preset3Length = 0;

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

// Controls
int mode = 1;  // 0: send live, 1: replay, 2: loop
float modalCutoff = 2.0; // out of the -12.5 to 12.5 square range
float replaySpeed = 1.0;
float size = 1.0;
int angle = 0;
int utilitySetting = 0;  // 0: self draw, 1: line, 2: triangle, 3: circle, 4: stamp (cat)\
boolean connectLastPoint = false;
int waitTime;
int lineWait = 75;
int triangleWait = 50;
int circleWait = 10;
int stampWait = 30;

// UI
int outerOffsetX = 100;
int outerOffsetY = 70;
int innerOffset = 40;
int squareSize;
int controlHeight = 40;
int betweenControls = 20;
float replay_speed = 1.0;
int controlX, controlW, controlH, spacer;
int buttonW, buttonH;

// Drawing bounds (of the grid)
final float DRAWING_MIN = -12.5;
final float DRAWING_MAX = 12.5;

void setup() {
  size(1000, 600);  // default android window
  surface.setResizable(true);

  // Create button images
  createButtonImages();
  
  // Load stamp image (add error handling)
  try {
    stampImg = loadImage("cat.png"); // Change this to your actual file name
    stampImg.resize(80,80);
    if (stampImg == null) {
      // If image doesn't load, create a placeholder
      stampImg = createStampPlaceholder();
    }
  } catch (Exception e) {
    println("Could not load stamp image, creating placeholder");
    stampImg = createStampPlaceholder();
  }

  // Serial setup
  printArray(Serial.list());
  String portName = Serial.list()[0];  // Adjust index as needed
  myPort = new Serial(this, portName, 57600);
  
  // Load lookup table
  lookup = loadTable("lookup_table.csv", "header");
  
  // Fill out the utility functions
  setupUtil();
  
  // Draw controls
  setupUI();
  
  println("Setup complete.");
}

void createButtonImages() {
  // Create line image
  lineImg = createGraphics(80, 80);
  lineImg.beginDraw();
  lineImg.background(240);
  lineImg.stroke(50);
  lineImg.strokeWeight(2);
  lineImg.line(15, 15, 65, 65);
  lineImg.endDraw();
  
  // Create triangle image
  triangleImg = createGraphics(80, 80);
  triangleImg.beginDraw();
  triangleImg.background(240);
  triangleImg.stroke(50);
  triangleImg.strokeWeight(2);
  triangleImg.fill(240);
  triangleImg.triangle(10, 62, 70, 62, 40, 12);
  triangleImg.endDraw();
  
  // Create circle image
  circleImg = createGraphics(80, 80);
  circleImg.beginDraw();
  circleImg.background(240);
  circleImg.stroke(50);
  circleImg.strokeWeight(2);
  circleImg.fill(240);
  circleImg.ellipse(40, 40, 60, 60);
  circleImg.endDraw();
}

PImage createStampPlaceholder() {
  PGraphics placeholder = createGraphics(80, 80);
  placeholder.beginDraw();
  placeholder.background(240);
  placeholder.fill(100);
  placeholder.textAlign(CENTER, CENTER);
  placeholder.textSize(12);
  placeholder.text("STAMP", 40, 40);
  placeholder.endDraw();
  return placeholder;
}

void setupUI() {
  cp5 = new ControlP5(this);
  
  PFont font = createFont("Arial", 10);
  cp5.setFont(font);

  squareSize = height - 2 * outerOffsetY;
  controlX = outerOffsetX + squareSize + innerOffset;
  controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
  controlH = controlHeight;
  spacer = controlH + betweenControls; 
  
  buttonW = 80; 
  buttonH = 80; 
  int buttonY = outerOffsetY + spacer * 3 + betweenControls * 2;

  // Replay speed slider
  cp5.addSlider("replaySpeed")
     .setPosition(controlX, outerOffsetY + betweenControls)
     .setRange(0.1, 2.0)
     .setValue(replay_speed)
     .setSize(controlW, controlH);

  // Size slider
  cp5.addSlider("size") 
     .setPosition(controlX, outerOffsetY + spacer + betweenControls)
     .setRange(0.1, 2.0)
     .setValue(size)
     .setSize(controlW, controlH);
     
  // Rotation slider
  cp5.addSlider("angle")
     .setPosition(controlX, outerOffsetY + spacer + spacer + betweenControls)
     .setRange(-180, 180)
     .setValue(angle)
     .setSize(controlW, controlH);

  // Image buttons using Button with custom images
  cp5.addButton("SetLine")
     .setPosition(controlX, buttonY)
     .setSize(buttonW, buttonH)
     .setImages(lineImg, lineImg, lineImg); // normal, over, pressed

  cp5.addButton("SetTriangle")
     .setPosition(controlX + buttonW + betweenControls, buttonY)
     .setSize(buttonW, buttonH)
     .setImages(triangleImg, triangleImg, triangleImg);

  cp5.addButton("SetCircle")
     .setPosition(controlX, buttonY + buttonH + betweenControls)
     .setSize(buttonW, buttonH)
     .setImages(circleImg, circleImg, circleImg);

  cp5.addButton("SetStamp")
     .setPosition(controlX + buttonW + betweenControls, buttonY + buttonH + betweenControls)
     .setSize(buttonW, buttonH)
     .setImages(stampImg, stampImg, stampImg);
     
  // clear button
  cp5.addButton("clear")
     .setLabel("clear")
     .setPosition(controlX, buttonY + buttonH + betweenControls + buttonH + innerOffset)
     .setSize(controlW / 2, controlH);
}

void draw() {
  background(200);
  
  // drawing square
  stroke(0);
  fill(255);
  strokeWeight(0);
  rect(outerOffsetX, outerOffsetY, squareSize, squareSize);
  
  // constrain drawing to inside the square
  pushMatrix();
  translate(outerOffsetX, outerOffsetY);
  
  // Draw stroke
  stroke(0);
  strokeWeight(5);
  noFill();
  
  if (strokeCount > 0) {
    beginShape();
    for (int i = 0; i < strokeCount; i++) {
      PVector newVertex = toSquareFromGrid(applyTransformations(stroke[i].pos));
      if (inBounds(toScreen(newVertex))) {
        vertex(newVertex.x, newVertex.y);
      }
    }
    if (connectLastPoint) {
      PVector firstVertex = toSquareFromGrid(applyTransformations(stroke[0].pos));
      vertex(firstVertex.x, firstVertex.y);
    }
    endShape();
    
    // Keep track of where the tip is
    if (!drawing) {
      PVector currentVertex;
      if (revReplaying) {
        currentVertex = toSquareFromGrid(applyTransformations(stroke[revReplayIndex].pos));
      } else {
        currentVertex = toSquareFromGrid(applyTransformations(stroke[replayIndex].pos));
      }
      strokeWeight(0);
      fill(255, 0, 0);
      circle(currentVertex.x, currentVertex.y, 20);
    }
  }
  
  popMatrix();
  
  // Handle modes
  // We don't need anything for mode0
  if (mode == 1) manageMode1();
  if (mode == 2) manageMode2();
  if (mode == 3) manageMode3(waitTime); // BRUTE FORCE
}

// Input handlers
void mousePressed() {
  if (inBounds()) {
    connectLastPoint = false;
    utilitySetting = 0;
    strokeCount = 0;
    strokeStartTime = millis();
    drawing = true;
    replaying = false;
    revReplaying = false;
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
  if (inBounds()) {
    if (mode != 0 && strokeCount > 0) {
      setMode1or2();
      // Start replay
      startReplay();
    }
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

// Helper methods

PVector applyTransformations(PVector original) {
  PVector transformed = original.copy();
  
  // Apply scaling
  println("size: ", size);
  transformed.mult(size);
  
  // Apply rotation
  println("orientation: ", angle);
  transformed.rotate(radians(-angle));
  
  return transformed;
}

PVector undoTransformations(PVector transformed) {
  PVector original = transformed.copy();
  
  // Apply scaling
  original.mult(1 / size);
  
  // Apply rotation
  original.rotate(radians(angle));
  
  return original;
}

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

// Modified inBounds to accept PVector
boolean inBounds(PVector pos) {
  float localX = pos.x - outerOffsetX;
  float localY = pos.y - outerOffsetY;

  return (localX >= 0 && localX <= squareSize &&
          localY >= 0 && localY <= squareSize);
}

// converts screen coordinates to square coordinates
PVector toSquare(PVector pos) {
  float localX = pos.x - outerOffsetX;
  float localY = pos.y - outerOffsetY;

  PVector returns = new PVector(localX, localY);
  return returns;
}

// converts square coordinates to screen coordinates
PVector toScreen(PVector pos) {
  float localX = pos.x + outerOffsetX;
  float localY = pos.y + outerOffsetY;

  PVector returns = new PVector(localX, localY);
  return returns;
}

// converts square coordinates to grid coordinates
PVector toGrid(PVector pos) {
  float gridX = map(pos.x, 0, squareSize, DRAWING_MIN, DRAWING_MAX);
  float gridY = map(pos.y, 0, squareSize, DRAWING_MAX, DRAWING_MIN); // We reverse
  PVector gridCoord = new PVector(gridX, gridY);
  
  return gridCoord;
}

// converts grid coordinates to square coordinates
PVector toSquareFromGrid(PVector pos) {
  float localX = map(pos.x, DRAWING_MIN, DRAWING_MAX, 0, squareSize);
  float localY = map(pos.y, DRAWING_MAX, DRAWING_MIN, 0, squareSize);
  
  PVector squareCoord = new PVector(localX, localY);
  return squareCoord;
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
    
    if (!data.equals(lastCommand)) {
      myPort.write(data);
      lastCommand = data;
    }
  }
}
