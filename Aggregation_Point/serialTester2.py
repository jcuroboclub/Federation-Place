from arduino_serial import ArduinoSerial

serialInterface = ArduinoSerial("/dev/ttyUSB0")

while True:
	reMsg = serialInterface.receiveMsg()
	if reMsg != "" and len(reMsg) > 10 :
		reMsg.strip()
		reMsg.rstrip("\n")
		reMsg.rstrip("\r")
		print(reMsg)
