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
    points.add(new TimedPoint(undoTransformations(p.pos), p.time));
    autoSetMode1or2();
    
    // update the normalized points array as well, keeping in mind the optional easing factor
    updateNormalizedPoints();
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
    ArrayList<TimedPoint> pointsForNormalizing = new ArrayList<>(points);
    if (connectLastPoint) {
      pointsForNormalizing.add(new TimedPoint(points.get(0).pos.copy()));
    }
    
    if (pointsForNormalizing.size() <= 1) {
      ArrayList<TimedPoint> out = new ArrayList<TimedPoint>();
      if (pointsForNormalizing.size() == 1) {
        TimedPoint tp = points.get(0);
        out.add(new TimedPoint(tp.pos.copy(), tp.time));
      }
      return out;
    }
  
    // Calculate total stroke length and segment lengths
    float totalLength = 0;
    float[] segmentLengths = new float[pointsForNormalizing.size() - 1];
    for (int i = 0; i < pointsForNormalizing.size() - 1; i++) {
      float segLength = PVector.dist(pointsForNormalizing.get(i).pos, pointsForNormalizing.get(i + 1).pos);
      segmentLengths[i] = segLength;
      totalLength += segLength;
    }
  
    // Handle zero-length strokes
    if (totalLength == 0) {
      ArrayList<TimedPoint> flat = new ArrayList<TimedPoint>();
      flat.add(new TimedPoint(pointsForNormalizing.get(0).pos.copy(), 0));
      return flat;
    }
  
    // Determine how many points to generate
    //int newCount = max(int(totalLength * 2), 2);  // at least 2
    int newCount = max(int(totalLength * 4), 2);  // at least 2
    ArrayList<TimedPoint> normalized = new ArrayList<>();
  
    float totalTime = totalLength / targetSpeed;
    float timePerPoint = totalTime / (newCount - 1);
  
    for (int i = 0; i < newCount; i++) {
      float alpha = (float)i / (newCount - 1);
      
      // distance interpolation method
      float linearAlpha = alpha;
      float easedAlpha = (1 - cos(PI * alpha)) / 2.0;
      float distanceAlpha = lerp(linearAlpha, easedAlpha, easingFactor);
  
      float targetDistance = distanceAlpha * totalLength;
      float time = i * timePerPoint;
  
      // Locate the segment for this distance
      float accumulatedLength = 0;
      int segmentIndex = 0;
      while (segmentIndex < pointsForNormalizing.size() - 1 &&
             accumulatedLength + segmentLengths[segmentIndex] < targetDistance) {
        accumulatedLength += segmentLengths[segmentIndex];
        segmentIndex++;
      }
  
      // Clamp to avoid out-of-bounds
      segmentIndex = min(segmentIndex, pointsForNormalizing.size() - 2);
      float segLength = segmentLengths[segmentIndex];
      float segmentStart = accumulatedLength;
  
      // Interpolate position within the segment
      float remainingDistance = targetDistance - segmentStart;
      float t = (segLength == 0) ? 0 : constrain(remainingDistance / segLength, 0, 1);
      PVector pos = PVector.lerp(pointsForNormalizing.get(segmentIndex).pos, pointsForNormalizing.get(segmentIndex + 1).pos, t);
  
      normalized.add(new TimedPoint(pos, time));
    }
  
    return normalized;
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
