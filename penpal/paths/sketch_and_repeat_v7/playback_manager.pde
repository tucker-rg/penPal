// -------------------
// Top-level enums
// -------------------
enum PlaybackMode {
  PINGPONG, LOOP, JUMP
}

enum PlaybackState {
  IDLE, PLAYING, PAUSED
}

// -------------------
// Playback Manager
// -------------------
class PlaybackManager {
  private NormalizationManager normalizer = new NormalizationManager();

  // -- State --
  private int     currentStrokeIndex = 0;
  private int     currentPointIndex  = 0;
  private long    strokeStartTime    = 0;
  PlaybackState   state              = PlaybackState.IDLE;
  private long    pauseStartTime     = 0;
  private PVector lastPoint = new PVector(0, 0);

  // -- PingPong state --
  private boolean isReversing        = false;

  // -- Jump state: transition strokes --
  private Stroke  jumpReturnStroke   = null;
  private Stroke repositioningStroke = null;
  private boolean isPlayingJumpReturn = false;
  private boolean isPlayingRepositioning = true;

  // -- Settings --
  private float        replaySpeed   = 1.0;
  PlaybackMode         mode;
  boolean              useNormalized = true; // default value
  private float        easingFactor  = 0.05;

  // -- Doodles --
  Doodle doodleOriginal = null;
  Doodle doodleNormalized = null;

  // -- Dependencies --
  PApplet parent;

  PlaybackManager(PApplet parent) {
    this.parent = parent;
  }

  // =============================================================
  // Public API
  // =============================================================
  void play(Doodle d) {
    if (d == null) {
      return;
    }
    if (d.getCount() == 0) {
      return;
    }
    setDoodle(d);
    state = PlaybackState.PLAYING;
    resetAndReturn();
  }

  void pause() {
    if (state == PlaybackState.PLAYING) {
      state = PlaybackState.PAUSED;
      pauseStartTime = parent.millis();
    }
  }

  void resume() {
    if (getCurrentDoodle() == null) {
      return;
    }
    if (state == PlaybackState.PAUSED) {
      if (currentPointIndex == 0 && currentStrokeIndex == 0) {
        strokeStartTime = parent.millis(); // No need to worry about pause time, start from the beginning
      } else {
        strokeStartTime += (parent.millis() - pauseStartTime);
      }
      state = PlaybackState.PLAYING;
    }
  }

  void togglePauseResume() {
    if (state == PlaybackState.PLAYING) {
      pause();
    } else {
      resume();
    } 
  }

  void clear() {
    Doodle clearningDoodle = new Doodle();
    TimedPoint clearingPoint = new TimedPoint(new PVector(0, 0), 0);
    clearningDoodle.addPoint(clearingPoint);
    resetAndReturn();
    state = PlaybackState.IDLE;
  }

  void setDoodle(Doodle d) {
    if (d == null) return;
    doodleOriginal   = d;
    doodleNormalized = normalizer.getNormalizedDoodle(d, replaySpeed * 0.05, easingFactor);
    autoSetMode();
  }

  void setMode(PlaybackMode m) {
    mode = m;
    reset();
  }

  // Changing speed rebuilds the normalized doodle and resets cleanly
  void setReplaySpeed(float speed) {
    replaySpeed      = max(0.01, speed);
    doodleNormalized = normalizer.getNormalizedDoodle(doodleOriginal, replaySpeed * 0.05, easingFactor);
    reset();
  }

  void swapUseNormalized() {
    useNormalized = !useNormalized;
    // clampIndices()
    resetAndReturn();
  }

  void setUseNormalized(boolean val) {
    useNormalized = val;
    resetAndReturn();
  }

  void reset() { // resets the playback settings
    currentStrokeIndex  = 0;
    currentPointIndex   = 0;
    isReversing         = false;
    isPlayingJumpReturn = false;
    jumpReturnStroke    = null;
    strokeStartTime     = parent.millis();
  }

