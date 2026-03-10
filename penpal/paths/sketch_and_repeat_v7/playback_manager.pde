// -------------------
// Top-level enum
// -------------------
enum PlaybackState {
  IDLE,
  PLAYING,
  PAUSED
}

// -------------------
// Playback Manager
// -------------------
class PlaybackManager {
  private NormalizationManager normalizer = new NormalizationManager();

  // -- State --
  private int     currentStrokeIndex  = 0;
  private int     currentPointIndex   = 0;
  private long    strokeStartTime     = 0;
  PlaybackState   state               = PlaybackState.IDLE;
  private long    pauseStartTime      = 0;
  private PVector lastPoint           = new PVector(0, 0); // the last point sent to the pen (transformed)

  // -- Transition state --
  private Stroke  transitionStroke       = null;
  private boolean isPlayingTransition    = false;
  private int     transitionTargetIndex  = 0;

  // -- Settings --
  private float     replaySpeed            = 1.0;
  private float     normalizedTargetSpeed  = 0.05; // mm/ms, corresponding to a 1.0 replaySpeed
  int       angle                  = 0; 
  float     size                   = 1.0; 
  boolean           useNormalized          = true; // Default to true, "motion smoothing"
  private float     easingFactor           = 0.05; // I honestly forgot what this does
  private float     transitionGapThreshold = 0.5; // Below this threshold, the pen will not "jump" to the next stroke, because it is already too close
  
  // -- Computed limits --
  private float maxSize = MAX_FLOAT;
  private int minAngle = -180; // these are actually offsets from the current angle
  private int maxAngle = 180;

