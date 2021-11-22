import time
import redis
import platform
import socket
import re
import uuid
import json
import psutil
import logging

from flask import Flask, json, render_template

app = Flask(__name__)

cache = redis.Redis(host='redis', port=6379)

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