  void resetAndReturn() { // resets the playback settings and sends the tip back to the start
    reset();
    startRepositioning();
  }

  boolean getPlaying() { // returns true if currently playing
    if (state == PlaybackState.PLAYING) {
      return true;
    } return false;
  }

  // =============================================================
  // Main update — call every frame
  // =============================================================
  PVector update() { // returns the current tip location
    if (state != PlaybackState.PLAYING) return lastPoint;

    // --- Handle the jump-return transition stroke ---
    if (isPlayingJumpReturn) {
      PVector sendingPt = updateJumpReturn();
      lastPoint = sendingPt;
      return sendingPt;
    }

    if (isPlayingRepositioning) {
      PVector sendingPt = updateRepositioning();
      lastPoint = sendingPt;
      return sendingPt;
    }

    Doodle doodle = getCurrentDoodle();
    if (doodle == null || doodle.getStrokeCount() == 0) return null;

    Stroke stroke = doodle.getStroke(currentStrokeIndex);
    if (stroke == null || stroke.getCount() == 0) {
      advanceStroke(doodle);
      return null;
    }

    float     elapsed = computeElapsed(stroke);
    TimedPoint tp     = isReversing
                          ? findPointForElapsedReverse(stroke, elapsed)
                          : findPointForElapsed(stroke, elapsed);
    if (tp == null) return null;

    if (elapsed >= stroke.getDuration()) {
      advanceStroke(doodle);
    }
    
    lastPoint = tp.pos;
    return tp.pos;
  }

  // =============================================================
  // Stroke advancement — handles all modes and directions
  // =============================================================
  private void advanceStroke(Doodle doodle) {
    if (isReversing) {
      advanceStrokeReverse(doodle);
    } else {
      advanceStrokeForward(doodle);
    }
  }

  private void advanceStrokeForward(Doodle doodle) {
    currentStrokeIndex++;
    currentPointIndex = 0;
    strokeStartTime   = parent.millis();

    if (currentStrokeIndex >= doodle.getStrokeCount()) {
      handlePlaybackEnd(doodle);
    }
  }

  private void advanceStrokeReverse(Doodle doodle) {
    currentStrokeIndex--;
    currentPointIndex = doodle.getCount()-1;   // reset; findPointForElapsedReverse scans from end
    strokeStartTime   = parent.millis();

    if (currentStrokeIndex < 0) {
      // Reached the start while reversing — flip direction
      isReversing        = false;
      currentStrokeIndex = 0;
      currentPointIndex  = 0;
      strokeStartTime    = parent.millis();
    }
  }

  // =============================================================
  // End-of-doodle handling
  // =============================================================
  private void handlePlaybackEnd(Doodle doodle) {
    switch (mode) {
      case LOOP:
        reset();
        break;

      case PINGPONG:
        // Flip direction; start walking backwards from the last stroke
        isReversing        = true;
        currentStrokeIndex = doodle.getStrokeCount() - 1;
        currentPointIndex  = 0;
        strokeStartTime    = parent.millis();
        break;

      case JUMP:
        startJumpReturn(doodle);
        break;
    }
  }

  // =============================================================
  // JUMP: build and play a one-off return transition
  // =============================================================

  private void startJumpReturn(Doodle doodle) {
    PVector endPos   = doodle.getPoint(doodle.getCount() - 1).pos;
    PVector startPos = doodle.getPoint(0).pos;

    jumpReturnStroke    = new Stroke(endPos, startPos);
    isPlayingJumpReturn = true;
    currentPointIndex   = 0;
    strokeStartTime     = parent.millis();
  }