  // -- Doodles --
  Doodle doodleOriginal   = null;
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
    if (d == null || d.getCount() == 0) return;
    // setDoodle(d); now we do this as we draw, so that the transformations work in advance
    state = PlaybackState.PLAYING;
    resetAndReturn();
  }

  void pause() {
    if (state == PlaybackState.PLAYING) {
      println("paused");
      state          = PlaybackState.PAUSED;
      pauseStartTime = parent.millis();
    }
  }

  void resume() {
    println("Called resume");
    if (getCurrentDoodle() == null) return;
    if (state == PlaybackState.PLAYING) return;

    if (state == PlaybackState.IDLE) {
      state = PlaybackState.PLAYING;
      startReturnToStart();
    } else if (state == PlaybackState.PAUSED) {
      if (currentPointIndex == 0 && currentStrokeIndex == 0) {
        strokeStartTime = parent.millis();
      } else {
        strokeStartTime += (parent.millis() - pauseStartTime);
      }
      state = PlaybackState.PLAYING;
      print("state is now PLAYING");
    }
  }

  void togglePauseResume() {
    println("");
    println("called togglePauseResume");
    if (state == PlaybackState.IDLE) {
      println("ITs IDLE");
    }
    println("");
    if (state == PlaybackState.PLAYING) pause();
    else resume();
  }

  void clear(Doodle d) {
    makeIdle();
    setDoodle(d); // should be a clear doodle
    // reset these settings whever we clear the doodle
    size = 1.0;
    angle = 0;
  }

  void makeIdle() {
    state = PlaybackState.IDLE;
    print("state is now IDLE");
  }

  void setDoodle(Doodle d) {
    if (d == null) return;
    doodleOriginal   = d;
    doodleNormalized = normalizer.getNormalizedDoodle(d, normalizedTargetSpeed, easingFactor);
    computeLimits();
  }

  void computeLimits() {
    maxSize  = computeMaxSize();
    computeMaxAngles();
  }

  private float computeMaxSize() {
    Doodle d = getCurrentDoodle();
    if (d == null) return MAX_FLOAT;
    float maxExtent = 0;

    for (int i = 0; i < d.getStrokeCount(); i++) {
      Stroke s = d.getStroke(i);
      for (int j = 0; j < s.getCount(); j++) {
        PVector p = applyAngle(s.getPointAtIndex(j).pos);
        maxExtent = max(maxExtent, abs(p.x));
        maxExtent = max(maxExtent, abs(p.y));
      }
    }

    if (maxExtent == 0) return 2.0;
    return 12.5 / maxExtent;
  }

  private void computeMaxAngles() {
    // find max positive angle
    maxAngle = 0;
    for (int a = angle; a <= 180; a++) {
      if (allPointsFit(size, a)) maxAngle = a;
      else break;
    }

    // find min (most negative) angle
    minAngle = 0;
    for (int a = angle; a >= -180; a--) {
      if (allPointsFit(size, a)) minAngle = a;
      else break;
    }
  }

  private boolean allPointsFit(float testSize, int testAngle) {
    Doodle d = getCurrentDoodle();
    if (d == null) return true;
    float a    = radians(-testAngle);
    float cosA = cos(a);
    float sinA = sin(a);

    for (int i = 0; i < d.getStrokeCount(); i++) {
      Stroke s = d.getStroke(i);
      for (int j = 0; j < s.getCount(); j++) {
        PVector p = s.getPointAtIndex(j).pos;
        float x  = p.x * testSize;
        float y  = p.y * testSize;
        float xr = x * cosA - y * sinA;
        float yr = x * sinA + y * cosA;
        if (abs(xr) > 12.5 || abs(yr) > 12.5) return false;
      }
    }
    return true;
  }

  void setReplaySpeed(float speed) {
    float oldSpeed      = replaySpeed;
    replaySpeed         = max(0.01, speed);
    if (isPlayingTransition) return; // transitions are unaffected by speed, no re-anchor needed
    float rawElapsed    = parent.millis() - strokeStartTime;
    float scaledElapsed = rawElapsed * oldSpeed;
    strokeStartTime     = (long)(parent.millis() - scaledElapsed / replaySpeed);
  }

  void setAngle(int a) {
    angle   = constrain(a, minAngle, maxAngle);
    maxSize = computeMaxSize();
    if (state == PlaybackState.PAUSED) {
      print("idle");
      state = PlaybackState.IDLE;
      print("state is now IDLE");
    }
  }

  void setSize(float s) {
    size = constrain(s, 0.01, maxSize);
    computeMaxAngles();
    if (state == PlaybackState.PAUSED) {
      print("idle");
      state = PlaybackState.IDLE;
      print("state is now IDLE");
    }
  }

  void swapUseNormalized() {
    useNormalized = !useNormalized;
    resetAndReturn();
  }

  void setUseNormalized(boolean val) {
    useNormalized = val;
    resetAndReturn();
  }

  void reset() {
    currentStrokeIndex     = 0;
    currentPointIndex      = 0;
    isPlayingTransition    = false;
    transitionStroke       = null;
    transitionTargetIndex  = 0;
    strokeStartTime        = parent.millis();
  }

  void resetAndReturn() {
    reset();
    startReturnToStart();
  }

  boolean isPlaying() {
    return state == PlaybackState.PLAYING;
  }

  boolean isPaused() {
    return state == PlaybackState.PAUSED;
  }

  boolean isIdle() {
    return state == PlaybackState.IDLE;
  }

  float getReplaySpeed() {
    return replaySpeed;
  }

  // =============================================================
  // Main update — call every frame
  // =============================================================
  PVector update() { // returns the current tip location
    if (state != PlaybackState.PLAYING) return lastPoint;

    // --- Handle the jump-return transition stroke ---
    if (isPlayingTransition) {
      PVector sendingPt = updateTransition();
      lastPoint = applyTransformations(sendingPt);
      return lastPoint;
    }

    Doodle doodle = getCurrentDoodle();
    if (doodle == null || doodle.getStrokeCount() == 0) return lastPoint;

    Stroke stroke = doodle.getStroke(currentStrokeIndex);
    if (stroke == null || stroke.getCount() == 0) {
      advanceStroke(doodle);
      return lastPoint;
    }

    float     elapsed = computeElapsed();
    TimedPoint tp     = findPointForElapsed(stroke, elapsed);
    if (tp == null) return lastPoint;
    
    lastPoint = applyTransformations(tp.pos);   
    
    if (elapsed >= stroke.getDuration()) {
      advanceStroke(doodle);
    }
    
    return lastPoint;
  }

  // =============================================================
  // Stroke advancement
  // =============================================================
  private void advanceStroke(Doodle doodle) {
    int nextIndex = currentStrokeIndex + 1;

    if (nextIndex >= doodle.getStrokeCount()) {
      nextIndex = 0;
    }

    Stroke currentStroke = doodle.getStroke(currentStrokeIndex);
    PVector endPos   = currentStroke.getLastPoint();
    PVector startPos = doodle.getStroke(nextIndex).getFirstPoint();

    if (PVector.dist(endPos, startPos) > transitionGapThreshold) {
      transitionTargetIndex  = nextIndex;
      startTransition(endPos, startPos);
    } else {
      currentStrokeIndex = nextIndex;
      currentPointIndex  = 0;
      strokeStartTime    = strokeStartTime + (long)(currentStroke.getDuration() / replaySpeed);
    }
  }

  // =============================================================
  // Transitions
  // =============================================================

  // worth noting: all transitions are handled in grid space, and then transformed in update() before sending to the pen. 
  // this means that transitions may become squeezed or otherwise as transformations change. 
  // perhaps a later version could address this. 
  private void startTransition(PVector from, PVector dest) {
    transitionStroke    = new Stroke(from, dest);
    isPlayingTransition = true;
    currentPointIndex   = 0;
    strokeStartTime     = parent.millis();
  }

  private void startReturnToStart() {
    Doodle d = getCurrentDoodle();
    if (d == null) return;
    PVector dest = d.getStroke(0).getPointAtIndex(0).pos;
    if (dest == null) return;

    PVector lastPointGrid = undoTransformations(lastPoint); // lastPoint stores the post-transformation last point, perhaps a different transformation than the current one.
                                                            // therefore, lastPointGrid stores the grid point that transforms to lastPoint

    if (lastPointGrid.dist(dest) < transitionGapThreshold) {
      print("no need to jump to return to start, already close enough");
      return;
    }

    transitionStroke       = new Stroke(lastPointGrid, dest);
    isPlayingTransition    = true;
    currentPointIndex      = 0;
    strokeStartTime        = parent.millis();
  }

  private PVector updateTransition() {
    if (transitionStroke == null) {
      finishTransition();
      return null;
    }

    float      elapsed = parent.millis() - strokeStartTime;
    TimedPoint tp      = findPointForElapsed(transitionStroke, elapsed);

    if (elapsed >= transitionStroke.getDuration()) {
      finishTransition();
    }

    return tp != null ? tp.pos : null;
  }

  private void finishTransition() {
    isPlayingTransition = false;
    transitionStroke       = null;
    currentStrokeIndex     = transitionTargetIndex;
    currentPointIndex      = 0;
    transitionTargetIndex  = 0;
    strokeStartTime        = parent.millis();
  }

  // =============================================================
  // Time / point helpers
  // =============================================================
  private float computeElapsed() {
    return (parent.millis() - strokeStartTime) * replaySpeed;
  }

  private TimedPoint findPointForElapsed(Stroke stroke, float elapsed) {
    TimedPoint result = null;

    for (int i = currentPointIndex; i < stroke.getCount(); i++) {
      TimedPoint tp = stroke.getPointAtIndex(i);

      if (tp.time <= elapsed) {
        result = tp;
        currentPointIndex = i;
      } else {
        break;
      }
    }

    if (result == null && stroke.getCount() > 0) {
      result = stroke.getPointAtIndex(0);
    }

    return result;
  }

  Doodle getCurrentDoodle() {
    return useNormalized ? doodleNormalized : doodleOriginal;
  }

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

  PVector applyAngle(PVector original) {
    PVector transformed = original.copy();
    transformed.rotate(radians(-angle));
    return transformed;
  }

  PVector applySize(PVector original) {
    PVector transformed = original.copy();
    transformed.mult(size);
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
}

