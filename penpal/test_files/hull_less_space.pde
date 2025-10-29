// Triangular Torus Slice - FIXED FOR RADIAL SYMMETRY
// - Defines a triangle (3 vertices) with perfect 120° symmetry around Z-axis
// - Defines an axis (two points) that lies in the XY plane (z = 0).
// - Rotates (sweeps) the triangle around the axis by angle `theta` (radians).
// - Builds a mesh by sampling `steps` intermediate rotations and connects corresponding vertices.
// - Controls: e (toggle edit mode), +/- angle, [ ] steps, c caps, w wireframe, r reset.
// - In Edit mode you can drag triangle vertices and axis endpoints in top-down view.

import processing.serial.*;
import java.util.*;

Serial myPort;

// all units in mm
float s = 10;
float R = s / sqrt(3);        // distance from center to each vertex
float r = s / (2*sqrt(3));    // distance from center to each side (inradius)

// FIXED: Triangle vertices with perfect 120° rotational symmetry
PVector[] tri = new PVector[3];

float tipLength = 13.7;
float spoolDiameter = 14.0; // in mm

PVector axisP1, axisP2; // axis endpoints (both z = 0)
float theta;        // sweep angle in radians (default 180°)
int steps = 72;          // subdivisions along sweep (higher => smoother)

PVector lastAxisPoint = null;
PVector lastAxisDir = null;
float lastTheta = 0;
boolean lastSolutionOK = false;
PVector lastTarget = null;
boolean offlineMode = false;

MotorCommand penControl = new MotorCommand();

// For viewer
float sceneRotX = -0.5, sceneRotY = 0.8; // initial 3D view rotation
float zoomFactor = 1.0;

ArrayList<PVector> reachablePoints = new ArrayList<PVector>();
int selectedPoint = -1;

void setup() {
  size(1000, 700, P3D);
  
  // FIXED: Initialize triangle with perfect 120° symmetry
  initializeSymmetricTriangle();
  
  findReachablePoints();
  // smooth(8);
  // textFont(createFont("SansSerif", 12));
  
  if (!offlineMode) {
    println("setting up serial");
    // Serial setup
    printArray(Serial.list());
    String portName = Serial.list()[3];  // Adjust index as needed
    myPort = new Serial(this, portName, 115200); //57600
    myPort.bufferUntil('\n');  // trigger serialEvent on newline
  }
  
  selectedPoint = 0;
  drawTendons(reachablePoints.get(selectedPoint));
  selectedPoint = -1;
}

// FIXED: Initialize triangle vertices with perfect 120° rotational symmetry
void initializeSymmetricTriangle() {
  // Place vertices at 0°, 120°, 240° for perfect radial symmetry
  // Starting at +X axis (0°) for conventional delta robot orientation
  for (int i = 0; i < 3; i++) {
    float angle = i * TWO_PI / 3.0; // 0°, 120°, 240°
    tri[i] = new PVector(
      R * cos(angle),
      R * sin(angle),
      0
    );
  }
  
  println("Symmetric triangle vertices:");
  for (int i = 0; i < 3; i++) {
    println("  tri[" + i + "] = (" + nf(tri[i].x, 1, 2) + ", " + nf(tri[i].y, 1, 2) + ", " + nf(tri[i].z, 1, 2) + ")");
  }
}

void draw() {
  background(200);
  draw3DView();
  drawDimensions();
  // drawHUD();
}

void findReachablePoints() {
  // Clear previous points
  reachablePoints.clear();
  
  println("Finding reachable points...");
  int totalPoints = 0;
  int reachableCount = 0;
  
  // FIXED: Use symmetric sampling pattern
  for (float z = 10; z < 70; z += 5) {
    for (float x = -50; x <= 50; x += 5) {
      for (float y = -50; y <= 50; y += 5) {
        totalPoints++;
        PVector point = new PVector(x, y, z);
        if (isReachable(point)) {
          reachablePoints.add(point);
          reachableCount++;
          if (reachableCount % 50 == 0) {
            println("Found " + reachableCount + " reachable points so far...");
          }
        }
      }
    }
  }
  
  println("Total points tested: " + totalPoints);
  println("Total reachable points: " + reachableCount);
  println("Workspace analysis complete.");
}

