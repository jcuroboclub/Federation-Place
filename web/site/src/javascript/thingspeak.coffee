# Created by AshGillman 20/4/15
$ = require 'jquery'
d3 = require 'd3'

TS_FIELDS = do ((n) -> ('field' + n) for n in [1...9])
TS_URL = "https://api.thingspeak.com/"
exports.UPDATE_SECS = 15

parseDateStr = d3.time.format.utc('%Y-%m-%dT%H:%M:%SZ').parse

# Function to convert thingspeak format
# [{"created_at":"YYYY-MM-DDTHH:mm:ssZ",
#   "entry_id":X,
#   "field1":"X",
#   "field2":"X",
#   ...,
#   "field8":"X"}]
# to nvd3 data format
# [{"key": "field1","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]},
#  {"key": "field2","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]},
#  ...,
#  {"key": "field8","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]}]
exports.toNv = (tsData) ->
  for f in TS_FIELDS
    key: (tsData.channel[f])
    values:
      (x: parseDateStr(d.created_at), y: parseFloat(d[f]) for d in tsData.feeds)

# Load ThingSpeak stream
exports.loadFeed = (channel, callback, n=100) ->
  $.getJSON TS_URL + "channels/#{channel}/feed.json?results=#{n}", callback