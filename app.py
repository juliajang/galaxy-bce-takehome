from flask import Flask

app = Flask(__name__)


@app.route("/")
def index():
    return "Hello World!"

@app.route("/dummy")
def dummy():
    return "This is a dummy endpoint."


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)