boolean isReachable(PVector point) {
  float[] tendonLengths = getTendonLengths(point);
  if (tendonLengths == null) return false;
  
  float[] motorPositions = getMotorPositions(tendonLengths);
  return (motorPositions != null);
}

// FIXED: Improved motor position calculation with better validation
float[] getMotorPositions(float[] tendonLengths) {
  if (tendonLengths == null) return null;
  
  float[] motorPositions = new float[3];
  for (int i = 0; i < 3; i++) {
    motorPositions[i] = arcLengthToMotorPosition(tendonLengths[i]);
    
    // Check if motor position is within valid range
    if (motorPositions[i] < 10 || motorPositions[i] > 310) {
      return null;
    }
  }
  
  return motorPositions;
}
  
float arcLengthToMotorPosition(float arcLength) {
  return arcLength * 360 / (PI * spoolDiameter) - 10;
}

void draw3DView() {
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomFactor);
  rotateX(sceneRotX);
  rotateY(sceneRotY);

  lights();
  ambientLight(60, 60, 60);
  directionalLight(200, 200, 200, -0.5, -0.8, -0.3);

  // --- draw triangle ---
  stroke(255, 220);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int j = 0; j < 3; j++) vertex(tri[j].x, tri[j].y, tri[j].z);
  endShape(CLOSE);

  // FIXED: Draw triangle vertices with different colors to show orientation
  noStroke();
  for (int j = 0; j < 3; j++) {
    pushMatrix();
    translate(tri[j].x, tri[j].y, tri[j].z);
    
    // Different colors for each vertex to verify symmetry
    if (j == 0) fill(255, 100, 100); // Red for 0° vertex
    else if (j == 1) fill(100, 255, 100); // Green for 120° vertex  
    else fill(100, 100, 255); // Blue for 240° vertex
    
    sphereDetail(8);
    sphere(1.5);
    popMatrix();
  }
  
  // Draw coordinate axes for reference
  drawCoordinateAxes();
  
  // inside draw3DView()
  if (selectedPoint == -1) {
    // draw all red dots
    fill(255,0,0);
    for (PVector p : reachablePoints) {
      pushMatrix();
      translate(p.x, p.y, p.z);
      sphere(0.3);
      popMatrix();
    }
    drawHull();
  } else {
    // first, we draw the other ones anyways
    fill(200, 150);
    for (PVector p : reachablePoints) {
      pushMatrix();
      translate(p.x, p.y, p.z);
      sphere(0.2);
      popMatrix();
    }
    
    // now, draw the selected one in red (and bigger)
    PVector p = reachablePoints.get(selectedPoint);
    fill(255,0,0);
    pushMatrix();
    translate(p.x, p.y, p.z);
    sphere(1);
    popMatrix();
    
    drawTendons(p);
  }

  popMatrix();
}

// FIXED: Add coordinate axes for reference
void drawCoordinateAxes() {
  strokeWeight(1);
  
  // X axis - Red
  stroke(255, 0, 0);
  line(0, 0, 0, 20, 0, 0);
  
  // Y axis - Green  
  stroke(0, 255, 0);
  line(0, 0, 0, 0, 20, 0);
  
  // Z axis - Blue
  stroke(0, 0, 255);
  line(0, 0, 0, 0, 0, 20);
}