  // Manual control, w/ variable height, for reposiitoning
  private void startRepositioning() {
    PVector startPos = null;
    if (getCurrentDoodle() != null) {
      startPos = getCurrentDoodle().getStroke(0).getPointAtIndex(0).pos; // since we send the pointer back to the start
    }
    PVector endPos = lastPoint;
    if (endPos == null || startPos == null) {
      return;
    }
    repositioningStroke    = new Stroke(endPos, startPos, height);
    isPlayingRepositioning = true;
    isPlayingJumpReturn = false;
    currentPointIndex   = 0;
    strokeStartTime     = parent.millis();
  }

  private PVector updateJumpReturn() {
    if (jumpReturnStroke == null) {
      finishJumpReturn();
      return null;
    }

    // Transition strokes are never speed-scaled
    float      elapsed = parent.millis() - strokeStartTime;
    TimedPoint tp      = findPointForElapsedInStroke(jumpReturnStroke, elapsed);

    if (elapsed >= jumpReturnStroke.getDuration()) {
      finishJumpReturn();
    }

    return tp != null ? tp.pos : null;
  }

  private PVector updateRepositioning() {
    if (repositioningStroke == null) {
      finishRepositioning();
      return null;
    }

    float      elapsed = parent.millis() - strokeStartTime;
    TimedPoint tp      = findPointForElapsedInStroke(repositioningStroke, elapsed); 

    if (elapsed >= repositioningStroke.getDuration()) { 
      finishRepositioning();
    }

    return tp != null ? tp.pos : null;
  }

  private void finishJumpReturn() {
    jumpReturnStroke    = null;
    isPlayingJumpReturn = false;
    reset();
  }

  private void finishRepositioning() {
    repositioningStroke    = null;
    isPlayingRepositioning = false;
    reset();
  }

  // =============================================================
  // Time / point helpers
  // =============================================================

  // Scale elapsed time by replaySpeed, but never for transition strokes
  private float computeElapsed(Stroke stroke) {
    float rawElapsed = parent.millis() - strokeStartTime;
    return stroke.getIsTransition() ? rawElapsed : rawElapsed * replaySpeed;
  }

  // Forward scan: walk from currentPointIndex, return latest point <= elapsed
  private TimedPoint findPointForElapsed(Stroke stroke, float elapsed) {
    return findPointForElapsedInStroke(stroke, elapsed);
  }

  // Shared forward scan (used for both normal strokes and jumpReturnStroke)
  private TimedPoint findPointForElapsedInStroke(Stroke stroke, float elapsed) {
    TimedPoint result = null;
    for (int i = currentPointIndex; i < stroke.getCount(); i++) {
      TimedPoint tp = stroke.getPointAtIndex(i);
      if (tp == null) continue;
      if (tp.time <= elapsed) {
        result            = tp;
        currentPointIndex = i;
      } else {
        break;
      }
    }
    return result;
  }

  // Reverse scan: treat elapsed as time from the END of the stroke backwards.
  // We mirror the timestamp: reversedTime = duration - tp.time
  private TimedPoint findPointForElapsedReverse(Stroke stroke, float elapsed) {
    float      duration = stroke.getDuration();
    TimedPoint result   = null;

    // Scan backwards from the end of the stroke
    int startScan = (currentPointIndex == 0)
                      ? stroke.getCount() - 1
                      : currentPointIndex;

    for (int i = startScan; i >= 0; i--) {
      TimedPoint tp = stroke.getPointAtIndex(i);
      if (tp == null) continue;
      float reversedTime = duration - tp.time;
      if (reversedTime <= elapsed) {
        result            = tp;
        currentPointIndex = i;
        break;
      }
    }
    return result;
  }

  // =============================================================
  // Safe index clamping (call after any doodle/mode switch)
  // =============================================================
  private void clampIndices() {
    Doodle doodle = getCurrentDoodle();
    if (doodle == null || doodle.getStrokeCount() == 0) {
      currentStrokeIndex = 0;
      currentPointIndex  = 0;
      return;
    }
    currentStrokeIndex = constrain(currentStrokeIndex, 0, doodle.getStrokeCount() - 1);
    Stroke stroke = doodle.getStroke(currentStrokeIndex);
    int maxPoint  = (stroke != null) ? max(0, stroke.getCount() - 1) : 0;
    currentPointIndex = constrain(currentPointIndex, 0, maxPoint);
  }

