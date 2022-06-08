import processing.sound.*; //<>// //<>// //<>// //<>// //<>// //<>//
import drop.*;

SqrOsc tone;

byte b[];
String[] lines;
int cols = 64;
int rows = 32;
int scalefactor = 16;
int [] framebuffer = new int[cols*rows];
boolean paused = false;
int speed = 10;

IntDict keyboard;
boolean [] keysPressed;
int lastKey;

boolean waitingForKey = false;
//boolean keyHandled = false;
//int bigx;

//Drag and Drop
SDrop drop;
boolean fileLoaded = false;

//CHIP-8 CPU
byte [] memory = new byte[4096];
int [] v = new int[16];
int I = 0;
int delayTimer = 0;
int soundTimer = 0;
int pc = 0x200;
IntList stack = new IntList();

void settings() {
  size(cols*scalefactor, rows*scalefactor);
}

void setup () {
  frameRate(60);

  surface.setTitle("CHIP-8 Emulator");
  surface.setLocation(1920/2 - (width/2), 200);
  //setup sound
  tone = new SqrOsc(this);
  tone.freq(440);

  //setupkeyboard
  keyboard = new IntDict();
  keyboard.set("1", 0x1);
  keyboard.set("2", 0x2);
  keyboard.set("3", 0x3);
  keyboard.set("4", 0xC);
  keyboard.set("q", 0x4);
  keyboard.set("w", 0x5);
  keyboard.set("e", 0x6);
  keyboard.set("r", 0xD);
  keyboard.set("a", 0x7);
  keyboard.set("s", 0x8);
  keyboard.set("d", 0x9);
  keyboard.set("f", 0xE);
  keyboard.set("z", 0xA);
  keyboard.set("x", 0x0);
  keyboard.set("c", 0xB);
  keyboard.set("v", 0xF);

  keysPressed = new boolean[16];

  drop = new SDrop(this);

  //load font data into memory
  loadSprites();
}

void draw() {
  background(0);
  noStroke();
  fill(18, 189, 69);

  for (var i = 0; i < framebuffer.length; i++) {
    int x = (i % cols) * scalefactor;
    int y = floor(i / cols) * scalefactor;

    if (framebuffer[i] == 0x1) {
      rect(x, y, scalefactor, scalefactor);
    }
  }

  if (fileLoaded) {
    cycle();
  }

  if (paused && waitingForKey) {
    boolean kp = false;
      for (var i = 0; i < keysPressed.length; i++) {
        if (keysPressed[i] == true) {
          kp = true;
        }
      }
      paused = false;
  }

  /*
  if (waitingForKey && paused && keyPressed) {
   if (keyboard.hasKey(str(key))) {
   println("handled key press while waiting");
   println(pc);
   waitingForKey = false;
   paused = false;
   keyHandled = true;
   pc+=2;
   v[bigx] = keyboard.get(str(key));
   }
   }
   */
}


void dropEvent (DropEvent theDropEvent) {
  fileLoaded = false;
  File myFile = theDropEvent.file();
  surface.setTitle("CHIP-8 Emulator - " + myFile.getName());
  resetChip8(); //<>//
  b = loadBytes(myFile);
  loadProgramIntoMemory(b);
}

void resetChip8 () {

  for (var i = 0x200; i < memory.length; i++) {
    memory[i] = 0;
  }

  for (var i = 0; i < v.length; i++) {
    v[i] = 0;
  }

  I = 0;
  delayTimer = 0;
  soundTimer = 0;
  pc = 0x200;
  stack.clear();
  clearDisplay();
}

void playSound() {
  if (soundTimer > 0) {
    tone.play();
  } else {
    tone.stop();
  }
}

boolean setPixel(int x, int y) {
  if (x > cols) {
    x -= cols;
  } //wrap around
  else if (x < 0) {
    x += cols;
  }
  if (y > rows) {
    y -= rows;
  } else if (y < 0) {
    y += rows;
  }

  int p = x + (y * cols); //get location in Array
  framebuffer[p] ^= 0x1;
  return (framebuffer[p] == 0x0);
}

