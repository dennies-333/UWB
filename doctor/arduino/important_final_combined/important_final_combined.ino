#include <Arduino.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
#include <Arduino_JSON.h>
#include <SPI.h>
#include "DW1000Ranging.h"
#include "WiFi.h"
#include <WiFiUdp.h>

// Replace with your network credentials
const char* ssid = "Gautham's Lap";
const char* password = "123456789";

// Create a sensor object
Adafruit_MPU6050 mpu;
float gyroX, gyroY, gyroZ;

//Gyroscope sensor deviation
float gyroXerror = 0.07;
float gyroYerror = 0.03;
float gyroZerror = 0.01;
const float movementThreshold = 10.0; // Adjust this threshold according to your requirements


// Connection pins for DW1000
const uint8_t PIN_SCK = 18;
const uint8_t PIN_MOSI = 23;
const uint8_t PIN_MISO = 19;
const uint8_t PIN_SS = 5;
const uint8_t PIN_RST = 16;
const uint8_t PIN_IRQ = 17;
 
const char* udpAddress = "192.168.137.116"; // Your UDP Server IP
const int udpPort = 9090;
boolean connected = false;
WiFiUDP udp;


// Init MPU6050
void initMPU() {
    if (!mpu.begin()) {
        Serial.println("Failed to find MPU6050 chip");
        while (1) {
            delay(10);
        }
    }
    Serial.println("MPU6050 Found!");
}

void setup() {
    Serial.begin(115200);
    initMPU();

    // Initialize SPI and DW1000
    SPI.begin(PIN_SCK, PIN_MISO, PIN_MOSI);
    DW1000Ranging.initCommunication(PIN_RST, PIN_SS, PIN_IRQ); // Reset, CS, IRQ pin
    DW1000Ranging.attachNewRange(newRange);
    DW1000Ranging.attachNewDevice(newDevice);
    DW1000Ranging.attachInactiveDevice(inactiveDevice);
    DW1000.enableDebounceClock();
    DW1000.enableLedBlinking();
    DW1000.setGPIOMode(MSGP3, LED_MODE);
    DW1000Ranging.startAsTag("7D:00:22:EA:82:60:3B:9C", DW1000.MODE_LONGDATA_RANGE_LOWPOWER);

    // Uncomment if you plan to use WiFi
    //connectToWiFi(ssid, password);
}



void loop() {
  DW1000Ranging.loop();
}

void newRange() {
    float projectedRange = DW1000Ranging.getDistantDevice()->getRange() * 2 / 5;
    projectedRange -= 0.18;
    String strData = String(DW1000Ranging.getDistantDevice()->getShortAddress(), HEX);
    strData += ", ";
    strData += String(projectedRange);
    Serial.println(strData);

    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    float gyroX_temp = g.gyro.x;
    if (abs(gyroX_temp) > gyroXerror) {
        gyroX += gyroX_temp / 50.00;
    }

    float gyroY_temp = g.gyro.y;
    if (abs(gyroY_temp) > gyroYerror) {
        gyroY += gyroY_temp / 70.00;
    }

    float gyroZ_temp = g.gyro.z;
    if (abs(gyroZ_temp) > gyroZerror) {
        gyroZ += gyroZ_temp / 90.00;
    }

    // Construct a string with the formatted data
    String dataString = String(gyroX) + "," + String(gyroY) + "," + String(gyroZ);


    // Print the data to the serial port
    Serial.println(dataString);
    
}


//void newRange() {
//    float projectedRange = DW1000Ranging.getDistantDevice()->getRange() * 2 / 5;
//    projectedRange -= 0.18;
//
//    // Get accelerometer data
//    sensors_event_t a, g, temp;
//    mpu.getEvent(&a, &g, &temp);
//
//    // Calculate total acceleration magnitude
//    float totalAcceleration = sqrt(a.acceleration.x * a.acceleration.x +
//                                    a.acceleration.y * a.acceleration.y +
//                                    a.acceleration.z * a.acceleration.z);
//
//    // Check if the tag is moving based on acceleration magnitude threshold
//    bool isMoving = totalAcceleration > movementThreshold;
//
//    // Send UWB data only if the tag is moving
//    if (isMoving) {
//        String uwbData = String(DW1000Ranging.getDistantDevice()->getShortAddress(), HEX);
//        uwbData += ", ";
//        uwbData += String(projectedRange);
//        Serial.println(uwbData);
//    }
//
//    // Process gyro data
//    float gyroX_temp = g.gyro.x;
//    if (abs(gyroX_temp) > gyroXerror) {
//        gyroX += gyroX_temp / 50.00;
//    }
//
//    float gyroY_temp = g.gyro.y;
//    if (abs(gyroY_temp) > gyroYerror) {
//        gyroY += gyroY_temp / 70.00;
//    }
//
//    float gyroZ_temp = g.gyro.z;
//    if (abs(gyroZ_temp) > gyroZerror) {
//        gyroZ += gyroZ_temp / 90.00;
//    }
//
//    // Construct a string with the formatted gyro data
//    String gyroDataString = String(gyroX) + "," + String(gyroY) + "," + String(gyroZ);
//
//    // Print gyro data to the serial port
//    Serial.println(gyroDataString);
//}

void newDevice(DW1000Device* device) {
    Serial.print("Ranging init; 1 device added! -> ");
    Serial.print(" short: ");
    Serial.println(device->getShortAddress(), HEX);
}

void inactiveDevice(DW1000Device* device) {
    Serial.print("Delete inactive device: ");
    Serial.println(device->getShortAddress(), HEX);
}

void WiFiEvent(WiFiEvent_t event) {
    switch (event) {
        case SYSTEM_EVENT_STA_GOT_IP:
            Serial.print("WiFi connected! IP address: ");
            Serial.println(WiFi.localIP());
            udp.begin(WiFi.localIP(), udpPort);
            connected = true;
            break;
        case SYSTEM_EVENT_STA_DISCONNECTED:
            Serial.println("WiFi lost connection");
            connected = false;
            break;
    }
}

void connectToWiFi(const char* ssid, const char* pwd) {
    Serial.println();
    Serial.println("Connecting to WiFi network: " + String(ssid));
    WiFi.disconnect(true);
    WiFi.onEvent(WiFiEvent);
    WiFi.begin(ssid, pwd);
    Serial.println("Waiting for WiFi connection...");
}
