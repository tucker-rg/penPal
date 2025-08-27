// Timed drawing point
class TimedPoint {
  PVector pos;
  float time = 0;
  TimedPoint(PVector p) {
    pos = p;
  }
  TimedPoint(PVector p, float t) {
    pos = p;
    time = t;
  }
}

class Doodle {
  // the points
  ArrayList<TimedPoint> points = new ArrayList<TimedPoint>();
  ArrayList<TimedPoint> normalizedPoints = new ArrayList<TimedPoint>();
  
  // the fixed characteristics of the doodle
  int mode;
  boolean connectLastPoint = false;;
  int waitTime = 0;
  int normalizedWaitTime = 0;
  // PGraphics img;
  float timeOffset = 0; // in ms, increases for all the time that was spent transitioning between paths
  int numStrokes = 0;
  
  // the adjustable characteristics of the doodle
  float replaySpeed = 1.0;
  float size = 1.0;
  int angle = 0;
  boolean normalized = false;

  // creating the doodle
  Doodle() {
    println("doodle constructed!");
  }
  
  // creating the doodle
  Doodle(boolean n) {
    normalized = n;
    println("doodle constructed!");
  }
  
  // managing the points
  void addPoint(TimedPoint p) {
    //float newTime;
    //if (getCount() == 0) {
    //  // First point in the doodle
    //  newTime = p.time;
    //} else {
    //  // Always append after the last point
    //  newTime = getPoint(getCount() - 1).time;
    //}
    float newTime = p.time;
  
    points.add(new TimedPoint(undoTransformations(p.pos), newTime + timeOffset));
    autoSetMode1or2();
    updateNormalizedPoints();
  }

  
  // accelerate quickly, plateau, then crawl into the end
  float easeStrongEnd(float t) {
    float eased = (1 - cos(PI * t)) / 2;  // base smoothstep
    return 1 - pow(1 - eased, 2.0);       // bias toward the end
  }
  
  // classic smoothstep S-curve (symmetrical)
  float easeSymmetrical(float t, float k) {
    // k > 1 = steeper acceleration/deceleration
    // k < 1 = softer (more gradual)
    return pow((1 - cos(PI * t)) / 2, k);
  }



  void addTransition(TimedPoint newPoint) {
    if (getCount() == 0) {
      addPoint(newPoint);
      return; // nothing to connect from
    }
  
    TimedPoint prevPoint = getPoint(getCount() - 1);
  
    // total time for transition
    float transitionTime = (newPoint.pos.dist(prevPoint.pos)) * 15 + 10;
    println("this transition will take: ", transitionTime);
  
    float h = 3;      // parabola apex lift
    int steps = 15;   // transition resolution
  
    for (int i = 1; i <= steps; i++) {
      float t = i / float(steps + 1);   // normalized [0,1]
  
      // apply easing (slows strongly at destination)
      //float easedT = easeStrongEnd(t);
      float easedT = easeSymmetrical(t, 2);
  
      // interpolate position with easedT
      float x = lerp(prevPoint.pos.x, newPoint.pos.x, easedT);
      float y = lerp(prevPoint.pos.y, newPoint.pos.y, easedT);
      float baseZ = lerp(prevPoint.pos.z, newPoint.pos.z, easedT);
  
      // parabola lift (sharper with exponent)
      float sharpness = 3.0; // tweak this
      float raw = pow(t, sharpness) * pow(1 - t, sharpness);
      float maxVal = pow(0.5, sharpness) * pow(0.5, sharpness);
      float lift = (raw / maxVal) * h;
      float z = baseZ - lift;

  
      // linear interpolation of time (not eased, so clock runs steadily)
      float time = prevPoint.time + t * transitionTime;
  
      // add interpolated point
      points.add(new TimedPoint(new PVector(x, y, z), time));
      println("added transition point: ", getPoint(getCount()-1).pos, " at time: ", getPoint(getCount()-1).time);
    }
  
    // finally add the target point *after* the transition
    float finalTime = prevPoint.time + transitionTime;
    points.add(new TimedPoint(newPoint.pos.copy(), finalTime));
  
    // update bookkeeping
    timeOffset = finalTime;
    numStrokes += 1;
  
    println("the time offset is now: ", timeOffset);
  }


  TimedPoint getPoint(int index) {
    if (index < getCount()) {
      if (normalized) {
        return new TimedPoint(applyTransformations(normalizedPoints.get(index).pos), normalizedPoints.get(index).time);
      } 
      return new TimedPoint(applyTransformations(points.get(index).pos), points.get(index).time);
    } else {
      println("i am trying to get the point at index ", index, ", but no such point exists");
      return null;
    }
  }
  
  int getCount() {
    if (normalized) {
      return normalizedPoints.size();
    } 
    return points.size();
  }
  
  ArrayList<TimedPoint> getAllPoints() {
    ArrayList<TimedPoint> transformedPoints = new ArrayList<>();
    for (int i = 0; i < this.getCount(); i++) {
      transformedPoints.add(getPoint(i));
    }
    return transformedPoints;
  }
  
