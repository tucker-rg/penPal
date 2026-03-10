// ------- SKETCH AND REPEAT VERSION 7 -------

// This is the main tab, handles external input, setup() and draw()

// imports
import java.util.*;
import controlP5.*;
import processing.serial.*;

// ===== Coordinate System =====
final float GRID_MIN = -12.5;
final float GRID_MAX = 12.5;

// System state
static enum State {
  DRAWING, // currently drawing (i.e. the mouse is being pressed in the squre)
  PLAYBACK, // handled by the playback manager, including pause
  DORMANT // nothing at all, (i.e. the playback manager has yet to be built for a new doodle)
}

// Pen communication
Serial myPort;
final boolean OFFLINE = false; // for testing purpose, otherwise set FALSE

State systemState = State.DORMANT;
ControlP5 cp5;
UIManager ui; // To manage UI
MotorCommand motorCommand; // To communicate with the pen
PlaybackManager playbackManager; // To manage playback

// Presets
final int NUM_PRESETS = 8; // this is hard coded
Doodle[] presets = new Doodle[NUM_PRESETS]; 
int selectedPreset = 0;

// current state
Doodle currentDoodle; // Holds the current doodle, one of the presets
// settings like angle, speed, size handled by the playback manager

void setup() {
  size(1000, 600);
  // fullScreen();

  if (!OFFLINE) {
    println("setting up serial");
    // Serial setup
    printArray(Serial.list());
    String portName = Serial.list()[3];  // Adjust index as needed
    myPort = new Serial(this, portName, 115200); //57600
    myPort.bufferUntil('\n');  // trigger serialEvent on newline
  }

  cp5 = new ControlP5(this);

  for (int i = 0; i < 4; i++) {
    presets[i] = new Doodle();
  }
  presets[4] = createLine();
  presets[5] = createTriangle();
  presets[6] = createCircle();
  presets[7] = createStamp();

  currentDoodle = presets[selectedPreset].copy(); // We make sure to only set currentDoodle to copies of the presets

  motorCommand = new MotorCommand();
  playbackManager = new PlaybackManager(this);
  ui = new UIManager(this, cp5);
}

void draw() {
  PVector newPoint = null;

  newPoint = playbackManager.update(); // get the latest point (playbackManager accounts for idle or paused)
  if (!OFFLINE && newPoint != null) {
    motorCommand.sendMotorCommand(newPoint, 30.0); // send the latest point
    // print(newPoint.x, newPoint.y, newPoint.z);
  }

  background(180);

  ui.draw(currentDoodle, newPoint, selectedPreset); // draw the ui with new updates
  
}

// handle mouse input, drawing things
int strokeStartMillis;
final float MIN_DIST = 0.2; // threshold in grid space

void mousePressed() {
  // Get the grid position
  PVector gridPos = ui.getGridPos();
  
  if (gridPos == null) return; // i.e. out of bounds
  
  systemState = State.DRAWING;
  strokeStartMillis = millis();
  playbackManager.pause();
  
  currentDoodle.addDrawingStroke();
  appendGridPos(gridPos);
}

void mouseDragged() {
  if (systemState != State.DRAWING) return;
  
  PVector gridPos = ui.getGridPos();
  if (gridPos == null) { // i.e. out of bounds
    playbackManager.setDoodle(currentDoodle);
    systemState = State.DORMANT;
    return;
  }
  appendGridPos(gridPos);
}

void mouseReleased() {
  if (systemState == State.DRAWING) {
    playbackManager.setDoodle(currentDoodle);
    systemState = State.DORMANT;
  }
}

void appendGridPos(PVector grid) {
  // Time since stroke start
  float t = millis() - strokeStartMillis;

  // Avoid adding points too close together
  Stroke latest = currentDoodle.getLastStroke();
  PVector last = latest.getLastPoint();

  if (last != null && grid.dist(last) < MIN_DIST) {
    return;
  }

  currentDoodle.addPoint(new TimedPoint(playbackManager.undoTransformations(grid), t));
}

void handleTogglePlayback() {
  if (systemState != State.PLAYBACK) { // We are doing a new drawing
    if (currentDoodle.getCount() == 0) {
      print("Tried to start playback, but the doodle is empty");
      return;
    }
    playbackManager.play(currentDoodle);
    systemState = State.PLAYBACK;
  } else {
    playbackManager.togglePauseResume();
  }
}

void handleClear() {
  currentDoodle = new Doodle();
  playbackManager.clear(currentDoodle);
  systemState = State.DORMANT;
}

void handleNormalize() {
  playbackManager.swapUseNormalized();
}

void replaySpeed(float val) {
  playbackManager.setReplaySpeed(val);
}

void angle(int a) {
  playbackManager.setAngle(a);
}

void size(float s) {
  playbackManager.setSize(s);
}

void controlEvent(ControlEvent e) {
  // println("controlEvent fired: " + e.getName());
}


void selectPreset(int i) {
  playbackManager.makeIdle();
  currentDoodle = presets[i].copy(); 
  selectedPreset = i;
  playbackManager.setDoodle(currentDoodle);
  systemState = State.DORMANT;
}

void save() {
  if (selectedPreset >= 4 && selectedPreset < 8) {
    println("Cannot overwrite default preset!");
    return;
  }
  presets[selectedPreset] = currentDoodle;
  ui.resetThumbnail(selectedPreset);
}

void set0() {
  selectPreset(0);
}

void set1() {
  selectPreset(1);
}

void set2() {
  selectPreset(2);
}

void set3() {
  selectPreset(3);
}

void set4() {
  selectPreset(4);
}

void set5() {
  selectPreset(5);
}

void set6() {
  selectPreset(6);
}

void set7() {
  selectPreset(7);
}


// keyboard shortcuts
void keyPressed() {
  if (key == ' ') {
    handleTogglePlayback();
  }
  
  if (key == 'c') {
    handleClear();
  }
  
  if (key == 'n') {
    handleNormalize();
  }
}