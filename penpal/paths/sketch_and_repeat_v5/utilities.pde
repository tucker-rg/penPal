 // This is where we store the utility motions (line, circle, etc)
// Also, other preset motions, chosen by the user

void createLine() {
  // the line
  line = new Doodle();
  PVector lPos0 = new PVector(-6.0, 0.0);
  PVector lPos1 = new PVector(6.0, 0.0);
  line.addPoint(new TimedPoint(lPos0));
  line.addPoint(new TimedPoint(lPos1)); // we don't care about time here
  
  line.setWaitTime(75);
  line.setMode(MODE_BRUTE); // BRUTE FORCE  
  line.setConnectLastPoint(true);
  // println("i created the line");
}

void createTriangle() {
  // the triangle
  triangle = new Doodle();
  PVector[] tPts = new PVector[3];
  tPts[0] = new PVector(0.0, 5.8923); // three pointed triangle
  tPts[1] = new PVector(6, -4.5);
  tPts[2] = new PVector(-6, -4.5);
  for (int i = 0; i < 3; i++) {
    triangle.addPoint(new TimedPoint(tPts[i]));
  }
  triangle.setWaitTime(50);
  triangle.setMode(MODE_BRUTE);
  triangle.setConnectLastPoint(true);
  // println("i created the triangle");
}

void createCircle() {
  // the circle
  circle = new Doodle();
  PVector[] cPts = new PVector[18];
  for (int i = 0; i < 18; i++) {
    float angle = radians(i * (360 / 18));
    float x = 4 * cos(angle);
    float y = 4 * sin(angle);
    cPts[i] = new PVector(x, y);
    circle.addPoint(new TimedPoint(cPts[i]));
  }
  circle.setWaitTime(10);
  circle.setMode(MODE_BRUTE);
  circle.setConnectLastPoint(true);
  // println("i created the circle");
}
  