void drawTendons(PVector point) {
  findAxisAndThetaForTipEnd(point);

  // Prepare sweep grid: (steps+1) x 3 vertices
  if (steps < 1) steps = 1;
  PVector axisDir = PVector.sub(axisP2, axisP1);
  if (axisDir.mag() == 0) axisDir = new PVector(1, 0, 0);
  axisDir.normalize();

  PVector[][] sweep = new PVector[steps+1][3];
  for (int i = 0; i <= steps; i++) {
    float a = (float)i / steps * theta;
    for (int j = 0; j < 3; j++) {
      sweep[i][j] = rotateAroundAxis(tri[j], axisP1, axisDir, a);
    }
  }

  // Fill material
  colorMode(HSB, 360, 100, 100);
  float hueBase = 210; // bluish
  // draw faces (connect corresponding triangle vertices between consecutive sweep rings)
  for (int i = 0; i < steps; i++) {
    for (int j = 0; j < 3; j++) {
      int jNext = (j + 1) % 3;

      PVector v0 = sweep[i][j];
      PVector v1 = sweep[i][jNext];
      PVector v2 = sweep[i+1][jNext];
      PVector v3 = sweep[i+1][j];

      // First triangle (v0, v1, v2)
      PVector n1 = faceNormal(v0, v1, v2);
      pushStyle();
      ambient((int)map(i, 0, steps, 50, 120)); // slight shading by angle
      fill((hueBase + j*30 + map(i,0,steps,0,40)) % 360, 60, 90);
      beginShape(TRIANGLES);
      normal(n1.x, n1.y, n1.z);
      vertex(v0.x, v0.y, v0.z);
      vertex(v1.x, v1.y, v1.z);
      vertex(v2.x, v2.y, v2.z);
      endShape();

      // Second triangle (v0, v2, v3)
      PVector n2 = faceNormal(v0, v2, v3);
      beginShape(TRIANGLES);
      normal(n2.x, n2.y, n2.z);
      vertex(v0.x, v0.y, v0.z);
      vertex(v2.x, v2.y, v2.z);
      vertex(v3.x, v3.y, v3.z);
      endShape();
      popStyle();
    }
  }

  // Caps
  // start cap (i = 0)
  PVector a = sweep[0][0], b = sweep[0][1], c = sweep[0][2];
  PVector nStart = faceNormal(a, b, c);
  pushStyle();
  fill((hueBase+180)%360, 40, 92);
  beginShape(TRIANGLES);
  normal(nStart.x, nStart.y, nStart.z);
  vertex(a.x, a.y, a.z);
  vertex(b.x, b.y, b.z);
  vertex(c.x, c.y, c.z);
  endShape();
  popStyle();

  // end cap (i = steps) - orient normal reversed so it faces outward consistently
  PVector d = sweep[steps][0], e = sweep[steps][1], f = sweep[steps][2];
  PVector nEnd = faceNormal(d, f, e); // reverse winding
  pushStyle();
  fill((hueBase+200)%360, 48, 85);
  beginShape(TRIANGLES);
  normal(nEnd.x, nEnd.y, nEnd.z);
  vertex(d.x, d.y, d.z);
  vertex(f.x, f.y, f.z);
  vertex(e.x, e.y, e.z);
  endShape();
  popStyle();
  
  // --- Draw tip line from final cap center ---
  if (steps > 0) {
    // get final cap triangle vertices
    PVector aCap = sweep[steps][0];
    PVector bCap = sweep[steps][1];
    PVector cCap = sweep[steps][2];

    // centroid of cap
    PVector capCentroid = new PVector(
      (aCap.x + bCap.x + cCap.x)/3.0,
      (aCap.y + bCap.y + cCap.y)/3.0,
      (aCap.z + bCap.z + cCap.z)/3.0
    );

    // cap normal (outward-facing)
    PVector nCap = faceNormal(aCap, bCap, cCap);
    nCap.normalize();

    // tip endpoint
    PVector tipEnd = PVector.add(capCentroid, PVector.mult(nCap, tipLength));

    // draw line
    stroke(255, 0, 0);
    strokeWeight(2);
    line(capCentroid.x, capCentroid.y, capCentroid.z,
         tipEnd.x, tipEnd.y, tipEnd.z);

    // small sphere at tip end
    noStroke();
    fill(255, 0, 0);
    pushMatrix();
    translate(tipEnd.x, tipEnd.y, tipEnd.z);
    sphereDetail(6);
    sphere(0.5);
    popMatrix();
  }
}

