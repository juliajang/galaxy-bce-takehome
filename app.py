from flask import Flask

app = Flask(__name__)


@app.route("/")
def index():
    return "Hello World!"

@app.route("/dummy")
def dummy():
    return "This is a dummy endpoint.", 200

# dummy health / readiness endpoints for k8s probes
@app.route("/health")
def health():
    return "ok", 200

@app.route("/ready")
def ready():
    return "ready", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)