void createStamp() {
  // the stamp (cat)
  stamp = new Doodle();
  PVector[] sPts = new PVector[156];
  sPts[0] = new PVector(5.4197, 6.1635);
  sPts[1] = new PVector(5.282, 6.0666);
  sPts[2] = new PVector(5.0659, 5.8751);
  sPts[3] = new PVector(5.0659, 5.8751);
  sPts[4] = new PVector(4.7077, 5.5704);
  sPts[5] = new PVector(4.4289, 5.4461);
  sPts[6] = new PVector(4.4289, 5.4461);
  sPts[7] = new PVector(3.9589, 5.4407);
  sPts[8] = new PVector(3.3049, 5.6804);
  sPts[9] = new PVector(3.3049, 5.6804);
  sPts[10] = new PVector(2.9708, 5.8243);
  sPts[11] = new PVector(2.8101, 5.8583);
  sPts[12] = new PVector(2.8101, 5.8583);
  sPts[13] = new PVector(2.7076, 5.8495);
  sPts[14] = new PVector(2.6482, 5.7922);
  sPts[15] = new PVector(2.6482, 5.7922);
  sPts[16] = new PVector(2.5825, 5.6053);
  sPts[17] = new PVector(2.5804, 5.3031);
  sPts[18] = new PVector(2.5804, 5.3031);
  sPts[19] = new PVector(2.6487, 4.8984);
  sPts[20] = new PVector(2.8414, 4.3044);
  sPts[21] = new PVector(2.8414, 4.3044);
  sPts[22] = new PVector(3.0232, 3.7485);
  sPts[23] = new PVector(3.0738, 3.426);
  sPts[24] = new PVector(3.0738, 3.426);
  sPts[25] = new PVector(3.0402, 3.1786);
  sPts[26] = new PVector(2.9224, 3.0006);
  sPts[27] = new PVector(2.9224, 3.0006);
  sPts[28] = new PVector(2.69, 2.8765);
  sPts[29] = new PVector(2.1326, 2.7722);
  sPts[30] = new PVector(2.1326, 2.7722);
  sPts[31] = new PVector(1.0357, 2.5505);
  sPts[32] = new PVector(0.1875, 2.2459);
  sPts[33] = new PVector(0.1875, 2.2459);
  sPts[34] = new PVector(-1.1875, 1.2433);
  sPts[35] = new PVector(-2.1453, -0.2946);
  sPts[36] = new PVector(-2.1453, -0.2946);
  sPts[37] = new PVector(-2.3269, -0.7925);
  sPts[38] = new PVector(-2.5644, -1.5852);
  sPts[39] = new PVector(-2.5644, -1.5852);
  sPts[40] = new PVector(-2.854, -2.4563);
  sPts[41] = new PVector(-3.2484, -2.93);
  sPts[42] = new PVector(-3.2484, -2.93);
  sPts[43] = new PVector(-4.0142, -3.5292);
  sPts[44] = new PVector(-5.0747, -4.0139);
  sPts[45] = new PVector(-5.0747, -4.0139);
  sPts[46] = new PVector(-5.6046, -4.2394);
  sPts[47] = new PVector(-5.8945, -4.4297);
  sPts[48] = new PVector(-5.8945, -4.4297);
  sPts[49] = new PVector(-6.1114, -4.7123);
  sPts[50] = new PVector(-6.2, -5.1039);
  sPts[51] = new PVector(-6.2, -5.1039);
  sPts[52] = new PVector(-6.0469, -5.6365);
  sPts[53] = new PVector(-5.4885, -6.0556);
  sPts[54] = new PVector(-5.4885, -6.0556);
  sPts[55] = new PVector(-5.3102, -6.1305);
  sPts[56] = new PVector(-5.1504, -6.1818);
  sPts[57] = new PVector(-5.1504, -6.1818);
  sPts[58] = new PVector(-4.8809, -6.2);
  sPts[59] = new PVector(-4.7679, -6.1181);
  sPts[60] = new PVector(-4.7679, -6.1181);
  sPts[61] = new PVector(-4.8368, -6.0298);
  sPts[62] = new PVector(-5.0016, -5.8586);
  sPts[63] = new PVector(-5.0016, -5.8586);
  sPts[64] = new PVector(-5.3157, -5.471);
  sPts[65] = new PVector(-5.3214, -5.1664);
  sPts[66] = new PVector(-5.3214, -5.1664);
  sPts[67] = new PVector(-5.0604, -4.8922);
  sPts[68] = new PVector(-4.576, -4.628);
  sPts[69] = new PVector(-4.576, -4.628);
  sPts[70] = new PVector(-3.8765, -4.3651);
  sPts[71] = new PVector(-3.1348, -4.0968);
  sPts[72] = new PVector(-3.1348, -4.0968);
  sPts[73] = new PVector(-2.4596, -3.9576);
  sPts[74] = new PVector(-1.9978, -4.1401);
  sPts[75] = new PVector(-1.9978, -4.1401);
  sPts[76] = new PVector(-1.9436, -4.1816);
  sPts[77] = new PVector(-1.8895, -4.223);
  sPts[78] = new PVector(-1.8895, -4.223);
  sPts[79] = new PVector(-0.7883, -4.2212);
  sPts[80] = new PVector(0.3128, -4.2194);
  sPts[81] = new PVector(0.3128, -4.2194);
  sPts[82] = new PVector(1.4146, -4.2164);
  sPts[83] = new PVector(2.5164, -4.2134);
  sPts[84] = new PVector(2.5164, -4.2134);
  sPts[85] = new PVector(2.5131, -4.1359);
  sPts[86] = new PVector(2.5099, -4.0584);
  sPts[87] = new PVector(2.5099, -4.0584);
  sPts[88] = new PVector(2.3596, -3.6605);
  sPts[89] = new PVector(1.7775, -3.5428);
  sPts[90] = new PVector(1.7775, -3.5428);
  sPts[91] = new PVector(1.5564, -3.5287);
  sPts[92] = new PVector(1.4577, -3.5164);
  sPts[93] = new PVector(1.4577, -3.5164);
  sPts[94] = new PVector(1.5021, -3.3735);
  sPts[95] = new PVector(1.6718, -3.0441);
  sPts[96] = new PVector(1.6718, -3.0441);
  sPts[97] = new PVector(2.1047, -2.3947);
  sPts[98] = new PVector(2.4955, -2.0166);
  sPts[99] = new PVector(2.4955, -2.0166);
  sPts[100] = new PVector(2.6101, -1.9722);
  sPts[101] = new PVector(2.7814, -1.971);
  sPts[102] = new PVector(2.7814, -1.971);
  sPts[103] = new PVector(3.0399, -2.0174);
  sPts[104] = new PVector(3.22, -2.1404);
  sPts[105] = new PVector(3.22, -2.1404);
  sPts[106] = new PVector(3.3158, -2.3028);
  sPts[107] = new PVector(3.3714, -2.6319);
  sPts[108] = new PVector(3.3714, -2.6319);
  sPts[109] = new PVector(3.4098, -2.8705);
  sPts[110] = new PVector(3.4707, -3.0549);
  sPts[111] = new PVector(3.4707, -3.0549);
  sPts[112] = new PVector(4.1317, -3.9265);
  sPts[113] = new PVector(4.921, -4.3312);
  sPts[114] = new PVector(4.921, -4.3312);
  sPts[115] = new PVector(5.0917, -4.2905);
  sPts[116] = new PVector(5.2134, -4.1425);
  sPts[117] = new PVector(5.2134, -4.1425);
  sPts[118] = new PVector(5.2738, -3.9418);
  sPts[119] = new PVector(5.2382, -3.7628);
  sPts[120] = new PVector(5.2382, -3.7628);
  sPts[121] = new PVector(5.1468, -3.6532);
  sPts[122] = new PVector(4.9811, -3.4852);
  sPts[123] = new PVector(4.9811, -3.4852);
  sPts[124] = new PVector(4.4316, -2.7363);
  sPts[125] = new PVector(4.2826, -1.7667);
  sPts[126] = new PVector(4.2826, -1.7667);
  sPts[127] = new PVector(4.4171, -0.6913);
  sPts[128] = new PVector(4.8375, 0.1417);
  sPts[129] = new PVector(4.8375, 0.1417);
  sPts[130] = new PVector(4.9967, 0.3222);
  sPts[131] = new PVector(5.2421, 0.5767);
  sPts[132] = new PVector(5.2421, 0.5767);
  sPts[133] = new PVector(5.7656, 1.2195);
  sPts[134] = new PVector(5.8857, 1.8469);
  sPts[135] = new PVector(5.8857, 1.8469);
  sPts[136] = new PVector(5.8606, 2.2301);
  sPts[137] = new PVector(5.7669, 2.6304);
  sPts[138] = new PVector(5.7669, 2.6304);
  sPts[139] = new PVector(5.6966, 3.2965);
  sPts[140] = new PVector(5.9993, 3.8057);
  sPts[141] = new PVector(5.9993, 3.8057);
  sPts[142] = new PVector(6.2, 4.1049);
  sPts[143] = new PVector(6.1677, 4.5231);
  sPts[144] = new PVector(6.1677, 4.5231);
  sPts[145] = new PVector(6.066, 5.0447);
  sPts[146] = new PVector(5.9967, 5.5266);
  sPts[147] = new PVector(5.9967, 5.5266);
  sPts[148] = new PVector(5.9009, 6.0046);
  sPts[149] = new PVector(5.7317, 6.1707);
  sPts[150] = new PVector(5.7317, 6.1707);
  sPts[151] = new PVector(5.5786, 6.2);
  sPts[152] = new PVector(5.4197, 6.1635);
  sPts[153] = new PVector(5.4197, 6.1635);
  sPts[154] = new PVector(5.4197, 6.1635);
  sPts[155] = new PVector(5.4197, 6.1635);
  
  for (int i = 0; i < 156; i++) {
    stamp.addPoint(new TimedPoint(sPts[i], i * 30));
  }
  
  stamp.setConnectLastPoint(true);
  // println("i created the stamp");
}

