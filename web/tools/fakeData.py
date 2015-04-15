__author__ = 'Ash'
import numpy as np
import time
import http.client, urllib.parse
from pprint import pprint

API_KEY = "LZ3F1HB2ORCXOA9O"
n_spine = 8
fields = list(map(lambda x: "field"+x, map(str, range(1, 9))))
headers = {"Content-type": "application/x-www-form-urlencoded",
           "Accept": "text/plain"}

def main():
    period = np.arange(0, 2, 2/n_spine) * np.pi
    while True:
        for dt in period:
            sensors = np.cos(period+dt)*5 + 25
            data = dict(zip(fields, sensors))
            data["key"] = API_KEY
            params = urllib.parse.urlencode(data)
            conn = http.client.HTTPConnection("api.thingspeak.com:80")
            conn.request("POST", "/update", params, headers)
            response = conn.getresponse()
            print(response.status, response.reason)
            #data = response.read()
            conn.close()
            time.sleep(15)



if __name__ == "__main__":
    main()