void clearDisplay() {
  for (var i = 0; i < framebuffer.length; i++) {
    framebuffer[i] = 0x0;
  }
}

void testrender() {
  setPixel(0, 0);
  setPixel(5, 2);
}

void loadSprites () {
  int[] sprites = {
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80  // F
  };

  for (var i = 0; i < sprites.length; i++) {
    memory[i] = byte(sprites[i]);
  }
}

void loadProgramIntoMemory (byte[] program) {
  for (int i = 0; i < program.length; i++) {
    int a = program[i] & 0xFF;
    memory[0x200 + i] = byte(a);
  }

  fileLoaded = true;
}

void keyPressed () {
  String k = str(key);
  if (keyboard.hasKey(k)) {
    keysPressed[keyboard.get(k)] = true;
    lastKey = keyboard.get(k);
    soundTimer = 0x9;
  }
}

void keyReleased () {
  String k = str(key);
  if (keyboard.hasKey(k)) {
    keysPressed[keyboard.get(k)] = false;
  }
}

void cycle() {
  for (var i = 0; i < speed; i++) {
    if (!paused) {
      int a = memory[pc] & 0xFF;
      int b = memory[pc + 1] & 0xFF;
      int aa = a << 8;
      int opcode = aa | b;
      executeInstruction(opcode);
    }
  }

  //Timers
  if (!paused) {
    if (delayTimer > 0) {
      delayTimer -= 1;
    }
    if (soundTimer > 0) {
      soundTimer -= 1;
    }
  }

  playSound();
}

