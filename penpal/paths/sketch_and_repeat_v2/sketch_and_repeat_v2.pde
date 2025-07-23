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

int mode = 1;  // 0: send live, 1: replay (live doesn't work so well with the web server)
String lastCommand = "";

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
  loadLookup();
  lookupSize = lookup.length;
  
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
  
  // In your draw() function, update the out-of-bounds warning:
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

String[] findRow(float x, float y) {
  float rx = round(x * 2) / 2.0;
  float ry = round(y * 2) / 2.0 * -1;

  for (int i = 0; i < lookupSize; i++) {
    if (lookup[i][0] == rx && lookup[i][1] == ry) {
      return str(lookup[i]);
    }
  }

  return null;
}

// === MOTOR COMMAND ===

boolean inBounds(float x, float y) {
  if (0 <= x && x <= 400 && 0 <= y && y <= 400) {
    return true;
  }
  return false;
}

void sendMotorCommand(float x, float y) {
  // Only proceed if we're not currently waiting for a response
  if (!waitingForResponse) {
    float realX = map(x, 0, width, -12.5, 12.5);
    float realY = map(y, 0, height, -12.5, 12.5);
    
    String[] row = findRow(realX, realY);
    if (row != null) {
      String data = "0:" + row[2] + ",1:" + row[3] + ",2:" + row[4] + "\n";
      if (!data.equals(lastCommand)) {
        //sendViaHttp(data);
        sendViaHttpAsync(data);  // Use async version
        lastCommand = data;
      }
    }
  }
}

void sendViaHttp(String data) {
  try {
    String[] parts = splitTokens(data, ":,\n ");
    String url = "http://192.168.4.1/move?0=" + parts[1] + "&1=" + parts[3] + "&2=" + parts[5];
    println("Sending: " + url);

    String[] response = loadStrings(url);
    if (response != null) {
      println("Response: " + join(response, "\n"));
    }
  } catch (Exception e) {
    println("HTTP Error: " + e.getMessage());
  }
}

// Global variable to track pending requests
boolean waitingForResponse = false;
String lastRequestUrl = "";

void sendViaHttpAsync(String data) {
  // Only proceed if we're not currently waiting for a response
  if (waitingForResponse) {
    println("Skipping request - waiting for previous response");
    return;
  }
  
  try {
    String[] parts = splitTokens(data, ":,\n ");
    String url = "http://192.168.4.1/move?0=" + parts[1] + "&1=" + parts[3] + "&2=" + parts[5];
    lastRequestUrl = url; // Store for debugging
    
    waitingForResponse = true;
    println("Sending async request: " + url);
    
    // Create a new thread for the HTTP request
    new Thread(new Runnable() {
      public void run() {
        try {
          // Actually make the HTTP request
          String[] response = loadStrings(url);
          
          // Handle response (runs in the background thread)
          if (response != null && response.length > 0) {
            println("Async response: " + join(response, " "));
          } else {
            println("Empty async response");
          }
        } 
        catch (Exception e) {
          println("Async HTTP error: " + e.getMessage());
        } 
        finally {
          // This runs when the request completes (success or failure)
          waitingForResponse = false;
        }
      }
    }).start();
    
  } catch (Exception e) {
    println("Error preparing async request: " + e.getMessage());
    waitingForResponse = false;
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
