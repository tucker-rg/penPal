// Triangular Torus Slice
// - Defines a triangle (3 vertices) in the XY plane (z = 0).
// - Defines an axis (two points) that lies in the XY plane (z = 0).
// - Rotates (sweeps) the triangle around the axis by angle `theta` (radians).
// - Builds a mesh by sampling `steps` intermediate rotations and connects corresponding vertices.
// - Controls: e (toggle edit mode), +/- angle, [ ] steps, c caps, w wireframe, r reset.
// - In Edit mode you can drag triangle vertices and axis endpoints in top-down view.

PVector[] tri = new PVector[3];
PVector axisP1, axisP2; // axis endpoints (both z = 0)
float theta = PI;        // sweep angle in radians (default 180°)
int steps = 72;          // subdivisions along sweep (higher => smoother)
boolean showCaps = true;
boolean wireframe = false;

float sceneRotX = -0.5, sceneRotY = 0.8; // initial 3D view rotation
float zoomFactor = 1.0;

boolean editMode = false;
int draggingIndex = -1; // 0..2 triangle verts, -2 axisP1, -3 axisP2
float pickRadius = 12;

float lastMouseX, lastMouseY;

PVector lastAxisPoint = null;
PVector lastAxisDir = null;
float lastTheta = 0;
boolean lastSolutionOK = false;
PVector lastTarget = null;

float tipLength = 100;   // length of the tip line

void setup() {
  size(1000, 700, P3D);
  // default triangle (centered around origin)
  tri[0] = new PVector(-86.6, -50, 0);
  tri[1] = new PVector(86.6, -50, 0);
  tri[2] = new PVector(0, 100, 0);
  // default axis (line along +X through left of triangle)
  axisP1 = new PVector(-120, 60, 0);
  axisP2 = new PVector(-120, -60, 0);
  smooth(8);
  textFont(createFont("SansSerif", 12));
}

void draw() {
  background(200);
  if (editMode) {
    drawTopDownEdit();
  } else {
    draw3DView();
  }
  drawHUD();
}

void draw3DView() {
  pushMatrix();
  translate(width/2, height/2);
  scale(zoomFactor);
  // basic orbiting
  rotateX(sceneRotX);
  rotateY(sceneRotY);

  lights();
  ambientLight(60, 60, 60);
  directionalLight(200, 200, 200, -0.5, -0.8, -0.3);
  noStroke();

  // Draw axis (as a thin cylinder-like line)
  stroke(255, 180);
  strokeWeight(2);
  line(axisP1.x, axisP1.y, axisP1.z, axisP2.x, axisP2.y, axisP2.z);
  noStroke();

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
  if (showCaps) {
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
  }
  
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
    strokeWeight(3);
    line(capCentroid.x, capCentroid.y, capCentroid.z,
         tipEnd.x, tipEnd.y, tipEnd.z);

    // small sphere at tip end
    noStroke();
    fill(255, 0, 0);
    pushMatrix();
    translate(tipEnd.x, tipEnd.y, tipEnd.z);
    sphereDetail(6);
    sphere(6);
    popMatrix();
  }

  // --- debug: draw last solver result ---
  if (lastTarget != null && lastAxisPoint != null) {
    // draw axis as long magenta line
    stroke(255, 100, 200);
    strokeWeight(3);
    float L = 1000;
    PVector a1 = PVector.sub(lastAxisPoint, PVector.mult(lastAxisDir, L));
    PVector a2 = PVector.add(lastAxisPoint, PVector.mult(lastAxisDir, L));
    line(a1.x, a1.y, a1.z, a2.x, a2.y, a2.z);

    // draw rotated initial tip endpoint (should match target)
    PVector C = centroidOfTriangle();
    PVector n0 = faceNormal(tri[0], tri[1], tri[2]);
    n0.normalize();
    PVector S = PVector.add(C, PVector.mult(n0, tipLength));
    PVector Srot = rotateAroundAxis(S, lastAxisPoint, lastAxisDir, lastTheta);
    noStroke();
    fill(0, 255, 0);
    pushMatrix(); translate(Srot.x, Srot.y, Srot.z); sphereDetail(8); sphere(6); popMatrix();

    // draw requested target
    fill(255, 0, 0);
    pushMatrix(); translate(lastTarget.x, lastTarget.y, lastTarget.z); sphereDetail(8); sphere(6); popMatrix();
  }

  
  // Wireframe overlay (optional)
  if (wireframe) {
    stroke(0, 180);
    strokeWeight(1);
    noFill();
    for (int i = 0; i < steps; i++) {
      for (int j = 0; j < 3; j++) {
        int jNext = (j + 1) % 3;
        PVector v0 = sweep[i][j];
        PVector v1 = sweep[i][jNext];
        PVector v2 = sweep[i+1][jNext];
        PVector v3 = sweep[i+1][j];
        // edges
        line(v0.x, v0.y, v0.z, v1.x, v1.y, v1.z);
        line(v1.x, v1.y, v1.z, v2.x, v2.y, v2.z);
        line(v2.x, v2.y, v2.z, v3.x, v3.y, v3.z);
        line(v3.x, v3.y, v3.z, v0.x, v0.y, v0.z);
      }
    }
  }

  // draw original triangle & axis points as guides
  stroke(255, 220);
  strokeWeight(2);
  noFill();
  beginShape();
  for (int j = 0; j < 3; j++) vertex(tri[j].x, tri[j].y, tri[j].z);
  endShape(CLOSE);
  noStroke();
  fill(255, 150);
  for (int j = 0; j < 3; j++) {
    pushMatrix();
    translate(tri[j].x, tri[j].y, tri[j].z);
    sphereDetail(6);
    sphere(4);
    popMatrix();
  }

  popMatrix();
}

