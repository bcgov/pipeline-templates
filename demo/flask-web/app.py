from flask import Flask, json, render_template

app = Flask(__name__)

@app.route("/")
def subway():
    return render_template("index.html")
