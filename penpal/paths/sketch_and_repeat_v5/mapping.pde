// Triangular Torus Slice
// - Defines a triangle (3 vertices) in the XY plane (z = 0).
// - Defines an axis (two points) that lies in the XY plane (z = 0).
// - Rotates (sweeps) the triangle around the axis by angle `theta` (radians).
// - Builds a mesh by sampling `steps` intermediate rotations and connects corresponding vertices.
// - Controls: e (toggle edit mode), +/- angle, [ ] steps, c caps, w wireframe, r reset.
// - In Edit mode you can drag triangle vertices and axis endpoints in top-down view.

// all units in mm
class Mapping {
  float s = 10;
  float R = s / sqrt(3);        // distance from center to each vertex
  float r = s / (2*sqrt(3));    // distance from center to each side (inradius)
  
  PVector[] tri = {
    new PVector(0,   R),
    new PVector(-s/2, -r),
    new PVector( s/2, -r)
  };

  PVector axisP1, axisP2; // axis endpoints (both z = 0)
  float theta;        // sweep angle in radians (default 180°)
  int steps = 72;          // subdivisions along sweep (higher => smoother)
  
  PVector lastAxisPoint = null;
  PVector lastAxisDir = null;
  float lastTheta = 0;
  boolean lastSolutionOK = false;
  PVector lastTarget = null;
  
  float tipLength;   // length of the tip line
  
  Mapping() {
    
    // creating the tip
    tipLength = 13.7;
    
    println("mapping constructed");
  }
  
  float[] getTendonLengths(PVector pos) {
    // --- find arc lengths of swept edges ---
    boolean foundLengths = findAxisAndThetaForTipEnd(pos); // first we send the pen to the position
    
    float[] arcLens;
    arcLens = new float[3];
    
    if (foundLengths && abs(theta) < PI / 2) { // we can use the axis and theta stuff (we enforce a 90 degree limit)
      for (int i = 0; i < 3; i++) {
        float r = distancePointLine(tri[i], axisP1, axisP2);
        arcLens[i] = r * abs(theta);
      }
    }
    
    if (!foundLengths) {
      if (pos.x == 0 && pos.y == 0 && pos.z > tipLength) { // if the desired point is directly ahead
        println("our position is just directly ahead");
        for (int i = 0; i < 3; i++) {
          arcLens[i] = pos.z - tipLength;
        }
      }
    }
    return arcLens;
  }
  
  // small helper to print float with limited decimals
  float degrees(float rad, int decimals) {
    float d = degrees(rad);
    float p = pow(10, decimals);
    return round(d * p) / p;
  }
  
  float degrees(float rad) {
    return rad * (180.0 / PI);
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
      if (ok) {
        println("Solved only after flipping initial normal (used -n0).");
      }
    }
    if (!ok) {
      println("findAxisAndThetaForTipEnd(): NO SOLUTION found for target.");
    }
    
    return ok;
  }
  
  // --- low-level solver that maps point S to target by rotation about some axis with direction u in z=0 ---
  // The function chooses u perpendicular to the XY projection of (target - S) (the necessary condition),
  // then solves two linear equations for axis point A = (Ax,Ay,0), then computes theta.
  // Returns true if verification distance less than tolerance.
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
    //println("=== findAxisAndThetaForTipEnd() result ===");
    //println("Initial tip S = " + nf(S.x,1,4) + ", " + nf(S.y,1,4) + ", " + nf(S.z,1,4));
    //println("Target T      = " + nf(target.x,1,4) + ", " + nf(target.y,1,4) + ", " + nf(target.z,1,4));
    //println("Axis point A  = " + nf(A.x,1,5) + ", " + nf(A.y,1,5) + ", 0.00000");
    //println("Axis dir u    = " + nf(u.x,1,6) + ", " + nf(u.y,1,6) + ", " + nf(u.z,1,6));
    //println("Theta (rad)   = " + nf(thetaFound,1,6) + "   Theta (deg) = " + nf(degrees(thetaFound),1,4));
    //println("Verification: |rotate(S) - T| = " + nf(err,1,6));
    //if (!lastSolutionOK) println("WARNING: verification error is large — solution may be unstable.");
  
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
}
