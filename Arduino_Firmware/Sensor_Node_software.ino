/*
SENSOR NODE SOFTWARE

This software is intended to run on a Arduino-compatible Sparkfun Pro Micro 3.3V.

The hardware connections are as follows:

Buttons: (all are active high)
 - Happy_button = pin 15
 - Indifferent_button= pin 14
 - Sad_button= pin 16

LEDs associated with the buttons:
 - Green_light = A0
 - Yellow_light = A1
 - Red_light = A2

The HTU2ID sensor:
 - SDA = pin 2
 - SCL = pin 3

Hardware Connections for RGB LED (common cathode)
 - redPWM = pin 5
 - greenPWM = pin 9
 - bluePWM = pin 6
*/

// In DEBUG mode, status information is printed over the serial port.
#define DEBUG 1

// SENSOR ID. Each sensor must have a unique ID, which is used to determine which reading comes from which part of the building.
#define SENSOR_ID 1

// Time delay between sensor readings (in milliseconds)
#define SENSOR_PERIOD 30000

//DEFINE LIBRARIES
#include <SoftwareSerial.h>
#include <Wire.h> // The I2C library
#include "SparkFunHTU21D.h" // Sensor's library
#include "ButtonEvent.h"

//Global variables
HTU21D The_sensor;
float humid;
float temp;

//Pins
int LEDpins[] = {A0, A1, A2}; // Green, Yellow, Red
int PWM[] = {5, 9, 6}; // Red, Green, Blue
SoftwareSerial XBee(8, 7); // RX, TX

// Keep track of the status of the system using this enumeration
enum NodeStatus {
  StartingUp, // before first contact
  OK, // working normally
  LossOfRadioContact // Lost contact with the coordinator
} nodeStatus;

// Time of last radio contact
unsigned long last_contact = 0; // time from millis() of last contact with the coordinator

void setup() {
  // General Setup
  nodeStatus = StartingUp;
  
  // Turn on all the LEDs for testing
  ledRGB(255,255,255);
  digitalWrite(LEDpins[0], 1);
  digitalWrite(LEDpins[1], 1);
  digitalWrite(LEDpins[2], 1);

  //Configuring the Button Events
  ButtonEvent.addButton(14, //button pin (SAD)
                        onDown,  //onDown event function
                        onUp,   //onUp event function
                        onHold,//onHold event function
                        1000,  //hold time in milliseconds
                        onDouble, //onDouble event function
                        200); //double time interval

  ButtonEvent.addButton(15, //button pin (INDIFFERENT)
                        onDown,  //onDown event function
                        onUp,   //onUp event function
                        onHold,//onHold event function
                        1000,  //hold time in milliseconds
                        onDouble, //onDouble event function
                        200); //double time interval

  ButtonEvent.addButton(16, //button pin (Happy)
                        onDown,  //onDown event function
                        onUp,   //onUp event function
                        onHold,//onHold event function
                        1000,  //hold time in milliseconds
                        onDouble, //onDouble event function
                        200); //double time interval

  // Initialising the pin for both normal LED and RGB LED
  for (int LED_no = 0; LED_no < 3; LED_no++)
  {
    pinMode(LEDpins[LED_no], OUTPUT);
    pinMode(PWM[LED_no], OUTPUT);
  }

  // Initialise the serial ports (for both Xbees and the USB serial)
  XBee.begin(9600); // Initialise the XBee SoftwareSerial
  Serial.begin(9600);
  
  // Wait a bit, and then turn off the LEDs
  delay(750);
  ledRGB(0, 0, 0);
  digitalWrite(LEDpins[0], 0);
  digitalWrite(LEDpins[1], 0);
  digitalWrite(LEDpins[2], 0);
}