// Utility functions
void setLine() {
  println("setting current doodle to preset: LINE");
  selectedPreset = 0; // to make sure we don't accidentally delete the previous preset
  clear();
  selectedPreset = -1;
  currentDoodle = line.copy();
  startReplay();
}

void setTriangle() {
  println("setting current doodle to preset: TRIANGLE");
  selectedPreset = 0;
  clear();
  selectedPreset = -2;
  currentDoodle = triangle.copy();
  startReplay();
}

void setCircle() {
  println("setting current doodle to preset: CIRCLE");
  selectedPreset = 0;
  clear();
  selectedPreset = -3;
  currentDoodle = circle.copy();
  startReplay();
}

void setStamp() {
  println("setting current doodle to preset: STAMP");
  selectedPreset = 0;
  clear();
  selectedPreset = -4;
  currentDoodle = stamp.copy();
  startReplay();
}

void set1() {
  println("setting current doodle to custom preset: 1");
  selectedPreset = 0; // to make sure that we don't accidentally delete our previous preset
  clear();
  selectedPreset = 1;
  currentDoodle = preset1.copy();
  startReplay();
}

void set2() {
  println("setting current doodle to custom preset: 2");
  selectedPreset = 0; // to make sure that we don't accidentally delete our previous preset
  clear();
  selectedPreset = 2;
  currentDoodle = preset2.copy();
  startReplay();
}

