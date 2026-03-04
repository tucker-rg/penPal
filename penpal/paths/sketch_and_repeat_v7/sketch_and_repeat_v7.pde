// ------- SKETCH AND REPEAT VERSION 7 -------

// This is the main tab, handles external input, setup() and draw()

// imports
import java.util.*;
import controlP5.*;

// ===== Coordinate System =====
final float GRID_MIN = -12.5;
final float GRID_MAX = 12.5;

// System state
static enum State {
  DRAWING, // currently drawing
  PLAYBACK, // handled by the playback manager, including pause
  DORMANT // nothing at all
}

State systemState = State.DRAWING;
ControlP5 cp5;
UIManager ui; // To manage UI
Doodle currentDoodle; // Holds the current doodle
MotorCommand motorCommand; // To communicate with the pen
PlaybackManager playbackManager; // To manage playback

void setup() {
  size(1000, 600);
  cp5 = new ControlP5(this);

  currentDoodle = new Doodle();
  motorCommand = new MotorCommand();
  playbackManager = new PlaybackManager(this);
  ui = new UIManager(this, cp5, currentDoodle);
}

void draw() {
  PVector newPoint = null;

  newPoint = playbackManager.update(); // get the latest point (if playback, otherwise returns the last point sent)
  motorCommand.sendMotorCommand(newPoint); // send the latest motor command

  background(180);

  ui.draw(newPoint, currentDoodle); // draw the ui
  
}

// handle mouse input, drawing things
int strokeStartMillis;
final float MIN_DIST = 0.5; // threshold in grid space

void mousePressed() {
  // Get the grid position
  PVector gridPos = ui.getGridPos();
  
  if (gridPos == null) return; // i.e. out of bounds
  
  systemState = State.DRAWING;
  strokeStartMillis = millis();
  
  if (currentDoodle.getCount() > 0) { // if this isn't the first stroke, we have to deal with transition
    currentDoodle.addTransitionStroke(gridPos);
  }
  
  currentDoodle.addDrawingStroke();
  appendGridPos(gridPos);
}

void mouseDragged() {
  if (systemState != State.DRAWING) return;
  
  PVector gridPos = ui.getGridPos();
  if (gridPos == null) { // i.e. out of bounds
    systemState = State.DORMANT;
    return;
  }
  appendGridPos(gridPos);
}

void mouseReleased() {
  PVector gridPos = ui.getGridPos();
  if (gridPos == null) return; // i.e. out of bounds

  systemState = State.DORMANT;
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

  currentDoodle.addPoint(new TimedPoint(grid, t));
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
  // playbackManager = new PlaybackManager(this);
  playbackManager.clear();
  systemState = State.DORMANT;
  println("handleClear called!");
}

void handleNormalize() {
  playbackManager.swapUseNormalized();
}

void replaySpeed(float val) {
  playbackManager.setReplaySpeed(val);
}

void controlEvent(ControlEvent theEvent) {
  println("controlEvent fired: " + theEvent.getName());
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
