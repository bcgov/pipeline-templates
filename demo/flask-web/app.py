import time
import redis
import platform
import socket
import re
import uuid
import json
import psutil
import logging
import requests

from flask import Flask, json, render_template, make_response

app = Flask(__name__)

cache = redis.Redis(host='redis', port=6379)

## function that gets the random quote
def get_quote():
    ## making the get request
    response = requests.get("https://quote-garden.herokuapp.com/api/v3/quotes/random")
    if response.status_code == 200:
        ## extracting the core data
	    json_data = response.json()
	    data = json_data['data']
    return(data[0]['quoteText'])

def get_hit_count():
    retries = 5
    while True:
        try:
            return cache.incr('hits')
        except redis.exceptions.ConnectionError as exc:
            if retries == 0:
                raise exc
            retries -= 1
            time.sleep(0.5)


@app.route("/")
def subway():
    return render_template("index.html")

@app.route('/hits')
def hello():
    count = get_hit_count()
    return 'web1: {} hits.\n'.format(count)

@app.route('/quote')
def quoter():
    quote = get_quote()
    print(quote)
    return quote + '\n'