void set3() {
  println("setting current doodle to custom preset: 3");
  selectedPreset = 0; // to make sure that we don't accidentally delete our previous preset
  clear();
  selectedPreset = 3;
  currentDoodle = preset3.copy();
  startReplay();
}

void set4() {
  println("setting current doodle to custom preset: 4");
  selectedPreset = 0; // to make sure that we don't accidentally delete our previous preset
  clear();
  selectedPreset = 4;
  currentDoodle = preset4.copy();
  startReplay();
}

void save() {
  //if (preset1.getCount() == 0) {
  //  reset1();
  //} else if (preset2.getCount() == 0) {
  //  reset2();
  //} else if (preset3.getCount() == 0) {
  //  reset3();
  //} else if (preset4.getCount() == 0) {
  //  reset4();
  //} else {
  //  println("trying to save but no empty slots");
  //}
  
  if (selectedPreset == 1) {
    reset1();
  } else if (selectedPreset == 2) {
    reset2();
  } else if (selectedPreset == 3) {
    reset3();
  } else if (selectedPreset == 4) {
    reset4();
  } else {
    println("trying to save but no valid slot selected!");
  }
}

void reset1() {
  println("resetting preset 1 to the current doodle"); 
  selectedPreset = 1;
  preset1 = currentDoodle.copy();
  updateUI();
}

void reset2() {
  println("resetting preset 2 to the current doodle");
  selectedPreset = 2;
  preset2 = currentDoodle.copy();
  updateUI();
}

void reset3() {
  println("resetting preset 3 to the current doodle");
  selectedPreset = 3;
  preset3 = currentDoodle.copy();
  updateUI();
}

void reset4() {
  println("resetting preset 4 to the current doodle");
  selectedPreset = 4;
  preset4 = currentDoodle.copy();
  updateUI();
}

int findFirstAvailableSlot() {
  if (preset1.getCount() == 0) {
    return 1;
  } else if (preset2.getCount() == 0) {
    return 2;
  } else if (preset3.getCount() == 0) {
    return 3;
  } else if (preset4.getCount() == 0) {
    return 4;
  } else {
    println("no empty slots!");
    if (selectedPreset == 1) {
      reset2();
      return 2;
    } else if (selectedPreset == 2) {
      reset3();
      return 3;
    } else if (selectedPreset == 3) {
      reset4();
      return 4;
    } else {
      reset1();
      return 1;
    }
  }
}