void loop() {
  // Obtain the sensor's data
  static unsigned long last_sensor_read = 0;
  unsigned long current_time = millis();
  if (current_time < last_sensor_read) {
    // Every ~ 50 days the time wraps around. Just reset the clock.
    last_sensor_read = 0;
  }
  if ((current_time - last_sensor_read) >= SENSOR_PERIOD) {
    readSensors();
    last_sensor_read = current_time;
  }
  
  // Check that we're still in radio communication with the coordinator
  checkRadio();
 
  // Events for the buttons
  ButtonEvent.loop();
  
  // Update the status LED
  switch (nodeStatus) {
    case StartingUp:
      // Fast blinking green led
      if ((millis() / 100) % 2 == 0) {
        ledRGB(0, 128, 0);
      } else {
        ledRGB(0, 0, 0);
      }
      break;
    case OK:
      // Solid green LED
      ledRGB(0, 40, 0);
      break;
    case LossOfRadioContact:
      // Blinking red LED
      if ((millis() / 200) % 2 == 0) {
        ledRGB(255, 0, 0);
      } else {
        ledRGB(0, 0, 0);
      } 
      break;
  }
  
#if DEBUG
  static unsigned long last_print = 0;
  if ((millis() - last_print) > 1000) {
    last_print = millis();
    switch (nodeStatus) {
      case StartingUp:
        Serial.println("Starting up");
        break;
      case OK:
        Serial.println("Status OK");
        break;
      case LossOfRadioContact:
        Serial.println("Loss of radio contact");
        break;
    }
  }  
#endif
    
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// SENSORS
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void readSensors() {
  // Read the temp and humidity from the sensors
  humid = The_sensor.readHumidity();
  temp = The_sensor.readTemperature();
  
  // Output in CSV format
  // SensorID,temp,humidity
  XBee.print(SENSOR_ID);
  XBee.print(",");
  XBee.print(temp);
  XBee.print(",");
  XBee.print(humid);
  XBee.println("");

  if (DEBUG) {
    Serial.print("Sensor ");
    Serial.print(SENSOR_ID);
    Serial.print(" Temperature:");
    Serial.print(temp );
    Serial.print("C ");
    Serial.print(" Humidity:");
    Serial.print(humid );
    Serial.println("%");
  }
}

// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// RADIO
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void checkRadio() 
{
  // The coordinator will send us periodic packets to indicate that we're still in radio contact.
  if (XBee.available()) {
    char msg = XBee.read();
    if (msg == '1') {
      // Character '1' indicates an OK status from the coordinator.
      last_contact = millis();
    }
  }

  // Check how long it has been since last radio contact
  unsigned long current_time = millis();
  if (current_time < last_contact) {
    // Every ~ 50 days the time wraps around. Just reset the clock.
    last_contact = 0;
  } else if ((current_time - last_contact) > 10000) {
    // More than 30 seconds have passed since last radio contact
    nodeStatus = LossOfRadioContact;
  }
}


// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// ON BUTTONS EVENT
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

void onDown(ButtonInformation* Sender) {
  Serial.print("Button (pin:");
  Serial.print(Sender->pin);
  Serial.println(") down!");

  if (Sender->pin == 14) { // Indifferent
    digitalWrite(LEDpins[1], HIGH);
    XBee.println("100" );
    delay(1000);
    digitalWrite(LEDpins[1], LOW);

  }

  else if (Sender->pin == 15) { //Happy
    digitalWrite(LEDpins[0], HIGH);
    XBee.println("200" );
    delay(1000);
    digitalWrite(LEDpins[0], LOW);

  }

  else if (Sender->pin == 16) { //SAD
    digitalWrite(LEDpins[2], HIGH);
    XBee.println("300" );
    delay(1000);
    digitalWrite(LEDpins[2], LOW);
  }
}

void onUp(ButtonInformation* Sender) {
}

void onHold(ButtonInformation* Sender) {
  Serial.print("Button (pin:");
  Serial.print(Sender->pin);
  Serial.print(") hold for ");
  Serial.print(Sender->holdMillis);
  Serial.println("ms!");
}

void onDouble(ButtonInformation* Sender) {
  Serial.print("Button (pin:");
  Serial.print(Sender->pin);
  Serial.print(") double click in ");
  Serial.print(Sender->doubleMillis);
  Serial.println("ms!");
}


// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
// RGB LED.
// Takes an input of the RGB PWM ratio (from 1-255)
// =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
void ledRGB (int red, int green, int blue) {
  analogWrite(PWM[0], red);
  analogWrite(PWM[1], green);
  analogWrite(PWM[2], blue);
}

