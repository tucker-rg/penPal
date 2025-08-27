// normalization
boolean normalize = true;
float targetSpeed = 0.05; // Adjust this value for desired speed (units per second)
TimedPoint[] originalStroke = new TimedPoint[1000];
TimedPoint[] normalizedStroke = new TimedPoint[1000];
int originalStrokeLength = 0;
int normalizedStrokeLength = 0;

// optional easing (i don't like it so much)
float easingAmount;
float fullEase = 0.5; // the amount of easing when the mode is 1

TimedPoint[] normalizeStroke(TimedPoint[] original, int originalCount, float targetSpeed) {
  if (originalCount <= 1) return original;

  // Calculate total stroke length and segment lengths
  float totalLength = 0;
  float[] segmentLengths = new float[originalCount - 1];
  for (int i = 0; i < originalCount - 1; i++) {
    float segLength = PVector.dist(original[i].pos, original[i + 1].pos);
    segmentLengths[i] = segLength;
    totalLength += segLength;
  }

  // Handle zero-length strokes
  if (totalLength == 0) {
    TimedPoint[] flat = new TimedPoint[1];
    flat[0] = new TimedPoint(original[0].pos.copy(), 0);
    return flat;
  }

  // Determine how many points to generate
  //int newCount = max(int(totalLength * 2), 2);  // at least 2
  int newCount = max(int(totalLength * 4), 2);  // at least 2
  TimedPoint[] normalized = new TimedPoint[newCount];

  float totalTime = totalLength / targetSpeed;
  float timePerPoint = totalTime / (newCount - 1);

  for (int i = 0; i < newCount; i++) {
    float alpha = (float)i / (newCount - 1);
    
    // distance interpolation method
    float linearAlpha = alpha;
    float easedAlpha = (1 - cos(PI * alpha)) / 2.0;
    float distanceAlpha = lerp(linearAlpha, easedAlpha, easingAmount);

    float targetDistance = distanceAlpha * totalLength;
    float time = i * timePerPoint;

    // Locate the segment for this distance
    float accumulatedLength = 0;
    int segmentIndex = 0;
    while (segmentIndex < originalCount - 1 &&
           accumulatedLength + segmentLengths[segmentIndex] < targetDistance) {
      accumulatedLength += segmentLengths[segmentIndex];
      segmentIndex++;
    }

    // Clamp to avoid out-of-bounds
    segmentIndex = min(segmentIndex, originalCount - 2);
    float segLength = segmentLengths[segmentIndex];
    float segmentStart = accumulatedLength;

    // Interpolate position within the segment
    float remainingDistance = targetDistance - segmentStart;
    float t = (segLength == 0) ? 0 : constrain(remainingDistance / segLength, 0, 1);
    PVector pos = PVector.lerp(original[segmentIndex].pos, original[segmentIndex + 1].pos, t);

    normalized[i] = new TimedPoint(pos, time);
  }

  return normalized;
}

void setNormalize() {
  if (utilitySetting != 0 || strokeCount == 0) {
    return;
  }
  if (normalize) { // We want to set the stroke to the normalized stroke
    for (int i = 0; i < normalizedStrokeLength; i++) {
      stroke[i] = normalizedStroke[i];
    }
    strokeCount = normalizedStrokeLength;
  } else {
    for (int i = 0; i < originalStrokeLength; i++) {
      stroke[i] = originalStroke[i];
    }
    strokeCount = originalStrokeLength;
  }
  startReplay();
}

// sets the original and normalized strokes according to the current storke
void setStrokeContents() {
  normalizedStroke = normalizeStroke(stroke, strokeCount, targetSpeed);
  normalizedStrokeLength = normalizedStroke.length;
   
  for (int i = 0; i < strokeCount; i++) {
    originalStroke[i] = stroke[i];
  } 
  originalStrokeLength = strokeCount;
}
