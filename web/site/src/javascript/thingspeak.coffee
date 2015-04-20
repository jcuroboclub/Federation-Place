# Created by AshGillman 20/4/15
_ = require 'underscore'
d3 = require 'd3'

THINGSPEAK_FIELDS = _.map(_.range(1, 9), (x) ->
  'field' + x
)

parseDateStr = d3.time.format.utc('%Y-%m-%dT%H:%M:%SZ').parse

exports.toNvLine = (ts) -> _.map(THINGSPEAK_FIELDS, (f) ->
  # [{"created_at":"YYYY-MM-DDTHH:mm:ssZ",
  #   "entry_id":X,
  #   "field1":"X",
  #   "field2":"X",
  #   ...,
  #   "field8":"X"}]
  # to
  # [{"key": "field1","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]},
  #  {"key": "field2","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]},
  #  ...,
  #  {"key": "field8","values": [{"x": "YYYY-MM-DDTHH:mm:ssZ", "y": X}, ... ]}]
  {
  'key': ts.channel[f]
  'values': _.map(ts.feeds, (d) ->
    {
    'x': parseDateStr(d.created_at)
    'y': d[f]
    }
  )
  }
)