#!/usr/bin/env python3

# Setup needed for a stock element14 Beaglebone:
# Run as root:
#     apt-get install python3 python3-pip
#     pip-3.2 install pyserial xbee requests

import re
import json
import requests
import time
from glob import glob
from queue import Queue
from collections import defaultdict
from pprint import pprint
from serial import Serial
from xbee import ZigBee

######################################################################

# Data from all XBee clients is intermixed. Need to separate incoming character
# data by source address.
class Depacketiser:
    """Unpacks newline-delimited strings from an intermixed stream of multiple sources."""

    # Constructor
    def __init__(self, callback):
        self.partial_msgs = defaultdict(str)  # Partial messages are stored as plain strings in a dictionary
        self.callback = callback              # When a complete message arrives, run this callback.

    # Feed in data
    def feed(self, source, message):
        # Append the new data to the old, and then detect newlines.
        messages = (self.partial_msgs[source] + message.decode('UTF-8')).split("\r\n")

        # Run the callback on all complete messages
        for m in messages[0:-1]:
            self.callback(source, m);

        # Save the current incomplete line
        self.partial_msgs[source] = messages[-1]

######################################################################

class DataStore:
    """Uploads sensor data to the Internet."""

    # Constructor
    def __init__(self, secrets):
        self.secrets = secrets

    # Feed in sensor data
    def sensor(self, sensorID, temperature, humidity):
        print("Sensor %s:\tTemp=%s C\tHumidity=%s%%" % (sensorID, temperature, humidity))

        # Upload to Thingspeak
        return self._upload(sensorID, {'field1': temperature, 'field2': humidity});

    # Feed in comfort data
    comfort_mapping = {'A': 3, 'B': 2, 'C': 3}
    def comfort(self, sensorID, comfort):
        print("Sensor %s:\tComfort=%s" % (sensorID, comfort))

        # Upload to Thingspeak
        return self._upload(sensorID, {'field3': comfort_mapping[comfort]})

    # Private method to upload to the Internet
    def _upload(self, sensorID, params):
        params['api_key'] = self.secrets['thingspeak_keys'][sensorID]
        for i in range(0, 3): # try 3 times
            try:
                r = requests.get("https://api.thingspeak.com/update", params=params)
                if r.status_code == 200 and r.text != '0':
                    return True
                else:
                    print("Warning: Failed to upload. HTTP status=%i; Thingspeak status=%s" % (r.status_code, r.text))
            except Exception as e:
                print("Warning: Failed to upload:", e)
                # Wait a moment and try again
                time.sleep(0.5) # seconds

        return False

######################################################################

class AggregationPoint:
    """Uploads data from an XBee network of sensor nodes."""

    # Constructor
    def __init__(self, datastore, serial_dev, baud=9600):
        self.datastore = datastore

        # Initialise the serial port
        self.serial = Serial(serial_dev, baud)
        print("Listening on", serial_dev, "at", baud, "baud.")

        # Set up the XBee wrapper. The callback runs in another thread, so
        # pass messages through a Queue object for thread safety.
        self.xbee_queue = Queue()
        self.xbee = ZigBee(self.serial, escaped=True, callback=self.xbee_queue.put)

        # Use a Depacketiser to unpack messages
        self.depacketiser = Depacketiser(self.parse)

    # Execute the main loop
    def join(self):
        """Runs the aggregation point main loop. Does not return."""

        while True:
            try:
                # Receive from the XBee
                data = self.xbee_queue.get(block=True)

                # Apparently there are two types of RX packet that the XBee could send.
                if (data['id'] == 'rx') or (data['id'] == 'rx_explicit'):
                    # Parse the stream of intermixed senders into messages
                    self.depacketiser.feed(data['source_addr_long'], data['rf_data'])
            except KeyboardInterrupt as e:
                raise e
            except Exception as e:
                time.sleep(0.5)
                print("Warning: Unhandled exception:", e)

    sensor_re = re.compile('^(\d+),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)$')
    comfort_re = re.compile('^(\d+),(A|B|C)$')
    def parse(self, msg_source, msg):
        """Parse a complete message from a sensor node."""

        # Parse the message as sensor readings
        as_sensor = self.sensor_re.match(msg)
        if as_sensor != None:
            # Log it to the Internet
            success = self.datastore.sensor(* as_sensor.groups())
            # Send the Arduino an acknowledgement
            if success: self.send_acknowledgement(msg_source)
            return

        # Parse the message as a comfort value
        as_comfort = self.comfort_re.match(msg)
        if as_comfort != None:
            # Log it to the Internet
            success = self.datastore.comfort(* as_comfort.groups())
            # Send the Arduino an acknowledgement
            if success: self.send_acknowledgement(msg_source)
            return

        # Unknown message
        print("Warning: Received an unknown message '" + msg + "' from node", msg_source)

    # Send an acknowledgment message to the sensor node when its data has been
    # successfully uploaded
    def send_acknowledgement(self, destination_address):
        data = b'1' # ASCII '1' is the 'success' acknowledgement
        self.xbee.tx(frame_id=b'\x00', # no response requested
                     dest_addr=b'\xFF\xFE', # use 64-bit addressing
                     dest_addr_long=destination_address,
                     data=data)

    # Cleanup
    def close(self):
        self.xbee.close()
        self.serial.close()

######################################################################

def find_port():
    ports = glob("/dev/ttyUSB*")
    if len(ports) == 0:
        raise IOError("No serial ports were detected that match /dev/ttyUSB*")
    return ports[0]

def load_secrets():
    with open("secrets.json", 'rt') as f:
        return json.load(f)

if __name__ == "__main__":
    port = find_port()
    ds = DataStore(load_secrets())

    aggPoint = AggregationPoint(datastore=ds, serial_dev=port)
    aggPoint.join()
