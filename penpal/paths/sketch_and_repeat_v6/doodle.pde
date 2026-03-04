// ---------------------------
// Timed drawing point
// ---------------------------
class TimedPoint {
  PVector pos;
  float time = 0;

  TimedPoint(PVector p) {
    pos = p.copy();
  }

  TimedPoint(PVector p, float t) {
    pos = p.copy();
    time = t;
  }
}

// ---------------------------
// Stroke (a single stroke)
// ---------------------------
class Stroke {
  private ArrayList<TimedPoint> points = new ArrayList<TimedPoint>();
  private boolean isTransition;

  // Standard drawing stroke
  Stroke() {
    isTransition = false;
  }

  // Transition stroke
  Stroke(PVector start, PVector end) {
    isTransition = true;
    buildTransition(start, end);
  }

  boolean getIsTransition() {
    return isTransition;
  }

  int getDuration() {
    if (points.isEmpty()) return 0;
    return int(points.get(points.size() - 1).time);
  }

  int getCount() {
    return points.size();
  }

  TimedPoint getPointAtIndex(int i) {
    if (i < 0 || i >= points.size()) return null;
    return points.get(i);
  }

  ArrayList<TimedPoint> getAllPoints() {
    return new ArrayList<TimedPoint>(points);
  }

  PVector getLastPoint() {
    if (points.isEmpty()) return null;
    return points.get(points.size() - 1).pos;
  }

  void addPoint(TimedPoint p) {
    if (p != null) points.add(p);
  }

  void setPoints(ArrayList<TimedPoint> p) {
    if (p != null) points = new ArrayList<TimedPoint>(p);
  }

  // Build a transition stroke with smooth interpolation
  void buildTransition(PVector start, PVector end) {
    float transitionTime = start.dist(end) * 15 + 10;
    println("This transition will take: ", transitionTime);

    float h = 3;      // parabola apex lift
    int steps = 15;   // transition resolution

    for (int i = 1; i <= steps; i++) {
      float t = i / float(steps + 1);   // normalized [0,1]
      float easedT = easeSymmetrical(t, 2); // S-curve easing

      float x = lerp(start.x, end.x, easedT);
      float y = lerp(start.y, end.y, easedT);
      float baseZ = lerp(start.z, end.z, easedT);

      // Parabola lift
      float sharpness = 3.0;
      float raw = pow(t, sharpness) * pow(1 - t, sharpness);
      float maxVal = pow(0.5, sharpness) * pow(0.5, sharpness);
      float lift = (raw / maxVal) * h;
      float z = baseZ - lift;

      float time = t * transitionTime;

      points.add(new TimedPoint(new PVector(x, y, z), time));
    }

    // Add final target point
    points.add(new TimedPoint(end.copy(), transitionTime));
  }

  float easeSymmetrical(float t, float k) {
    return pow((1 - cos(PI * t)) / 2, k);
  }

  Stroke copy() {
    Stroke copy = new Stroke();
    copy.isTransition = this.isTransition;

    for (TimedPoint tp : this.points) {
      copy.points.add(new TimedPoint(tp.pos.copy(), tp.time));
    }

    return copy;
  }
}

// ---------------------------
// Doodle (collection of strokes)
// ---------------------------
class Doodle {
  private ArrayList<Stroke> strokes = new ArrayList<Stroke>();

  Doodle() {
    println("Doodle constructed!");
  }

  // Add a standard drawing stroke
  Stroke addDrawingStroke() {
    Stroke newStroke = new Stroke();
    strokes.add(newStroke);
    return newStroke;
  }

  // Add a transition stroke connecting to last stroke
  void addTransitionStroke(PVector newPoint) {
    if (strokes.isEmpty()) return;
    Stroke latestStroke = strokes.get(strokes.size() - 1);
    PVector prevPoint = latestStroke.getLastPoint();
    if (prevPoint == null) return;

    Stroke newStroke = new Stroke(prevPoint, newPoint);
    strokes.add(newStroke);
  }

  void addStroke(Stroke s) {
    if (s != null) strokes.add(s);
  }

  // Add point to the latest stroke
  void addPoint(TimedPoint p) {
    if (strokes.isEmpty() || p == null) return;
    strokes.get(strokes.size() - 1).addPoint(p);
  }

  int getCount() {
    int count = 0;
    for (Stroke s : strokes) {
      count += s.getCount();
    }
    return count;
  }

  int getStrokeCount() {
    return strokes.size();
  }

  Stroke getStroke(int index) {
    if (index < 0 || index >= strokes.size()) return null;
    return strokes.get(index);
  }

  TimedPoint getPoint(int index) {
    int running = 0;
    for (Stroke s : strokes) {
      int strokeSize = s.getCount();
      if (index < running + strokeSize) {
        return s.getPointAtIndex(index - running);
      }
      running += strokeSize;
    }
    return null;
  }

  Doodle copy() {
    Doodle copy = new Doodle();
    for (Stroke s : this.strokes) {
      copy.strokes.add(s.copy());
    }
    return copy;
  }
}