void drawHull() {
  if (reachablePoints.isEmpty()) return;
  
  // Simple hull approximation: draw translucent spheres around boundary points
  // This gives a visual sense of the workspace boundary without complex 3D hull computation
  
  fill(100, 150, 255, 30); // Light blue, very translucent
  noStroke();
  
  // Find boundary points (points that are near the edge of the workspace)
  ArrayList<PVector> boundaryPoints = new ArrayList<PVector>();
  
  for (PVector p : reachablePoints) {
    boolean isBoundary = false;
    
    // Check if this point is near the boundary by seeing if nearby points are unreachable
    for (float dx = -10; dx <= 10; dx += 10) {
      for (float dy = -10; dy <= 10; dy += 10) {
        for (float dz = -10; dz <= 10; dz += 10) {
          if (dx == 0 && dy == 0 && dz == 0) continue;
          
          PVector testPoint = new PVector(p.x + dx, p.y + dy, p.z + dz);
          if (!isReachable(testPoint)) {
            isBoundary = true;
            break;
          }
        }
        if (isBoundary) break;
      }
      if (isBoundary) break;
    }
    
    if (isBoundary) {
      boundaryPoints.add(p);
    }
  }
  
  // Draw boundary points as slightly larger spheres
  for (PVector p : boundaryPoints) {
    pushMatrix();
    translate(p.x, p.y, p.z);
    sphere(2); // Slightly larger than regular points
    popMatrix();
  }
}

void drawDimensions() {
  // compute bounds
  float minX = Float.MAX_VALUE, minY = Float.MAX_VALUE, minZ = Float.MAX_VALUE;
  float maxX = -Float.MAX_VALUE, maxY = -Float.MAX_VALUE, maxZ = -Float.MAX_VALUE;
  
  for (int j = 0; j < 3; j++) {
    minX = min(minX, tri[j].x); maxX = max(maxX, tri[j].x);
    minY = min(minY, tri[j].y); maxY = max(maxY, tri[j].y);
    minZ = min(minZ, tri[j].z); maxZ = max(maxZ, tri[j].z);
  }
  for (PVector p : reachablePoints) {
    minX = min(minX, p.x); maxX = max(maxX, p.x);
    minY = min(minY, p.y); maxY = max(maxY, p.y);
    minZ = min(minZ, p.z); maxZ = max(maxZ, p.z);
  }

  hint(DISABLE_DEPTH_TEST);  // overlay on top
  stroke(0);
  fill(0);
  textAlign(CENTER, CENTER);
  
  // X dimension
  drawDimLine(new PVector(minX, minY, minZ), new PVector(maxX, minY, minZ),
              nf(maxX - minX, 1, 1) + " mm");
  // Y dimension
  drawDimLine(new PVector(minX, minY, minZ), new PVector(minX, maxY, minZ),
              nf(maxY - minY, 1, 1) + " mm");
  // Z dimension
  drawDimLine(new PVector(minX, minY, minZ), new PVector(minX, minY, maxZ),
              nf(maxZ - minZ, 1, 1) + " mm");
  
  hint(ENABLE_DEPTH_TEST);
}

void drawDimLine(PVector p1, PVector p2, String label) {
  float x1 = screenX(p1.x, p1.y, p1.z);
  float y1 = screenY(p1.x, p1.y, p1.z);
  float x2 = screenX(p2.x, p2.y, p2.z);
  float y2 = screenY(p2.x, p2.y, p2.z);
  
  line(x1, y1, x2, y2);
  text(label, (x1 + x2) * 0.5, (y1 + y2) * 0.5 - 10); // offset label a bit
}

// FIXED: Improved tendon length calculation with better error handling
float[] getTendonLengths(PVector pos) {
  // --- find arc lengths of swept edges ---
  boolean foundLengths = findAxisAndThetaForTipEnd(pos); // first we send the pen to the position
  
  float[] arcLens = new float[3];
  
  if (foundLengths && abs(theta) < PI / 2) { // we can use the axis and theta stuff (we enforce a 90 degree limit)
    for (int i = 0; i < 3; i++) {
      float r = distancePointLine(tri[i], axisP1, axisP2);
      arcLens[i] = r * abs(theta);
      
      // Sanity check: arc lengths should be positive and reasonable
      if (arcLens[i] < 0 || arcLens[i] > 200) { // 200mm seems like a reasonable max
        return null;
      }
    }
  } else if (pos.x == 0 && pos.y == 0 && pos.z > tipLength) { 
    // if the desired point is directly ahead (on Z-axis)
    for (int i = 0; i < 3; i++) {
      arcLens[i] = pos.z - tipLength;
    }
  } else {
    return null; // No valid solution found
  }
  
  return arcLens;
}

