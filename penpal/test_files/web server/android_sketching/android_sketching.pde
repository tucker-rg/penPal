import android.os.Bundle;
import android.view.MotionEvent;
import android.net.*;
import java.io.*;

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

// Drawing and control variables
TimedPoint[] stroke = new TimedPoint[1000];
int strokeCount = 0;
int strokeStartTime;
boolean drawing = false;
boolean replaying = false;
boolean revReplaying = false;
int replayStartTime;
int replayIndex;
int revReplayStartTime;
int revReplayIndex;
int lastSentIndex = -1;
int mode = 1; // 0: send live, 1: replay

// Drawing area bounds
final float DRAWING_MIN_X = -12.5;
final float DRAWING_MAX_X = 12.5;
final float DRAWING_MIN_Y = -12.5;
final float DRAWING_MAX_Y = 12.5;

// Speed control
float replaySpeed = 1.0;
final float SPEED_INCREMENT = 0.25;
final float MIN_SPEED = 0.25;
final float MAX_SPEED = 5.0;

// Button layout
final int BUTTON_WIDTH = 120;
final int BUTTON_HEIGHT = 50;
final int CONTROL_PANEL_HEIGHT = 60;
int slowButtonX, fastButtonX, speedDisplayX;

// Networking
String lastCommand = "";
boolean waitingForResponse = false;
String lastRequestUrl = "";

// Android touch tracking
boolean[] touchDown = new boolean[10];

// ================= ANDROID LIFECYCLE =================
void onCreate(Bundle savedInstanceState) {
  super.onCreate(savedInstanceState);
  orientation(PORTRAIT); // Lock to portrait mode
}

void settings() {
  fullScreen();
  pixelDensity(displayDensity()); // Handle high-res displays
}

void setup() {
  // Initialize button positions
  slowButtonX = width/4 - BUTTON_WIDTH/2;
  fastButtonX = 3*width/4 - BUTTON_WIDTH/2;
  speedDisplayX = width/2;
  
  // Load your motor lookup table
  loadLookup();
  
  println("Setup complete");
}

// ================= MAIN DRAW LOOP =================
void draw() {
  background(255);
  
  // Draw control panel
  drawSpeedControls();
  
  // Draw the current stroke
  drawCurrentStroke();
  
  // Handle replay if active
  if (mode == 1) {
    manageReplay();
  }
  
  // Debug touch points
  drawTouchDebug();
}

// ================= TOUCH HANDLING =================
public boolean surfaceTouchEvent(MotionEvent event) {
  int action = event.getActionMasked();
  int idx = event.getActionIndex();
  int id = event.getPointerId(idx);
  
  switch(action) {
    case MotionEvent.ACTION_DOWN:
    case MotionEvent.ACTION_POINTER_DOWN:
      touchDown[id] = true;
      touchStarted(event.getX(idx), event.getY(idx));
      break;
      
    case MotionEvent.ACTION_MOVE:
      for (int i = 0; i < event.getPointerCount(); i++) {
        if (touchDown[event.getPointerId(i)]) {
          touchMoved(event.getX(i), event.getY(i));
        }
      }
      break;
      
    case MotionEvent.ACTION_UP:
    case MotionEvent.ACTION_POINTER_UP:
      touchDown[id] = false;
      touchEnded(event.getX(idx), event.getY(idx));
      break;
  }
  return super.surfaceTouchEvent(event);
}

void touchStarted(float x, float y) {
  if (y < CONTROL_PANEL_HEIGHT) {
    // Handle control panel touches
    if (x >= slowButtonX && x <= slowButtonX + BUTTON_WIDTH) {
      replaySpeed = max(MIN_SPEED, replaySpeed - SPEED_INCREMENT);
    } 
    else if (x >= fastButtonX && x <= fastButtonX + BUTTON_WIDTH) {
      replaySpeed = min(MAX_SPEED, replaySpeed + SPEED_INCREMENT);
    }
    return;
  }
  
  // Start new stroke
  strokeCount = 0;
  strokeStartTime = millis();
  drawing = true;
  replaying = false;
  revReplaying = false;
}

void touchMoved(float x, float y) {
  if (!drawing || y < CONTROL_PANEL_HEIGHT) return;
  
  Vec2 pos = new Vec2(x, y - CONTROL_PANEL_HEIGHT);
  float t = millis() - strokeStartTime;
  
  if (strokeCount < stroke.length) {
    stroke[strokeCount++] = new TimedPoint(pos, t);
  }

  if (mode == 0) {
    sendMotorCommand(pos.x, pos.y);
  }
}

void touchEnded(float x, float y) {
  if (mode == 1) {
    drawing = false;
    replaying = true;
    replayStartTime = millis();
    replayIndex = 0;
  }
}

// ================= DRAWING FUNCTIONS =================
void drawSpeedControls() {
  // Control panel background
  fill(240);
  noStroke();
  rect(0, 0, width, CONTROL_PANEL_HEIGHT);
  
  // Slow button
  fill(200);
  rect(slowButtonX, 10, BUTTON_WIDTH, BUTTON_HEIGHT, 10);
  fill(0);
  textAlign(CENTER, CENTER);
  textSize(18);
  text("SLOWER", slowButtonX + BUTTON_WIDTH/2, 10 + BUTTON_HEIGHT/2);
  
  // Speed display
  fill(255);
  rect(speedDisplayX - BUTTON_WIDTH/2, 10, BUTTON_WIDTH, BUTTON_HEIGHT, 10);
  fill(0);
  text(nf(replaySpeed, 1, 2) + "x", speedDisplayX, 10 + BUTTON_HEIGHT/2);
  
  // Fast button
  fill(200);
  rect(fastButtonX, 10, BUTTON_WIDTH, BUTTON_HEIGHT, 10);
  fill(0);
  text("FASTER", fastButtonX + BUTTON_WIDTH/2, 10 + BUTTON_HEIGHT/2);
}

