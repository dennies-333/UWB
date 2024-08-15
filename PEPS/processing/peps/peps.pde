import processing.serial.*;

Serial myPort;
float distance;
String anchorName = "Closed"; 
boolean dataReceived = false;
float zoomFactor = 1;
color anchorColor = color(150);



void setup() {
  size(800, 600);
  String portName = "COM15"; 
  myPort = new Serial(this, portName, 115200);
  myPort.bufferUntil('\n');
}

void draw() {
  background(255);
  translate(width / 4, height / 2);
  scale(zoomFactor);

  
  stroke(0);
  fill(anchorColor);
  ellipse(0, 0, 10, 10); 
  fill(0);
  textAlign(CENTER);
  text(anchorName, 0, -15);

  
  if (dataReceived) {
    float distanceInPixels = map(distance, 0, 2000, 0, width);
    stroke(255, 0, 0);

    fill(255, 0, 0);
    ellipse(distanceInPixels, 0, 10, 10); 

    fill(0);
    textAlign(CENTER);
    text(distance + " cm", distanceInPixels, 15);
  }
}


void serialEvent(Serial myPort) {
  try {
    String inData = myPort.readStringUntil('\n');
    if (inData != null) {
      println("Received data: " + inData); 
      String[] data = trim(inData).split(",");
      if (data.length == 2) {
        anchorName = data[0];
        if (float(data[1]) <= 0) {
          distance = 0;
        } else {
          distance = float(data[1]) * 100;
        }
        dataReceived = true;
        
      
        if (distance <= 30) {
          anchorColor = color(0, 255, 0);
          anchorName = "Open";
        } else {
          anchorColor = color(150);
          anchorName = "Closed";
        }
      } else {
        println("Invalid data format: " + inData); 
      }
    }
  } catch (Exception e) {
    println("Error reading from serial port: " + e.getMessage());
  }
}


void keyPressed() {
  if (key == '+') {
    zoomFactor *= 1.1;
  } else if (key == '-') {
    zoomFactor /= 1.1;
  }
}