// small helper to print float with limited decimals
float degrees(float rad, int decimals) {
  float d = degrees(rad);
  float p = pow(10, decimals);
  return round(d * p) / p;
}

// --- main solver ---
// Returns true if a solution was found (axis in z=0 plane and theta), false otherwise.
// Prints axis point, unit direction, theta, and verification error.
// target: PVector (can be arbitrary 3D)

boolean findAxisAndThetaForTipEnd(PVector target) {
  return findAxisAndThetaForTipEnd(target, true);
}

boolean findAxisAndThetaForTipEnd(PVector target, boolean tryFlipNormal) {
  final float EPS = 1e-8f;
  PVector C = centroidOfTriangle();                 // centroid of triangle
  PVector n0 = faceNormal(tri[0], tri[1], tri[2]);  // initial cap normal (unit)
  n0.normalize();

  lastTarget = target.copy();

  // Build initial tip endpoint S (before any rotation)
  PVector S = PVector.add(C, PVector.mult(n0, tipLength));

  // Try solving; if no solution and tryFlipNormal==true, try -n0
  boolean ok = solvePointRotation(S, target, n0);
  if (!ok && tryFlipNormal) {
    // try flipping the initial normal (user might have wanted the other face side)
    PVector nFlip = PVector.mult(n0, -1);
    PVector Sflip = PVector.add(C, PVector.mult(nFlip, tipLength));
    ok = solvePointRotation(Sflip, target, nFlip);
  }
  
  return ok;
}

// --- low-level solver that maps point S -> target by rotation about some axis with direction u in z=0 ---
// The function chooses u perpendicular to the XY projection of (target - S) (the necessary condition),
// then solves two linear equations for axis point A = (Ax,Ay,0), then computes theta.
// Returns true if verification distance < tolerance.
boolean solvePointRotation(PVector S, PVector target, PVector usedNormal /* for reporting only */) {
  final float EPS = 1e-9f;
  PVector d = PVector.sub(target, S);
  float dx = d.x, dy = d.y, dz = d.z;

  // Degenerate: same XY projection but different Z -> impossible for axis constrained to z=0
  if (abs(dx) < EPS && abs(dy) < EPS) {
    if (abs(dz) < EPS) {
      // trivial: S == target
      lastAxisDir = new PVector(1, 0, 0);
      lastAxisPoint = new PVector((S.x + target.x)/2f, (S.y + target.y)/2f, 0);
      lastTheta = 0;
      lastSolutionOK = true;
      lastTarget = target.copy();
      return true;
    } else {
      lastSolutionOK = false;
      return false;
    }
  }

  // Choose axis direction u in XY plane perpendicular to (target - S) projection
  PVector u = new PVector(-dy, dx, 0);
  if (u.mag() < EPS) {
    lastSolutionOK = false;
    return false;
  }
  u.normalize();

  // canonicalize direction so results are stable (optional)
  if (u.x < -EPS || (abs(u.x) < EPS && u.y < 0)) u.mult(-1);

  // Two linear equations for Ax,Ay:
  // (1) u_x * Ax + u_y * Ay = u · S    (we pick axis point A so that (S-A) has zero component along u)
  // (2) d_x * Ax + d_y * Ay = (|target|^2 - |S|^2) / 2   (derived from |target - A|^2 = |S - A|^2)
  float e = u.dot(S);
  float rhs = (target.x*target.x + target.y*target.y + target.z*target.z
             - (S.x*S.x + S.y*S.y + S.z*S.z)) * 0.5f;

  float det = u.x * d.y - u.y * d.x;
  if (abs(det) < 1e-10f) {
    lastSolutionOK = false;
    return false;
  }

  float Ax = ( e * d.y - u.y * rhs ) / det;
  float Ay = ( u.x * rhs - e * d.x ) / det;
  PVector A = new PVector(Ax, Ay, 0);

  // vectors relative to A
  PVector v = PVector.sub(S, A);
  PVector w = PVector.sub(target, A);

  // compute signed angle theta (using axis direction u for sign via triple product)
  PVector crossVW = cross(v, w);
  float numer = u.dot(crossVW);
  float denom = v.dot(w);
  float thetaFound = atan2(numer, denom);

  // Verify by rotating S around axis (A,u,thetaFound)
  PVector Srot = rotateAroundAxis(S, A, u, thetaFound);
  float err = PVector.dist(Srot, target);

  // store results globally for drawing/inspection
  lastAxisPoint = A.copy();
  lastAxisDir = u.copy();
  lastTheta = thetaFound;
  lastSolutionOK = (err < 1e-4f);
  lastTarget = target.copy();

  // setting the actual display
  axisP1 = A;
  axisP2 = PVector.add(A, u);
  theta = thetaFound;
  
  return lastSolutionOK;
}