void drawCurrentStroke() {
  pushMatrix();
  translate(0, CONTROL_PANEL_HEIGHT);
  
  // Draw the stroke
  if (strokeCount > 1) {
    beginShape();
    noFill();
    stroke(0);
    strokeWeight(4);
    for (int i = 0; i < strokeCount; i++) {
      vertex(stroke[i].pos.x, stroke[i].pos.y);
    }
    endShape();
  }
  
  // Draw out-of-bounds warning
  if (drawing && touchDown[0]) {
    float realX = map(stroke[strokeCount-1].pos.x, 0, width, DRAWING_MIN_X, DRAWING_MAX_X);
    float realY = map(stroke[strokeCount-1].pos.y, 0, height-CONTROL_PANEL_HEIGHT, DRAWING_MIN_Y, DRAWING_MAX_Y);
    
    if (realX < DRAWING_MIN_X || realX > DRAWING_MAX_X || 
        realY < DRAWING_MIN_Y || realY > DRAWING_MAX_Y) {
      fill(255, 0, 0, 100);
      noStroke();
      ellipse(stroke[strokeCount-1].pos.x, stroke[strokeCount-1].pos.y, 40, 40);
      fill(0);
      textAlign(CENTER, CENTER);
      text("OUT OF BOUNDS", stroke[strokeCount-1].pos.x, stroke[strokeCount-1].pos.y);
    }
  }
  
  popMatrix();
}

void drawTouchDebug() {
  // Visualize touch points (debug)
  for (int i = 0; i < touchDown.length; i++) {
    if (touchDown[i]) {
      fill(255, 0, 0, 100);
      noStroke();
      ellipse(touches[i].x, touches[i].y, 50, 50);
    }
  }
}

// ================= REPLAY SYSTEM =================
void manageReplay() {
  if (replaying) {
    float currentTargetTime = (millis() - replayStartTime) * replaySpeed;
    
    // Find current point to display
    int targetIndex = -1;
    for (int i = replayIndex; i < strokeCount; i++) {
      if (stroke[i].time <= currentTargetTime) {
        targetIndex = i;
      } else {
        break;
      }
    }
    
    // Send motor command if new point found
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      sendMotorCommand(stroke[targetIndex].pos.x, stroke[targetIndex].pos.y);
      lastSentIndex = targetIndex;
      replayIndex = targetIndex + 1;
    }
    
    // Check if reached end
    if (replayIndex >= strokeCount) {
      startReversePlayback();
    }
  }
  
  if (revReplaying) {
    float currentTargetTime = (millis() - replayStartTime) * replaySpeed;
    float maxTime = stroke[strokeCount-1].time;
    
    // Find current point in reverse
    int targetIndex = -1;
    for (int i = revReplayIndex; i >= 0; i--) {
      if ((maxTime - stroke[i].time) <= currentTargetTime) {
        targetIndex = i;
      } else {
        break;
      }
    }
    
    // Send motor command if new point found
    if (targetIndex != -1 && targetIndex != lastSentIndex) {
      sendMotorCommand(stroke[targetIndex].pos.x, stroke[targetIndex].pos.y);
      lastSentIndex = targetIndex;
      revReplayIndex = targetIndex - 1;
    }
    
    // Check if reached start
    if (revReplayIndex < 0) {
      startForwardPlayback();
    }
  }
}

void startForwardPlayback() {
  replaying = true;
  revReplaying = false;
  replayStartTime = millis();
  replayIndex = 0;
  lastSentIndex = -1;
}

void startReversePlayback() {
  replaying = false;
  revReplaying = true;
  replayStartTime = millis();
  revReplayIndex = strokeCount - 1;
  lastSentIndex = -1;
}

// ================= MOTOR CONTROL =================
void sendMotorCommand(float x, float y) {
  if (waitingForResponse) return;
  
  float realX = map(x, 0, width, DRAWING_MIN_X, DRAWING_MAX_X);
  float realY = map(y, 0, height-CONTROL_PANEL_HEIGHT, DRAWING_MIN_Y, DRAWING_MAX_Y);
  
  String[] row = findRow(realX, realY);
  if (row != null) {
    String data = "0:" + row[2] + ",1:" + row[3] + ",2:" + row[4];
    sendAndroidHttp(data);
  }
}

void sendAndroidHttp(final String data) {
  waitingForResponse = true;
  new Thread(new Runnable() {
    public void run() {
      try {
        URL url = new URL("http://192.168.4.1/move?" + data);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(1000);
        
        BufferedReader in = new BufferedReader(
          new InputStreamReader(conn.getInputStream()));
        String response = in.readLine();
        in.close();
        
        println("Response: " + response);
      } catch (Exception e) {
        println("HTTP Error: " + e.getMessage());
      } finally {
        waitingForResponse = false;
      }
    }
  }).start();
}

// ================= HELPER FUNCTIONS =================
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

// ================= ANDROID MANIFEST =================
// Add this to your sketch's manifest.xml file:
/*
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          package="your.package.name">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
</manifest>
*/
