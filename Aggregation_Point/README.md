# Aggregation point code

This is the code intended to run on the aggregation point. It requires an XBee
radio connected over a USB serial connection. It receives data from all the
sensors and then uploads it to the Internet. It returns acknowledgment messages
to the sensor nodes when each record is successfully uploaded.

## Technical Overview

A class ``AggregationPoint`` manages the main run loop. It:
  * Receives data from the XBee module.
  * "Depacketises" the incoming stream to separate out the partial messages from each individual sensor node.
  * Passes the raw strings to the ``SensorData`` class to be parsed.
  * Hands the ``SensorData`` object to the data store to the uploaded to the Internet. In this implementation, the data store is the class ``ThingSpeakStore``.

The ``ThingSpeakStore`` uses a queue of pending uploads that are processed by worker threads. In the event of failure to upload, each worker thread sleeps for some time and tries again repeatedly. In this way, transient network issues are handled. The number of worker threads grows dynamically as needed up to a maximum limit set in the source code.

## API keys

API keys for Thingspeak need to be placed in a file called "secrets.json".
Example format:

    {
        "thingspeak_keys": {
            "1":"write_API_key_for_sensor_1",
            "2":"write_API_key_for_sensor_2",
            "3":"write_API_key_for_sensor_3"
        }
    }