void drawTopDownEdit() {
  // 2D orthographic top-down editing (Z ignored). Origin at center.
  pushMatrix();
  translate(width/2, height/2);
  scale(1);
  // grid
  stroke(60);
  for (int x = -width; x <= width; x += 40) line(x, -height, x, height);
  for (int y = -height; y <= height; y += 40) line(-width, y, width, y);

  // axis
  strokeWeight(3);
  stroke(255, 150, 0);
  line(axisP1.x, axisP1.y, axisP2.x, axisP2.y);
  // axis endpoints
  fill(255, 180, 0);
  noStroke();
  ellipse(axisP1.x, axisP1.y, 12, 12);
  ellipse(axisP2.x, axisP2.y, 12, 12);

  // triangle
  stroke(0, 200);
  strokeWeight(2);
  fill(120, 120);
  beginShape();
  for (int i = 0; i < 3; i++) vertex(tri[i].x, tri[i].y);
  endShape(CLOSE);

  // vertices
  fill(0, 200, 220);
  noStroke();
  for (int i = 0; i < 3; i++) ellipse(tri[i].x, tri[i].y, 12, 12);

  popMatrix();
}

void drawHUD() {
  hint(DISABLE_DEPTH_TEST); // draw HUD on top
  fill(255);
  textAlign(LEFT, TOP);
  String mode = editMode ? "EDIT MODE (top-down): drag vertices & axis endpoints" : "3D VIEW: drag mouse to orbit, mouse wheel to zoom";
  text(mode, 10, 10);
  text("theta: " + degrees(theta, 2) + "°    steps: " + steps + "    caps: " + (showCaps ? "ON" : "OFF") + "    wireframe: " + (wireframe ? "ON" : "OFF"), 10, 30);
  text("Controls: e toggle edit | +/- adjust angle | [ ] steps | c caps | w wireframe | r reset", 10, 50);
  text("Tip: choose an axis that does NOT intersect the triangle for classic 'triangular-torus-slice' appearance", 10, 70);
  hint(ENABLE_DEPTH_TEST);
  
  // --- print arc lengths of swept edges ---
  float[] arcLens = new float[3];
  for (int i = 0; i < 3; i++) {
    float r = distancePointLine(tri[i], axisP1, axisP2);
    arcLens[i] = r * abs(theta);
  }
  text("Arc lengths (one per vertex sweep): " +
          nf(arcLens[0],1,3) + ", " +
          nf(arcLens[1],1,3) + ", " +
          nf(arcLens[2],1,3), 10, 90);
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
boolean findAxisAndThetaForCapCenter(PVector target) {
  PVector C = centroidOfTriangle();
  PVector d = PVector.sub(target, C);
  float dx = d.x, dy = d.y, dz = d.z;
  final float EPS = 1e-7;

  // Degenerate: same XY projection
  if (abs(dx) < EPS && abs(dy) < EPS) {
    if (abs(dz) < EPS) {
      // trivial: target == centroid
      lastAxisDir = new PVector(1,0,0);
      lastAxisPoint = new PVector(C.x, C.y, 0);
      lastTheta = 0;
      lastSolutionOK = true;
      println("Target equals centroid. Trivial solution: theta = 0, axis arbitrary.");
      return true;
    } else {
      println("NO SOLUTION: target projects to the same XY as the centroid but has different Z.");
      println("With the axis constrained to the XY plane (z=0) you cannot rotate the centroid straight up/down.");
      lastSolutionOK = false;
      return false;
    }
  }

  // choose u perpendicular to d's XY component
  PVector u = new PVector(-dy, dx, 0);
  if (u.mag() < EPS) {
    println("Numerical degenerate while building axis direction.");
    lastSolutionOK = false;
    return false;
  }
  u.normalize();

  // linear system:
  // (1) u_x * Ax + u_y * Ay = u·C
  // (2) d_x * Ax + d_y * Ay = (|P|^2 - |C|^2)/2
  float e = u.dot(C);
  float rhs = (target.x*target.x + target.y*target.y + target.z*target.z
               - (C.x*C.x + C.y*C.y + C.z*C.z)) * 0.5f;

  float det = u.x * d.y - u.y * d.x; // should be nonzero for non-degenerate case
  if (abs(det) < 1e-9) {
    println("Degenerate linear system (det ~= 0). Can't find unique A with this method.");
    lastSolutionOK = false;
    return false;
  }

  float Ax = ( e * d.y - u.y * rhs ) / det;
  float Ay = ( u.x * rhs - e * d.x ) / det;
  PVector A = new PVector(Ax, Ay, 0);

  // vectors in rotation plane
  PVector v = PVector.sub(C, A);
  PVector w = PVector.sub(target, A);

  // compute angle
  PVector crossVW = cross(v, w);            // uses your existing cross()
  float numer = u.dot(crossVW);             // signed area term
  float denom = v.dot(w);
  float thetaFound = atan2(numer, denom);   // signed rotation angle in radians

  // verify by performing an actual rotation
  PVector Crot = rotateAroundAxis(C, A, u, thetaFound);
  float err = PVector.dist(Crot, target);

  // store results
  lastAxisPoint = A.copy();
  lastAxisDir = u.copy();
  lastTheta = thetaFound;
  lastSolutionOK = (err < 1e-4);

  // print nicely
  println("=== findAxisAndThetaForCapCenter() result ===");
  println("Centroid C = " + nf(C.x,1,3) + ", " + nf(C.y,1,3) + ", " + nf(C.z,1,3));
  println("Target P   = " + nf(target.x,1,3) + ", " + nf(target.y,1,3) + ", " + nf(target.z,1,3));
  println("Axis point A (on z=0): " + nf(A.x,1,4) + ", " + nf(A.y,1,4) + ", 0.0000");
  println("Axis unit dir u:       " + nf(u.x,1,6) + ", " + nf(u.y,1,6) + ", " + nf(u.z,1,6));
  println("Theta (rad): " + nf(thetaFound,1,6) + "    Theta (deg): " + nf(degrees(thetaFound),1,4));
  println("Verification: distance(rotated centroid, target) = " + nf(err,1,6));
  if (!lastSolutionOK) println("WARNING: verification error is not tiny; solution may be numerically unstable.");

  // setting the actual display
  axisP1 = A;
  axisP2 = PVector.add(A, u);
  theta = thetaFound;
  
  return lastSolutionOK;
}

// Same thing, but for the tip end this time
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
    if (ok) {
      println("Solved only after flipping initial normal (used -n0).");
    }
  }
  if (!ok) {
    println("findAxisAndThetaForTipEnd(): NO SOLUTION found for target.");
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
      println("Trivial: target equals initial tip endpoint (theta = 0).");
      return true;
    } else {
      println("NO SOLUTION: target shares XY projection with S but different Z — impossible with axis in z=0.");
      lastSolutionOK = false;
      return false;
    }
  }

  // Choose axis direction u in XY plane perpendicular to (target - S) projection
  PVector u = new PVector(-dy, dx, 0);
  if (u.mag() < EPS) {
    println("Numerical degeneracy when choosing axis direction u.");
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
    println("Degenerate linear system (det ~= 0). Can't find unique axis point A with this method.");
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

  // print nicely
  println("=== findAxisAndThetaForTipEnd() result ===");
  println("Initial tip S = " + nf(S.x,1,4) + ", " + nf(S.y,1,4) + ", " + nf(S.z,1,4));
  println("Target T      = " + nf(target.x,1,4) + ", " + nf(target.y,1,4) + ", " + nf(target.z,1,4));
  println("Axis point A  = " + nf(A.x,1,5) + ", " + nf(A.y,1,5) + ", 0.00000");
  println("Axis dir u    = " + nf(u.x,1,6) + ", " + nf(u.y,1,6) + ", " + nf(u.z,1,6));
  println("Theta (rad)   = " + nf(thetaFound,1,6) + "   Theta (deg) = " + nf(degrees(thetaFound),1,4));
  println("Verification: |rotate(S) - T| = " + nf(err,1,6));
  if (!lastSolutionOK) println("WARNING: verification error is large — solution may be unstable.");

  // setting the actual display
  axisP1 = A;
  axisP2 = PVector.add(A, u);
  theta = thetaFound;
  
  return lastSolutionOK;
}