void executeInstruction(int opcode) {
  pc+=2; //should this be here?

  int m = (opcode & 0xF000); //most significant bit

  int x = (opcode & 0x0F00) >> 8;
  int y = (opcode & 0x00F0) >> 4;

  int nnn = (opcode & 0xFFF);
  int  nn = (opcode & 0xFF);
  int   n = (opcode & 0xF);
  println("");
  println("OPCODE= 0x" + hex(opcode, 4));


  switch(m) {

  case 0x0000: //<>//
    switch (opcode) {
      //00E0 /Display / disp_clear() / Clears the screen
    case 0x00E0:
      println("clearDisplay");
      clearDisplay();
      break;

      //00EE /Flow / return / Returns from a subroutine
    case 0x00EE:
      println("return from subroutine");
      pc = stack.pop();
      break;
    }
    break;

    //1NNN /Flow / goto NNN / Jumps to address NNN;
  case 0x1000:
    println("Jumping to: " + nnn);
    pc = nnn;
    break;

    //2NNN /Flow / *(0xNNN)() / Calls subroutine at NNN;
  case 0x2000:
    println("Call subroutine at: " + nnn);
    stack.push(pc);
    pc = nnn;
    break;

    //3XNN /Cond / if (Vx == NN) / Skips next instruction if Vx == NN
  case 0x3000:
    if (v[x] == nn) {
      pc+=2;
    }
    break;

    //4XNN /Cond / if (Vx != NN) / Skips next instruction if Vx != NN
  case 0x4000:
    if (v[x] != nn) {
      pc += 2;
    };
    break;

    //5XY0 /Cond / if (Vx == Vy) / Skips next instruction if Vx == Vy
  case 0x5000:
    if (v[x] == v[y]) {
      pc += 2;
    };
    break;

    //6XNN /Const / Vx = NN / Sets Vx to NN;
  case 0x6000:
    v[x] = nn;
    println("setting v" + x + " to: " + nn);
    println("v" + x + ": is now " + v[x]);

    break;

    //7XNN /Const / Vx += NN / Adds NN to VX (Carry flag is not changed)
  case 0x7000:
    v[x] += byte(nn);
    println("adding vx to: " + nn);
    break;
 //<>//

  case 0x8000:
    switch (n) {
      //8XY0 / Assign / Vx = Vy / Sets Vx to value of Vy;
    case 0x0:
      println("8XY0");
      v[x] = v[y];
      break;

    case 0x1:
      println("8XY1");
      v[x] |= v[y]; //<>//
      break;
    case 0x2:
      println("8XY2");
      v[x] &= v[y];
      break;
    case 0x3: //<>//
      println("8XY3");
      v[x] ^= v[y];
      break;

    case 0x4:
      println("8XY4");
      int sum = v[x] += v[y];
      v[0xF] = (sum > 0xFF) ? 1 : 0;
      v[x] = (sum & 0xFF);
      break;

    case 0x5:
      println("8XY5");
      v[0xF] = (v[x] > v[y]) ? 1 : 0;
      v[x] = (v[x] - v[y]) & 0xFF;
      break;

    case 0x6:
      println("8XY6");
      v[0xF] = ((v[x] & 0x1) == 1) ? 1 : 0;
      v[x] >>= 1;
      break;

    case 0x7:
      println("8XY7");
      v[0xF] = (v[y] > v[x]) ? 1 : 0;
      v[x] = (v[y] - v[x]) & 0xFF;
      break;

    case 0xE:
      println("8XYE");
      println(v[0xF]);
      v[0xF] = (v[x] & 0x80) >> 7;
      v[x] <<= 1;
      break;
    }
    break;

  case 0x9000:
    if (v[x] != v[y]) {
      pc += 2;
    }
    break;

  case 0xA000:
    println("setting I to: " + hex(nnn));
    I = nnn;
    break;

  case 0xB000:
    pc = nnn + v[0];
    break;

  case 0xC000:
    int rnd = floor(random(0, 0xFF));
    println("random number in v" + x + " = " + rnd);
    v[x] = rnd & nn;
    break;

  case 0xD000:
    println("Drawing pixel DXYN");
    int spriteWidth = 8;
    int spriteHeight = n;
    v[0xF] = 0;

    for (var row = 0; row < spriteHeight; row++) {
      int sprite = memory[I + row];
      for (var col = 0; col < spriteWidth; col++) {
        if ((sprite & 0x80) > 0) {

          if (setPixel(v[x] + col, v[y] + row)) { //<>//
            v[0xF] = 1;
          }
        }

        sprite <<= 1;
      }
    }

    break;

  case 0xE000:
    switch(nn) {
    case 0x9E:
      if (keysPressed[x]) {
        pc+=2;
      }
      break;
    case 0xA1:
      if (!keysPressed[x]) {
        pc+=2;
      }
      break;
    }

  case 0xF000:
    switch (nn) {
    case 0x07:
      v[x] = delayTimer;
      break;

    case 0x0A:
    println("FX0A waiting for keypress");
      paused = true;
      waitingForKey = true;
      boolean kp = false;

      for (var i = 0; i < keysPressed.length; i++) {
        if (keysPressed[i] == true) {
          kp = true;
        }
      }

      if (kp) {
        paused = false;
        waitingForKey = false;
        v[x] = lastKey;
      } else {
        pc-=2;
      }
      break;

    case 0x15:
      delayTimer = v[x];
      break;

    case 0x18:
      soundTimer = v[x];
      break;

    case 0x1E:
      I += v[x];
      break;

    case 0x29:
      println("setting I to: " + v[x] + " from v" + x);
      I = v[x] * 5;
      println("I: " + I);
      break;

    case 0x33:
      memory[I] = byte(int (v[x] / 100));
      println ("I: 100s: " + memory[I]);
      memory[I + 1] = byte(int ((v[x] % 100) / 10));
      println ("I+1: 10s: " + memory[I+1]);
      memory[I + 2] = byte(int (v[x] % 10));
      println ("I+2: 1s: " + memory[I+2]);
      break;

    case 0x55:
      for (int i = 0; i <= x; i++ ) {
        memory[I + i] = byte(v[i]);
      }
      break;

    case 0x65:
      for (var i = 0; i <= x; i++) {
        v[i] = memory[I + i];
        println("setting v" + i + " to: " + memory[I+i]);
      }
      break;
    }
    break;

  default:
    break;
  }
}
