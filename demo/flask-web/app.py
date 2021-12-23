from flask import Flask, render_template
import requests

app = Flask(__name__)

@app.route("/")
def index():
    url = "https://api.quotable.io/random"
    data = requests.get(url)
    response = data.json()
    quote = response["content"]
    author = response["author"]
    return render_template("index.html", quote=quote, author=author)

if __name__ == "__main__":
    app.run()
