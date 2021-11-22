
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

@app.route("/")
def subway():
    return render_template("index.html")