// --- interaction --- //

void mousePressed() {
  lastMouseX = mouseX;
  lastMouseY = mouseY;
  if (editMode) {
    // pick nearest control (in 2D top-down coordinates)
    PVector m = screenToWorld2D(mouseX, mouseY);
    // pick tri verts
    for (int i = 0; i < 3; i++) {
      if (PVector.dist(m, tri[i]) <= pickRadius) {
        draggingIndex = i;
        return;
      }
    }
    if (PVector.dist(m, axisP1) <= pickRadius) {
      draggingIndex = -2;
      return;
    }
    if (PVector.dist(m, axisP2) <= pickRadius) {
      draggingIndex = -3;
      return;
    }
    draggingIndex = -1;
  } else {
    draggingIndex = -1; // not used
  }
}

void mouseDragged() {
  float dx = mouseX - lastMouseX;
  float dy = mouseY - lastMouseY;
  lastMouseX = mouseX;
  lastMouseY = mouseY;

  if (editMode) {
    if (draggingIndex >= 0 && draggingIndex <= 2) {
      PVector m = screenToWorld2D(mouseX, mouseY);
      tri[draggingIndex].x = m.x;
      tri[draggingIndex].y = m.y;
      tri[draggingIndex].z = 0;
    } else if (draggingIndex == -2) {
      PVector m = screenToWorld2D(mouseX, mouseY);
      axisP1.x = m.x; axisP1.y = m.y; axisP1.z = 0;
    } else if (draggingIndex == -3) {
      PVector m = screenToWorld2D(mouseX, mouseY);
      axisP2.x = m.x; axisP2.y = m.y; axisP2.z = 0;
    }
  } else {
    // orbit
    sceneRotY += dx * 0.01;
    sceneRotX += dy * 0.01;
  }
}