// =============================================================
// Normalization Manager
// =============================================================
class NormalizationManager {

  Doodle getNormalizedDoodle(Doodle d, float targetSpeed, float easingFactor) {
    Doodle normalizedDoodle = new Doodle();
    for (int i = 0; i < d.getStrokeCount(); i++) {
      Stroke newStroke = normalizedDoodle.addDrawingStroke();
      ArrayList<TimedPoint> normalizedPoints =
        normalizeSegment(d.getStroke(i).getAllPoints(), targetSpeed, easingFactor);
      newStroke.setPoints(normalizedPoints);
    }
    return normalizedDoodle;
  }

  ArrayList<TimedPoint> normalizeSegment(ArrayList<TimedPoint> seg, float targetSpeed, float easingFactor) {
    ArrayList<TimedPoint> out = new ArrayList<>();

    float totalLength  = 0;
    float[] segLengths = new float[seg.size() - 1];
    for (int j = 0; j < seg.size() - 1; j++) {
      float l       = PVector.dist(seg.get(j).pos, seg.get(j + 1).pos);
      segLengths[j] = l;
      totalLength  += l;
    }
    if (totalLength == 0) {
      out.add(new TimedPoint(seg.get(0).pos.copy(), seg.get(0).time));
      return out;
    }

    int   newCount     = max(int(totalLength * 4), 2);
    float totalTime    = totalLength / targetSpeed;
    float timePerPoint = totalTime / (newCount - 1);

    for (int k = 0; k < newCount; k++) {
      float alpha         = (float)k / (newCount - 1);
      float easedAlpha    = (1 - cos(PI * alpha)) / 2.0;
      float distanceAlpha = lerp(alpha, easedAlpha, easingFactor);
      float targetDist    = distanceAlpha * totalLength;
      float time          = seg.get(0).time + k * timePerPoint;

      float accum  = 0;
      int   segIdx = 0;
      while (segIdx < segLengths.length && accum + segLengths[segIdx] < targetDist) {
        accum += segLengths[segIdx];
        segIdx++;
      }
      segIdx       = min(segIdx, segLengths.length - 1);
      float remain = targetDist - accum;
      float t      = (segLengths[segIdx] == 0) ? 0 : constrain(remain / segLengths[segIdx], 0, 1);

      PVector p = PVector.lerp(seg.get(segIdx).pos, seg.get(segIdx + 1).pos, t);
      out.add(new TimedPoint(p, time));
    }

    return out;
  }
}