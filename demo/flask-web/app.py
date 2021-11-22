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

companies = [{"id": 1, "name": "Company One"},
             {"id": 2, "name": "Company Two"}]

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


@app.route("/getinfo", methods=['GET'])
def getSystemInfo():
    count = get_hit_count()
    try:
        info = {}
        info['hits'] = '{}'.format(count)
        info['platform'] = platform.system()
        info['platform-release'] = platform.release()
        info['platform-version'] = platform.version()
        info['architecture'] = platform.machine()
        info['hostname'] = socket.gethostname()
        info['ip-address'] = socket.gethostbyname(socket.gethostname())
        info['mac-address'] = ':'.join(re.findall('..',
                                       '%012x' % uuid.getnode()))
        info['processor'] = platform.processor()
        info['ram'] = str(
            round(psutil.virtual_memory().total / (1024.0 ** 3)))+" GB"
        return json.dumps(info)
    except Exception as e:
        logging.exception(e)


@app.route('/companies', methods=['GET'])
def get_companies():
  return json.dumps(companies)


@app.route('/hits')
def hello():
    count = get_hit_count()
    return 'web1: {} hits.\n'.format(count)
