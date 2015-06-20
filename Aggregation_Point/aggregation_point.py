#!/usr/bin/env python3

# Setup needed for a stock element14 Beaglebone:
# Run as root:
#     apt-get install python3 python3-pip
#     pip-3.2 install pyserial xbee requests

import re
import json
import requests
import time
from binascii import hexlify
from glob import glob
from queue import Queue
from collections import defaultdict
from pprint import pprint
from serial import Serial
from threading import Thread
from xbee import ZigBee

######################################################################

class ParseError(Exception): pass

class SensorData:
    """Represents sensor data."""

    # There are (at present) 2 different types of messages that can be sent. We
    # detect which is which by using a restrictive regular expression.
    msg_formats = {
        'sensor': re.compile('^(\d+),(\d+(?:\.\d+)?),(\d+(?:\.\d+)?)$'),
        'comfort': re.compile('^(\d+),(A|B|C)$')
    }
    def __init__(self, raw_message):
        self.on_upload = None  # Callback to run when data is successfully uploaded

        # Parse the message against the known formats
        for format in self.msg_formats:
            matches = self.msg_formats[format].match(raw_message)
            if matches != None:
                # Success.
                self.type = format
                self.data = matches.groups()
                return

        # Unknown message type
        raise ParseError("Received an unknown message '%s'" % raw_message)

    pp_formats = {
        'sensor': 'SensorID=%s\tTemperature=%s C\tHumidity=%s%%',
        'comfort': 'SensorID=%s\tComfort=%s'
    }
    def to_string(self):
        return self.pp_formats[self.type] % self.data


######################################################################

class ThingSpeakStore:
    """Uploads sensor data to Thingspeak."""

    # Constructor
    def __init__(self, secrets, num_workers=1, max_workers=30):
        self.secrets = secrets

        # Use a large number of workers because they will block for long periods
        # of time in the case that ThingSpeak rejects updates.
        self.max_workers = max_workers
        self.queue = Queue() # Place data in the queue waiting to be uploaded.

        # Start worker threads
        self.threads = [self._new_worker() for i in range(0, num_workers)]

    # Feed in data to be uploaded
    def upload(self, data):
        assert(type(data) == SensorData)
        self.queue.put(data)
        # Add more workers if the queue of unuploaded messages is too long
        if self.queue.qsize() > 2 and len(self.threads) <= self.max_workers:
            self.threads.append(self._new_worker())
            print("ThingSpeakStore: Added new worker. There are now", len(self.threads), "workers.")

    # Worker threads (running in the background)
    comfort_mapping = {'A': 3, 'B': 2, 'C': 1}
    def worker(self):
        while True:
            try:
                # Receive data to upload
                d = self.queue.get(block=True)

                # Upload it
                success = False
                if d.type == 'sensor':
                    (sensorID, temperature, humidity) = d.data
                    success = self._upload(sensorID, {'field1': temperature, 'field2': humidity});
                elif d.type == 'comfort':
                    (sensorID, comfort) = d.data
                    success = self._upload(sensorID, {'field3': self.comfort_mapping[comfort]})

                if not success:
                    print("Warning: *** Discarded data because upload failed.")

                # Run the data object's on_upload callback if we were successful
                if success and d.on_upload != None:
                    d.on_upload()
            except Exception as E:
                time.sleep(0.5)
                print("Warning: Suppressed unhandled exception in worker:", e)

    # Private method to create a new worker thread
    def _new_worker(self):
        t = Thread(target=self.worker)
        t.daemon = True
        t.start()
        return t

    # Private method to upload to the Internet
    def _upload(self, sensorID, params):
        params['api_key'] = self.secrets['thingspeak_keys'][sensorID]
        for i in range(0, 5): # try 5 times
            try:
                r = requests.get("https://api.thingspeak.com/update", params=params)
                if r.status_code == 200 and r.text != '0':
                    return True
                else:
                    pass
                    # Commented out because these happen all the time!
                    #print("Warning: Failed to upload. HTTP status=%i; Thingspeak status=%s" % (r.status_code, r.text))
            except Exception as e:
                print("Warning: Failed to upload:", e)

            # Wait a moment and try again
            time.sleep(5) # seconds

        return False

######################################################################

class AggregationPoint:
    """Receives and parses data from an XBee network of sensor nodes."""

    # Constructor
    def __init__(self, datastore, serial_dev, baud=9600):
        self.datastore = datastore

        # Initialise the serial port
        self.serial = Serial(serial_dev, baud)
        print("Listening on", serial_dev, "at", baud, "baud.")

        # XBee messages arrive in an intermixed stream from multiple sources.
        # Use a dictionary that is keyed on the radio MAC address to depacketise
        # this stream.
        self.partial_msgs = defaultdict(str)

        # Set up the XBee wrapper. The callback runs in another thread, so
        # pass messages through a Queue object for thread safety.
        self.xbee_queue = Queue()
        self.xbee = ZigBee(self.serial, escaped=True, callback=self.xbee_queue.put)


    # Execute the main loop
    def join(self):
        """Runs the aggregation point main loop. Does not return."""

        while True:
            try:
                # Receive from the XBee
                data = self.xbee_queue.get(block=True)

                # If it's a "tx" frame in the queue, then we need to send it out.
                if (data['id'] == 'tx'):
                    data.pop('id')
                    self.xbee.send('tx', **data)

                # If it was an "rx" frame, then we received it from the XBee.
                # Apparently there are two types of RX packet that the XBee could send.
                elif (data['id'] == 'rx') or (data['id'] == 'rx_explicit'):
                    # Parse the stream of intermixed senders into messages
                    self.depacketise(data['source_addr_long'], data['rf_data'])
            except KeyboardInterrupt as e:
                raise e
            except Exception as e:
                time.sleep(0.5)
                print("Warning: Suppressed unhandled exception:", e)

    def depacketise(self, source, message):
        """Unpack newline-delimited strings from an intermixed stream with multiple sources."""
        # Append the new data to the old, and then detect newlines.
        messages = (self.partial_msgs[source] + message.decode('UTF-8')).split("\r\n")

        # When a complete message has arrived, parse it
        for m in messages[0:-1]:
            self.parse(source, m)

        # Save the current incomplete line
        self.partial_msgs[source] = messages[-1]

    def parse(self, msg_source, msg):
        """Parse a complete message from a sensor node."""

        # Parse the message
        try:
            data = SensorData(msg)
        except ParseError as e:
            print(e, "(from node %s)" % hexlify(source_address).decode('utf-8').upper())
            return

        # Print the data
        print(data.to_string())

        # Register the on-upload callback
        data.on_upload = lambda: self.send_acknowledgement(msg_source)

        # Give to the data store
        self.datastore.upload(data)

    # Send an acknowledgment message to the sensor node when its data has been
    # successfully uploaded.
    def send_acknowledgement(self, destination_address):
        # This is run in a background thread! It cannot interact with the XBee
        # hardware directly, and must use the xbee_queue to communicate with the
        # main thread.

        self.xbee_queue.put({
            'id': 'tx',
            'frame_id': b'\x00', # no response requested
            'dest_addr': b'\xFF\xFE', # use 64-bit addressing
            'dest_addr_long': destination_address,
            'data': b'1' # ASCII '1' is the 'success' acknowledgement
        })

    # Cleanup
    def close(self):
        self.xbee.close()
        self.serial.close()

######################################################################

# Start-up code:

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
    ds = ThingSpeakStore(load_secrets())

    aggPoint = AggregationPoint(datastore=ds, serial_dev=port)
    aggPoint.join()