  // managing the fixed characteristics of the doodle
  void setMode(int m) {
    mode = m;
  }
  
  void setConnectLastPoint(boolean c) {
    connectLastPoint = c;
    updateNormalizedPoints();
  }
  
  void setWaitTime(int w) {
    waitTime = w;
    normalizedWaitTime = w / 10; // just because there are so many more points to worry about
  }
  
  int getWaitTime() {
    //return waitTime;
    if (normalized) {
      return normalizedWaitTime;
    } 
    return waitTime;
  }
  
  //void setImg(PGraphics i) {
  //  img = i;
  //}
  
  //PGraphics getImg() {
  //  return img;
  //}
  
  // managing the adjustable aspects of the doodle
  void setReplaySpeed(float r) {
    replaySpeed = r;
    // println("replay speed is now: ", r);
  }
  
  float getReplaySpeed() {
    return replaySpeed;
  }
  
  void setSize(float s) {
    size = s;
    updateNormalizedPoints();
  }
  
  float getSize() {
    return size;
  }
  
  void setAngle(int a) {
    angle = a%360;
  }
  
  int getAngle() {
    return angle;
  }
  
  void setNormalized(boolean setting) {
    if (normalized != setting) {
      println("setting normalized to: ", setting);
      normalized = setting;
      startReplay(); // this is a bit goofy
    }
  }
  
  boolean getNormalized() {
    return normalized;
  }
  
  void updateNormalizedPoints() {
    float easingFactor = 0;
    //if (mode == 1) {
    //  easingFactor = 0.5;
    //}
    normalizedPoints = this.getNormalizedPoints(0.05, easingFactor);
  }
  
  void autoSetMode1or2() {
    // Convert screen coordinates to real coordinates first
    PVector startPos = points.get(0).pos;
    PVector endPos = points.get(points.size() - 1).pos;
    
    if (PVector.dist(startPos, endPos) > 2.0) {
      mode = MODE_REPLAY;
    } else {
      mode = MODE_LOOP;
    }
    // println("I set the mode to: ", mode, " because the distance between ", startPos, " and ", endPos, " is ", PVector.dist(startPos, endPos));
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
  
  PVector undoTransformations(PVector transformed) {
    PVector original = transformed.copy();
    
    // Apply scaling
    original.mult(1 / size);
    
    // Apply rotation
    original.rotate(radians(angle));
    
    return original;
  }
  
  // generates normalized points given an ArrayList of TimedPoints, a target speed, and an easing factor
  ArrayList<TimedPoint> getNormalizedPoints(float targetSpeed, float easingFactor) {
    ArrayList<TimedPoint> normalized = new ArrayList<>();
  
    int i = 0;
    while (i < points.size()) {
      TimedPoint start = points.get(i);
  
      if (abs(start.pos.z) < 1e-3) {
        // --- Pen-down segment: collect until z != 0 or end ---
        ArrayList<TimedPoint> seg = new ArrayList<>();
        while (i < points.size() && abs(points.get(i).pos.z) < 1e-3) {
          seg.add(points.get(i));
          i++;
        }
  
        if (seg.size() > 1) {
          // Normalize this contiguous stroke
          normalized.addAll(normalizeSegment(seg, targetSpeed, easingFactor));
        } else {
          // Degenerate case: single z=0 point, just copy it
          normalized.add(new TimedPoint(seg.get(0).pos.copy(), seg.get(0).time));
        }
      } else {
        // --- Pen-up point: keep untouched ---
        normalized.add(new TimedPoint(start.pos.copy(), start.time));
        i++;
      }
    }
  
    return normalized;
  }
  
  // helper: runs your current normalization logic on a contiguous segment
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

  
  void reset() {
    // println("resetting the doodle");
    // the points
    points.clear();
    normalizedPoints.clear();
    
    // the fixed characteristics of the doodle
    mode = 1;
    connectLastPoint = false;;
    waitTime = 0;
    
    replaySpeed = 1.0;
    size = 1.0;
    angle = 0;
    normalized = false;
  }
  
  Doodle copy() {
    Doodle copy = new Doodle();
  
    // Deep copy points
    for (TimedPoint tp : this.points) {
      copy.points.add(new TimedPoint(tp.pos.copy(), tp.time));
    }
  
    // Deep copy normalizedPoints
    for (TimedPoint tp : this.normalizedPoints) {
      copy.normalizedPoints.add(new TimedPoint(tp.pos.copy(), tp.time));
    }
  
    // Copy all other fields
    copy.mode = this.mode;
    copy.connectLastPoint = this.connectLastPoint;
    copy.waitTime = this.waitTime;
    //copy.img = this.img;
    copy.replaySpeed = this.replaySpeed;
    copy.size = this.size;
    copy.angle = this.angle;
    copy.normalized = this.normalized;
    
    // println("i finished copying the doodle");
    return copy;
  }
}
