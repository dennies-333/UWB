#include <SPI.h>
#include "DW1000Ranging.h"
#include "DW1000.h"

// leftmost two bytes below will become the "short address"
char anchor_addr[] = "DD:CC:5B:D5:A9:9A:E2:9C"; //#4

// Initial Antenna Delay setting
uint16_t Adelay = 16540;

//makerfabs
#define SPI_SCK 18
#define SPI_MISO 19
#define SPI_MOSI 23
#define DW_CS 4

// connection pins
const uint8_t PIN_RST = 27; // reset pin
const uint8_t PIN_IRQ = 34; // irq pin
const uint8_t PIN_SS = 4;

// Kalman Filter variables
float Q = 0.022; // process noise covariance
float R = 0.617; // measurement noise covariance
float P = 1;     // estimated error covariance
float X = 0;     // value

void setup()
{
  Serial.begin(115200);
  delay(1000); // wait for serial monitor to connect
  Serial.println("Anchor configuration and start");

  // init the configuration
  SPI.begin(SPI_SCK, SPI_MISO, SPI_MOSI);
  DW1000Ranging.initCommunication(PIN_RST, PIN_SS, PIN_IRQ); // Reset, CS, IRQ pin

  // set initial antenna delay for anchors only. Tag is default (16384)
  DW1000.setAntennaDelay(Adelay);
  DW1000Ranging.useRangeFilter(true);

  DW1000Ranging.attachNewRange(newRange);
  DW1000Ranging.attachNewDevice(newDevice);
  DW1000Ranging.attachInactiveDevice(inactiveDevice);

  // start the module as an anchor, do not assign random short address
  DW1000Ranging.startAsAnchor(anchor_addr, DW1000.MODE_LONGDATA_RANGE_LOWPOWER, false);
}

void loop()
{
  DW1000Ranging.loop();
}

void newRange()
{
  Serial.print(DW1000Ranging.getDistantDevice()->getShortAddress(), HEX);
  Serial.print(", ");

  // Measurement from DW1000
  float measurement = DW1000Ranging.getDistantDevice()->getRange();

  // First Path Detection
  uint32_t firstPath = DW1000.getFirstPathPower();
  uint32_t receiveTime = DW1000.getReceiveTimestamp();
  uint32_t timeOfFlight = receiveTime - firstPath;

  float distance = timeOfFlight * TIME_RES; // TIME_RES - Time resolution of the DW1000, typically 15.65 ps

  // Apply Kalman Filter (if needed) after multipath reduction
  float filteredDistance = applyKalmanFilter(distance);

  // Output filtered distance
  Serial.println(filteredDistance);
}

float applyKalmanFilter(float measurement)
{
  // Apply Kalman Filter
  float prior_P = P + Q; // Prediction
  float K = prior_P / (prior_P + R); // Kalman gain
  X = X + K * (measurement - X); // Update estimate
  P = (1 - K) * prior_P; // Update error covariance

  return X;
}

void newDevice(DW1000Device *device)
{
  Serial.print("Device added: ");
  Serial.println(device->getShortAddress(), HEX);
}

void inactiveDevice(DW1000Device *device)
{
  Serial.print("Delete inactive device: ");
  Serial.println(device->getShortAddress(), HEX);
}
