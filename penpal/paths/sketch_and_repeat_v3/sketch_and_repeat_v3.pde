import processing.serial.*;
import java.util.*;
import controlP5.*;

ControlP5 cp5;
Serial myPort;

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
boolean preset1Normalized;
boolean preset2Normalized;
boolean preset3Normalized;

// normalization
boolean normalize = true;
float targetSpeed = 0.05; // Adjust this value for desired speed (units per second)
TimedPoint[] originalStroke = new TimedPoint[1000];
TimedPoint[] normalizedStroke = new TimedPoint[1000];
int originalStrokeLength = 0;
int normalizedStrokeLength = 0;

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
float easingAmount;
float fullEase = 0.5; // the amount of easing when the mode is 1

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

void setupUI() {
  cp5 = new ControlP5(this);
  
  PFont font = createFont("Arial", 10);
  cp5.setFont(font);

  squareSize = height - 2 * outerOffsetY;
  controlX = outerOffsetX + squareSize + innerOffset;
  controlW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 3;
  controlH = controlHeight;
  spacer = controlH + betweenControls; 
  
  buttonW = (width - outerOffsetX - outerOffsetX - squareSize - innerOffset) * 2 / 5;
  buttonH = buttonW / 2;
  int buttonY = outerOffsetY + spacer * 3 + betweenControls * 2;

  // Replay speed slider
  cp5.addSlider("replaySpeed")
     .setPosition(controlX, outerOffsetY + betweenControls)
     .setRange(0.1, 2.0)
     .setValue(replay_speed)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label

  // Size slider
  cp5.addSlider("size") 
     .setPosition(controlX, outerOffsetY + spacer + betweenControls)
     .setRange(0.1, 2.0)
     .setValue(size)
     .setSize(controlW, controlH);
     //.setLabel("");  // Hide default label
     
  // Rotation slider
  cp5.addSlider("angle")
     .setPosition(controlX, outerOffsetY + spacer + spacer + betweenControls)
     .setRange(-180, 180)
     .setValue(angle)
     .setSize(controlW, controlH);
     //.setLabel("orientation");  // Hide default label
     

  // Line button
  cp5.addButton("SetLine")
     .setLabel("Line")
     .setPosition(controlX, buttonY)
     .setSize(buttonW, buttonH);

  // Triangle button
  cp5.addButton("SetTriangle")
     .setLabel("Triangle")
     .setPosition(controlX + buttonW + betweenControls, buttonY)
     .setSize(buttonW, buttonH);

  // Circle button
  cp5.addButton("SetCircle")
     .setLabel("Circle")
     .setPosition(controlX, buttonY + buttonH + betweenControls)
     .setSize(buttonW, buttonH);

  // Stamp button
  cp5.addButton("SetStamp")
     .setLabel("Stamp")
     .setPosition(controlX + buttonW + betweenControls, buttonY + buttonH + betweenControls)
     .setSize(buttonW, buttonH);
     
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
    
    // Keep track of where the tip is with a red dot
    if (!drawing) {
      PVector currentVertex;
      if (revReplaying) {
        currentVertex = toSquareFromGrid(applyTransformations(stroke[revReplayIndex].pos));
      } else {
        currentVertex = toSquareFromGrid(applyTransformations(stroke[replayIndex].pos));
      }
      if (inBounds(toScreen(currentVertex))) {
        strokeWeight(0);
        fill(255, 0, 0);
        circle(currentVertex.x, currentVertex.y, 20);
      }
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



// Helper methods

PVector applyTransformations(PVector original) {
  PVector transformed = original.copy();
  
  // Apply scaling
  //println("size: ", size);
  transformed.mult(size);
  
  // Apply rotation
  //println("orientation: ", angle);
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

// Modified inBounds to accept PVector (screen position)
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

TimedPoint[] normalizeStroke(TimedPoint[] original, int originalCount, float targetSpeed) {
  if (originalCount <= 1) return original;

  // Calculate total stroke length and segment lengths
  float totalLength = 0;
  float[] segmentLengths = new float[originalCount - 1];
  for (int i = 0; i < originalCount - 1; i++) {
    float segLength = PVector.dist(original[i].pos, original[i + 1].pos);
    segmentLengths[i] = segLength;
    totalLength += segLength;
  }

  // Handle zero-length strokes
  if (totalLength == 0) {
    TimedPoint[] flat = new TimedPoint[1];
    flat[0] = new TimedPoint(original[0].pos.copy(), 0);
    return flat;
  }

  // Determine how many points to generate
  //int newCount = max(int(totalLength * 2), 2);  // at least 2
  int newCount = max(int(totalLength * 4), 2);  // at least 2
  TimedPoint[] normalized = new TimedPoint[newCount];

  float totalTime = totalLength / targetSpeed;
  float timePerPoint = totalTime / (newCount - 1);

  for (int i = 0; i < newCount; i++) {
    float alpha = (float)i / (newCount - 1);
    
    // distance interpolation method
    float linearAlpha = alpha;
    float easedAlpha = (1 - cos(PI * alpha)) / 2.0;
    float distanceAlpha = lerp(linearAlpha, easedAlpha, easingAmount);

    float targetDistance = distanceAlpha * totalLength;
    float time = i * timePerPoint;

    // Locate the segment for this distance
    float accumulatedLength = 0;
    int segmentIndex = 0;
    while (segmentIndex < originalCount - 1 &&
           accumulatedLength + segmentLengths[segmentIndex] < targetDistance) {
      accumulatedLength += segmentLengths[segmentIndex];
      segmentIndex++;
    }

    // Clamp to avoid out-of-bounds
    segmentIndex = min(segmentIndex, originalCount - 2);
    float segLength = segmentLengths[segmentIndex];
    float segmentStart = accumulatedLength;

    // Interpolate position within the segment
    float remainingDistance = targetDistance - segmentStart;
    float t = (segLength == 0) ? 0 : constrain(remainingDistance / segLength, 0, 1);
    PVector pos = PVector.lerp(original[segmentIndex].pos, original[segmentIndex + 1].pos, t);

    normalized[i] = new TimedPoint(pos, time);
  }

  return normalized;
}


PVector getSmoothedPosition(TimedPoint[] stroke, int count, float t) {
  if (count == 0) return new PVector();
  if (count == 1 || t <= stroke[0].time) return stroke[0].pos.copy();
  if (t >= stroke[count - 1].time) return stroke[count - 1].pos.copy();

  for (int i = 0; i < count - 1; i++) {
    float t0 = stroke[i].time;
    float t1 = stroke[i + 1].time;
    if (t >= t0 && t < t1) {
      float alpha = (t - t0) / (t1 - t0);
      alpha = alpha * alpha * (3 - 2 * alpha); // smoothstep
      return PVector.lerp(stroke[i].pos, stroke[i + 1].pos, alpha);
    }
  }
  return stroke[count - 1].pos.copy();
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
    
    if (!data.equals(lastCommand) && !offlineMode) {
      myPort.write(data);
      lastCommand = data;
    }
  }
}
