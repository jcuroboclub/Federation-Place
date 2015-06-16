"""
"""
import serial

class ArduinoSerial:
    def __init__(self, port):
        self.port = serial.Serial(port, baudrate=9600, timeout=4.0)

    def sendMsg(self, message):
        self.port.write("" + message)

    def receiveMsg(self):
        return self.port.readline()