// --- math helpers --- //

// Rotate point p around an axis line that passes through axisPoint and has unit direction axisDir (Rodrigues)
// axisDir must be normalized.
PVector rotateAroundAxis(PVector p, PVector axisPoint, PVector axisDir, float ang) {
  // v = p - a
  PVector v = PVector.sub(p, axisPoint);
  float cosA = cos(ang);
  float sinA = sin(ang);
  PVector term1 = PVector.mult(v, cosA);
  PVector crossUV = cross(axisDir, v);
  PVector term2 = PVector.mult(crossUV, sinA);
  float dot = axisDir.x * v.x + axisDir.y * v.y + axisDir.z * v.z;
  PVector term3 = PVector.mult(axisDir, dot * (1 - cosA));
  PVector vrot = PVector.add(PVector.add(term1, term2), term3);
  return PVector.add(axisPoint, vrot);
}

PVector cross(PVector a, PVector b) {
  return new PVector(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x);
}

PVector faceNormal(PVector a, PVector b, PVector c) {
  PVector u = PVector.sub(b, a);
  PVector v = PVector.sub(c, a);
  PVector n = cross(u, v);
  float m = n.mag();
  if (m == 0) return new PVector(0, 0, 1);
  n.div(m);
  return n;
}

// Distance from point p to line through a1->a2
float distancePointLine(PVector p, PVector a1, PVector a2) {
  PVector ap = PVector.sub(p, a1);
  PVector ab = PVector.sub(a2, a1);
  float abLen = ab.mag();
  if (abLen == 0) return ap.mag();
  PVector abNorm = PVector.div(ab, abLen);
  PVector proj = PVector.mult(abNorm, ap.dot(abNorm));
  PVector perp = PVector.sub(ap, proj);
  return perp.mag();
}

// --- centroid helper ---
PVector centroidOfTriangle() {
  PVector c = new PVector(0,0,0);
  for (int i = 0; i < 3; i++) c.add(tri[i]);
  c.div(3.0);
  return c;
}

void mousePressed() {
  // Apply same transforms as draw3DView before calling screenX/Y
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomFactor);
  rotateX(sceneRotX);
  rotateY(sceneRotY);

  int hitIndex = -1;
  for (int i = 0; i < reachablePoints.size(); i++) {
    PVector p = reachablePoints.get(i);
    float sx = screenX(p.x, p.y, p.z);
    float sy = screenY(p.x, p.y, p.z);
    if (dist(mouseX, mouseY, sx, sy) < 8 && selectedPoint == -1) {
      hitIndex = i;
      break;
    }
  }

  popMatrix();

  if (hitIndex != -1) {
    selectedPoint = hitIndex;
    println("Selected " + hitIndex + " at " + reachablePoints.get(hitIndex));
    penControl.sendMotorCommand(reachablePoints.get(hitIndex));
  }
}

void mouseDragged() {
  sceneRotY += (mouseX - pmouseX) * 0.01;
  sceneRotX -= (mouseY - pmouseY) * 0.01;
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  zoomFactor *= (1 - e * 0.05);
}

void keyPressed() {
  if (key == ' ') {
    selectedPoint = -1;
  }
}
