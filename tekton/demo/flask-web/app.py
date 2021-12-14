from flask import Flask, json, render_template
import requests

app = Flask(__name__)

@app.route("/")
def index():
    url = "https://api.kanye.rest"
    data = requests.get(url)
    response = data.json()
    quote = response["quote"]
    return render_template("index.html", quote=quote)
