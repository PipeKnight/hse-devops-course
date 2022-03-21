from flask import Flask
from flask import request
from datetime import datetime
app = Flask(__name__)
 
@app.route("/")
def hello():
    return "Date: " + str(datetime.now()) + 'Agent: ' + request.user_agent.string

if __name__ == "__main__":
    app.run()
