from flask import Flask
import redis
import os

app = Flask(__name__)

# Connect to Redis
redis_host = os.environ.get('REDIS_HOST', 'redis')
redis_port = os.environ.get('REDIS_PORT', 6379)

try:
    r = redis.Redis(host=redis_host, port=int(redis_port))
except:
    r = None

@app.route('/')
def index():
    try:
        count = r.incr('hits')
        return f'''
        <html>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>Welcome to SravsDevOps App!</h1>
            <h2>This page has been visited {count} times</h2>
            <p>Running on Kubernetes with Jenkins CI/CD Pipeline</p>
        </body>
        </html>
        '''
    except:
        return '''
        <html>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
            <h1>Welcome to SravsDevOps App!</h1>
            <p>Running on Kubernetes</p>
        </body>
        </html>
        '''

@app.route('/health')
def health():
    return {'status': 'healthy'}, 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=False)