void mouseReleased() {
  draggingIndex = -1;
}

void mouseWheel(processing.event.MouseEvent ev) {
  float e = ev.getCount();
  zoomFactor *= (1 - e * 0.08);
  zoomFactor = constrain(zoomFactor, 0.2, 5);
}

void keyPressed() {
  if (key == 'e' || key == 'E') editMode = !editMode;
  else if (key == '+' || key == '=') theta += radians(5);
  else if (key == '-' || key == '_') theta -= radians(5);
  else if (key == '[') steps = max(1, steps - 4);
  else if (key == ']') steps = min(1024, steps + 4);
  else if (key == 'c' || key == 'C') showCaps = !showCaps;
  else if (key == 'w' || key == 'W') wireframe = !wireframe;
  else if (key == 'r' || key == 'R') resetDefaults();
  
  // for testing the endpoint finder
  else if (key == 'f') {
   PVector exampleTarget = new PVector(100, 100, 120); 
   findAxisAndThetaForCapCenter(exampleTarget);
  }
  else if (key == 'g') {
   PVector exampleTarget = new PVector(100, -100, -120); 
   findAxisAndThetaForCapCenter(exampleTarget);
  }
  else if (key == 'h') {
   PVector exampleTarget = new PVector(-100, -100, 300); 
   findAxisAndThetaForCapCenter(exampleTarget);
  }
  
  // These ones use the tip rather than the center of the cap
  else if (key == 'F') {
   PVector exampleTarget = new PVector(100, 100, 120); 
   findAxisAndThetaForTipEnd(exampleTarget);
  }
  else if (key == 'G') {
   PVector exampleTarget = new PVector(100, -100, 120); 
   findAxisAndThetaForTipEnd(exampleTarget);
  }
  else if (key == 'H') {
   PVector exampleTarget = new PVector(-100, -100, 120); 
   findAxisAndThetaForTipEnd(exampleTarget);
  }
  else if (key == 'J') {
    PVector exampletarget = new PVector(-100, 100, 120);
    findAxisAndThetaForTipEnd(exampletarget);
  }
  
  // clamp theta for safety
  theta = constrain(theta, -TWO_PI*4, TWO_PI*4); // allow multiple revolutions, but bounded
}

void resetDefaults() {
  tri[0] = new PVector(-86.6, -50, 0);
  tri[1] = new PVector(86.6, -50, 0);
  tri[2] = new PVector(0, 100, 0);
  axisP1.set(-120, 0, 0);
  axisP2.set(120, 0, 0);
  theta = PI;
  steps = 72;
  showCaps = true;
  wireframe = false;
  sceneRotX = -0.5; sceneRotY = 0.8; zoomFactor = 1;
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

// small utility: convert mouse screen coords to top-down world coords used in edit mode
PVector screenToWorld2D(float sx, float sy) {
  return new PVector(sx - width/2.0, sy - height/2.0, 0);
}

// --- centroid helper ---
PVector centroidOfTriangle() {
  PVector c = new PVector(0,0,0);
  for (int i = 0; i < 3; i++) c.add(tri[i]);
  c.div(3.0);
  return c;
}