  // =============================================================
  // Internal mode detection
  // =============================================================
  private void autoSetMode() {
    Doodle d = getCurrentDoodle();
    if (d == null || d.getCount() == 0) return;
    PVector startPos = d.getPoint(0).pos;
    PVector endPos   = d.getPoint(d.getCount() - 1).pos;
    mode = (PVector.dist(startPos, endPos) > 2.0)
             ? PlaybackMode.JUMP
            //  ? PlaybackMode.PINGPONG
             : PlaybackMode.LOOP;
  }

  Doodle getCurrentDoodle() {
    return useNormalized ? doodleNormalized : doodleOriginal;
  }
}

// NORMALIZATION MANAGER
class NormalizationManager {
  // generates a normalized doodle, given a target speed and an easing factor
  
  Doodle getNormalizedDoodle(Doodle d, float targetSpeed, float easingFactor) {
    //ArrayList<TimedPoint> normalized = new ArrayList<>();
    Doodle normalizedDoodle = new Doodle();
    for (int i = 0; i < d.getStrokeCount(); i++) {
      Stroke currStroke = d.getStroke(i);
      if (currStroke.getIsTransition() == true) {
        normalizedDoodle.addStroke(currStroke);
      } else {
        Stroke newStroke = normalizedDoodle.addDrawingStroke();
        ArrayList<TimedPoint> seg = currStroke.getAllPoints();
        ArrayList<TimedPoint> normalizedNewStrokePoints = normalizeSegment(seg, targetSpeed, easingFactor);
        newStroke.setPoints(normalizedNewStrokePoints);
      }
    }
    return normalizedDoodle;
  }
  
  // helper: runs normalization logic on a contiguous segment
  ArrayList<TimedPoint> normalizeSegment(ArrayList<TimedPoint> seg, float targetSpeed, float easingFactor) {
    ArrayList<TimedPoint> out = new ArrayList<>();
  
    // --- compute lengths ---
    float totalLength = 0;
    float[] segLengths = new float[seg.size() - 1];
    for (int j = 0; j < seg.size() - 1; j++) {
      float l = PVector.dist(seg.get(j).pos, seg.get(j + 1).pos);
      segLengths[j] = l;
      totalLength += l;
    }
    if (totalLength == 0) {
      out.add(new TimedPoint(seg.get(0).pos.copy(), seg.get(0).time));
      return out;
    }
  
    int newCount = max(int(totalLength * 4), 2);
    float totalTime = totalLength / targetSpeed;
    float timePerPoint = totalTime / (newCount - 1);
  
    for (int k = 0; k < newCount; k++) {
      float alpha = (float)k / (newCount - 1);
  
      float linearAlpha = alpha;
      float easedAlpha = (1 - cos(PI * alpha)) / 2.0;
      float distanceAlpha = lerp(linearAlpha, easedAlpha, easingFactor);
  
      float targetDist = distanceAlpha * totalLength;
      float time = seg.get(0).time + k * timePerPoint; // anchor times to first point
  
      // find segment
      float accum = 0;
      int segIdx = 0;
      while (segIdx < segLengths.length && accum + segLengths[segIdx] < targetDist) {
        accum += segLengths[segIdx];
        segIdx++;
      }
      segIdx = min(segIdx, segLengths.length - 1);
      float remain = targetDist - accum;
      float t = (segLengths[segIdx] == 0) ? 0 : constrain(remain / segLengths[segIdx], 0, 1);
  
      PVector p = PVector.lerp(seg.get(segIdx).pos, seg.get(segIdx + 1).pos, t);
      out.add(new TimedPoint(p, time));
    }
  
    return out;
  }
}
