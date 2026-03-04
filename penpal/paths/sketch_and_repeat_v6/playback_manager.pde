// -------------------
// Top-level enums
// -------------------
enum PlaybackMode {
  MODE_PING_PONG,
  MODE_LOOP,
  MODE_BACK_TO_START
}

// -------------------
// Playback Manager
// -------------------
class PlaybackManager {
  int lastSentIndex = -1;
  int replayStartTime = 0;
  int revReplayStartTime = 0;
  int replayIndex = 0;
  int revReplayIndex = 0;

  PlaybackMode mode = PlaybackMode.MODE_LOOP;

  Doodle doodleOriginal;
  Doodle doodleNormalized;
  boolean useNormalized = false;

  // Tracks if currently playing forward (true) or reverse (false)
  boolean forward = true;

  // -------------------
  // Set doodle and mode
  // -------------------
  void setDoodle(Doodle d, boolean normalized) {
    if (d == null) return;
    useNormalized = normalized;
    if (normalized) doodleNormalized = d;
    else doodleOriginal = d;
    autoSetMode();
    reset();
  }

  void toggleNormalized() {
    useNormalized = !useNormalized;
    autoSetMode();
    reset();
  }

  void setMode(PlaybackMode m) {
    mode = m;
    reset();
  }

  void setSpeed(float speed) {
    if (getCurrentDoodle() != null) getCurrentDoodle().setReplaySpeed(speed);
  }

  void reset() {
    lastSentIndex = -1;
    replayStartTime = millis();
    revReplayStartTime = millis();
    replayIndex = 0;
    revReplayIndex = getCurrentDoodle() != null ? getCurrentDoodle().getCount() - 1 : 0;
    forward = true;
  }

  // -------------------
  // Auto-detect mode
  // -------------------
  void autoSetMode() {
    Doodle d = getCurrentDoodle();
    if (d == null || d.getCount() == 0) return;

    PVector startPos = d.getPoint(0).pos;
    PVector endPos = d.getPoint(d.getCount() - 1).pos;

    if (PVector.dist(startPos, endPos) > 2.0) {
      mode = PlaybackMode.MODE_BACK_TO_START;
    } else {
      mode = PlaybackMode.MODE_LOOP;
    }
  }

  Doodle getCurrentDoodle() {
    return useNormalized ? doodleNormalized : doodleOriginal;
  }

  // -------------------
  // Main update loop
  // -------------------
  void update() {
    Doodle current = getCurrentDoodle();
    if (current == null || current.getCount() == 0) return;

    switch (mode) {
      case MODE_PING_PONG:
        managePingPong(current);
        break;
      case MODE_LOOP:
        manageLoop(current);
        break;
      case MODE_BACK_TO_START:
        manageBackToStart(current);
        break;
    }
  }

  // -------------------
  // Playback modes
  // -------------------
  void managePingPong(Doodle doodle) {
    if (forward) {
      float t = (millis() - replayStartTime) * doodle.getReplaySpeed();
      int idx = findTargetIndexForward(doodle, replayIndex, t);

      if (idx != -1 && idx != lastSentIndex) {
        penControl.sendMotorCommand(doodle.getPoint(idx).pos);
        lastSentIndex = idx;
        replayIndex = idx + 1;
      }

      if (replayIndex >= doodle.getCount()) {
        forward = false;
        revReplayStartTime = millis();
        lastSentIndex = -1;
        revReplayIndex = doodle.getCount() - 1;
      }
    } else {
      float t = (millis() - revReplayStartTime) * doodle.getReplaySpeed();
      float maxTime = doodle.getPoint(doodle.getCount() - 1).time;
      int idx = findTargetIndexReverse(doodle, revReplayIndex, maxTime, t);

      if (idx != -1 && idx != lastSentIndex) {
        penControl.sendMotorCommand(doodle.getPoint(idx).pos);
        lastSentIndex = idx;
        revReplayIndex = idx - 1;
      }

      if (revReplayIndex < 0) {
        forward = true;
        replayStartTime = millis();
        lastSentIndex = -1;
        replayIndex = 0;
      }
    }
  }

  void manageLoop(Doodle doodle) {
    float t = (millis() - replayStartTime) * doodle.getReplaySpeed();
    int idx = findTargetIndexForward(doodle, replayIndex, t);

    if (idx != -1 && idx != lastSentIndex) {
      penControl.sendMotorCommand(doodle.getPoint(idx).pos);
      lastSentIndex = idx;
      replayIndex = idx + 1;
    }

    if (replayIndex >= doodle.getCount()) {
      // loop jumps straight to start without transition
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }

  void manageBackToStart(Doodle doodle) {
    float t = (millis() - replayStartTime) * doodle.getReplaySpeed();
    int idx = findTargetIndexForward(doodle, replayIndex, t);

    if (idx != -1 && idx != lastSentIndex) {
      penControl.sendMotorCommand(doodle.getPoint(idx).pos);
      lastSentIndex = idx;
      replayIndex = idx + 1;
    }

    if (replayIndex >= doodle.getCount()) {
      // use the transition stroke back to start
      PVector startPos = doodle.getPoint(0).pos;
      PVector endPos = doodle.getPoint(doodle.getCount() - 1).pos;

      // create temporary stroke for transition
      Stroke transition = new Stroke(endPos, startPos);
      for (TimedPoint tp : transition.getAllPoints()) {
        penControl.sendMotorCommand(tp.pos);
      }

      // reset to start
      replayStartTime = millis();
      lastSentIndex = -1;
      replayIndex = 0;
    }
  }

  // -------------------
  // Helpers
  // -------------------
  int findTargetIndexForward(Doodle d, int startIdx, float t) {
    for (int i = startIdx; i < d.getCount(); i++) {
      if (d.getPoint(i).time <= t) continue;
      return i - 1 >= startIdx ? i - 1 : startIdx;
    }
    return d.getCount() - 1;
  }

  int findTargetIndexReverse(Doodle d, int startIdx, float maxTime, float t) {
    for (int i = startIdx; i >= 0; i--) {
      if ((maxTime - d.getPoint(i).time) <= t) return i;
    }
    return 0;
  }

  // -------------------
  // External controls
  // -------------------
  void pause() {
    state = 0; // matches your existing DRAWING / PLAYBACK system
  }

  void resume() {
    state = 1;
    replayStartTime = millis();
  }

  void jumpToStart() {
    reset();
  }
}
