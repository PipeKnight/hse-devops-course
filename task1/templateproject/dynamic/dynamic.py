# pylint: skip-file
from datetime import datetime

from flask import Flask
from flask import request

app = Flask(__name__)

@app.route('/')
def hello():
    return f'Date: {datetime.now()}\nAgent: {request.user_agent.string}'


if __name__ == '__main__':
    app.run()
