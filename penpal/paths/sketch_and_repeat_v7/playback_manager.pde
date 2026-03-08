// -------------------
// Top-level enums
// -------------------
enum PlaybackMode {
  PINGPONG, // NOT IMPLEMENTED
  LOOP
}

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
  private PVector lastPoint           = new PVector(0, 0);

  // -- PingPong state --
  private boolean isReversing         = false;

  // -- Transition state --
  private Stroke  transitionStroke       = null;
  private boolean isPlayingTransition    = false;
  private int     transitionFinishAction = 0;
  private int     transitionTargetIndex  = 0;

  final int TRANSITION_RESET   = 1;
  final int TRANSITION_ADVANCE = 2;

  // -- Settings --
  private float     replaySpeed            = 1.0;
  private float     normalizedTargetSpeed  = 0.05;
  private int       angle                  = 0;
  PlaybackMode      mode                   = PlaybackMode.LOOP;
  private boolean   usePingPong            = false; // not implemented
  boolean           useNormalized          = true;
  private float     easingFactor           = 0.05;
  private float     transitionGapThreshold = 0.5;

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
    setDoodle(d);
    state = PlaybackState.PLAYING;
    resetAndReturn();
  }

  void pause() {
    if (state == PlaybackState.PLAYING) {
      state          = PlaybackState.PAUSED;
      pauseStartTime = parent.millis();
    }
  }

  void resume() {
    if (getCurrentDoodle() == null) return;
    if (state == PlaybackState.PAUSED) {
      if (currentPointIndex == 0 && currentStrokeIndex == 0) {
        strokeStartTime = parent.millis();
      } else {
        strokeStartTime += (parent.millis() - pauseStartTime);
      }
      state = PlaybackState.PLAYING;
    }
  }

  void togglePauseResume() {
    if (state == PlaybackState.PLAYING) pause();
    else resume();
  }

  void makeIdle() {
    state = PlaybackState.IDLE;
  }

  void setDoodle(Doodle d) {
    if (d == null) return;
    doodleOriginal   = d;
    doodleNormalized = normalizer.getNormalizedDoodle(d, normalizedTargetSpeed, easingFactor);
    mode = usePingPong ? PlaybackMode.PINGPONG : PlaybackMode.LOOP;
  }

  void setMode(PlaybackMode m) {
    mode = m;
    reset();
  }

  void setReplaySpeed(float speed) {
    float oldSpeed      = replaySpeed;
    replaySpeed         = max(0.01, speed);
    float rawElapsed    = parent.millis() - strokeStartTime;
    float scaledElapsed = rawElapsed * oldSpeed;
    strokeStartTime     = (long)(parent.millis() - scaledElapsed / replaySpeed);
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
    isReversing            = false;
    isPlayingTransition    = false;
    transitionStroke       = null;
    transitionFinishAction = 0;
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

  float getReplaySpeed() {
    return replaySpeed;
  }

  // =============================================================
  // Main update — call every frame
  // =============================================================
  PVector update() {
    if (state != PlaybackState.PLAYING) return lastPoint;
    if (isPlayingTransition) {
      PVector pt = updateTransition();
      if (pt != null) lastPoint = pt;
      return lastPoint;
    }

    Doodle doodle = getCurrentDoodle();
    if (doodle == null || doodle.getStrokeCount() == 0) return null;

    // loop so that advancing a stroke immediately scans the next one
    int safetyLimit = doodle.getStrokeCount() + 1;
    while (safetyLimit-- > 0) {
      Stroke stroke = doodle.getStroke(currentStrokeIndex);
      if (stroke == null || stroke.getCount() == 0) {
        advanceStroke(doodle);
        if (isPlayingTransition) return lastPoint; // transition just started
        continue;
      }

      float      elapsed = computeElapsed();
      TimedPoint tp      = isReversing
                            ? findPointForElapsedReverse(stroke, elapsed)
                            : findPointForElapsed(stroke, elapsed);
      if (tp != null) lastPoint = tp.pos;

      if (elapsed >= stroke.getDuration()) {
        advanceStroke(doodle);
        if (isPlayingTransition) return lastPoint; // transition just started
        continue; // immediately scan the new stroke
      }

      return lastPoint;
    }

    return lastPoint;
  }

  // =============================================================
  // Stroke advancement
  // =============================================================
  private void advanceStroke(Doodle doodle) {
    if (isReversing) advanceStrokeReverse(doodle);
    else             advanceStrokeForward(doodle);
  }

  private void advanceStrokeForward(Doodle doodle) {
    int nextIndex = currentStrokeIndex + 1;

    if (nextIndex >= doodle.getStrokeCount()) {
      handlePlaybackEnd(doodle);
      return;
    }

    Stroke currentStroke = doodle.getStroke(currentStrokeIndex);
    PVector endPos   = currentStroke.getLastPoint();
    PVector startPos = doodle.getStroke(nextIndex).getFirstPoint();

    if (PVector.dist(endPos, startPos) > transitionGapThreshold) {
      transitionTargetIndex  = nextIndex;
      transitionFinishAction = TRANSITION_ADVANCE;
      startTransition(endPos, startPos);
    } else {
      currentStrokeIndex = nextIndex;
      currentPointIndex  = 0;
      strokeStartTime    = strokeStartTime + (long)(currentStroke.getDuration() / replaySpeed);
    }
  }

  private void advanceStrokeReverse(Doodle doodle) {
    int nextIndex = currentStrokeIndex - 1;

    if (nextIndex < 0) {
      isReversing        = false;
      currentStrokeIndex = 0;
      currentPointIndex  = 0;
      strokeStartTime    = parent.millis();
      return;
    }

    Stroke currentStroke = doodle.getStroke(currentStrokeIndex);
    PVector endPos   = currentStroke.getFirstPoint(); // reverse: we're at the start of this stroke
    PVector startPos = doodle.getStroke(nextIndex).getLastPoint(); // heading to the end of the previous

    if (PVector.dist(endPos, startPos) > transitionGapThreshold) {
      transitionTargetIndex  = nextIndex;
      transitionFinishAction = TRANSITION_ADVANCE;
      startTransition(endPos, startPos);
    } else {
      currentStrokeIndex = nextIndex;
      currentPointIndex  = doodle.getStroke(nextIndex).getCount() - 1;
      strokeStartTime    = strokeStartTime + (long)(currentStroke.getDuration() / replaySpeed);
    }
  }

  // =============================================================
  // End-of-doodle handling
  // =============================================================
  private void handlePlaybackEnd(Doodle doodle) {
    if (mode == PlaybackMode.PINGPONG) {
      isReversing        = true;
      currentStrokeIndex = doodle.getStrokeCount() - 1;
      currentPointIndex  = doodle.getStroke(currentStrokeIndex).getCount() - 1;
      strokeStartTime    = parent.millis();
    } else {
      resetAndReturn();
    }
  }

  // =============================================================
  // Transitions
  // =============================================================
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
    if (lastPoint.dist(dest) < transitionGapThreshold) {
      print("no need to jump to return to start, already close enough");
      return;
    }

    transitionStroke       = new Stroke(lastPoint, dest);
    isPlayingTransition    = true;
    transitionFinishAction = TRANSITION_RESET;
    currentPointIndex      = 0;
    strokeStartTime        = parent.millis();
  }

  private PVector updateTransition() {
    if (transitionStroke == null) {
      finishTransition();
      return null;
    }

    float      elapsed = parent.millis() - strokeStartTime;
    TimedPoint tp      = findPointForElapsedInStroke(transitionStroke, elapsed);

    if (elapsed >= transitionStroke.getDuration()) {
      finishTransition();
    }

    return tp != null ? tp.pos : null;
  }

  private void finishTransition() {
    isPlayingTransition = false;

    if (transitionFinishAction == TRANSITION_ADVANCE) {
      long transitionDuration = (long)transitionStroke.getDuration();
      transitionStroke       = null;
      currentStrokeIndex     = transitionTargetIndex;
      currentPointIndex      = 0;
      transitionFinishAction = 0;
      transitionTargetIndex  = 0;
      strokeStartTime        = strokeStartTime + transitionDuration;
    } else if (transitionFinishAction == TRANSITION_RESET) {
      transitionStroke       = null;
      transitionFinishAction = 0;
      reset();
    }
  }

  // =============================================================
  // Time / point helpers
  // =============================================================
  private float computeElapsed() {
    return (parent.millis() - strokeStartTime) * replaySpeed;
  }

  private TimedPoint findPointForElapsed(Stroke stroke, float elapsed) {
    return findPointForElapsedInStroke(stroke, elapsed);
  }

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

  private TimedPoint findPointForElapsedReverse(Stroke stroke, float elapsed) {
    float      duration = stroke.getDuration();
    TimedPoint result   = null;

    for (int i = currentPointIndex; i >= 0; i--) {
      TimedPoint tp = stroke.getPointAtIndex(i);
      if (tp == null) continue;
      float reversedTime = duration - tp.time;
      if (reversedTime <= elapsed) {
        result            = tp;
        currentPointIndex = i;
      } else {
        break;
      }
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
    // transformed.mult(size);
    
    // Apply rotation
    //println("orientation: ", angle);
    transformed.rotate(radians(-angle));
    
    return transformed;
  }
  
  PVector undoTransformations(PVector transformed) {
    PVector original = transformed.copy();
    
    // Apply scaling
    // original.mult(1 / size);
    
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