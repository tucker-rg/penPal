static class NormalizationManager {
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
}
