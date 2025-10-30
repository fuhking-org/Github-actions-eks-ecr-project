from flask import Flask, render_template_string
import redis
import os

app = Flask(__name__)

REDIS_HOST = os.environ.get('REDIS_HOST', 'redis-service') # Kubernetes service name
REDIS_PORT = int(os.environ.get('REDIS_PORT', 6379))

# Attempt to connect to Redis
try:
    r = redis.Redis(host=REDIS_HOST, port=REDIS_PORT, db=0, socket_connect_timeout=2)
    r.ping()
    print(f"Successfully connected to Redis at {REDIS_HOST}:{REDIS_PORT}")
except redis.exceptions.ConnectionError as e:
    print(f"Could not connect to Redis at {REDIS_HOST}:{REDIS_PORT}: {e}")
    r = None # Set r to None if connection fails

@app.route('/')
def hello():
    if r:
        try:
            count = r.incr('visits')
            message = f"Hello from Flask! I have been visited {count} times."
        except Exception as e:
            message = f"Hello from Flask! Could not increment visit count: {e}"
    else:
        message = "Hello from Flask! Redis is not available."
    
    return render_template_string(
        """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Flask Microservice</title>
            <style>
                body { font-family: Arial, sans-serif; background-color: #f4f4f4; color: #333; margin: 50px; }
                .container { background-color: #fff; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                h1 { color: #0056b3; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>{{ message }}</h1>
                <p>Environment variable REDIS_HOST: {{ redis_host }}</p>
                <p>Environment variable REDIS_PORT: {{ redis_port }}</p>
            </div>
        </body>
        </html>
        """,
        message=message,
        redis_host=REDIS_HOST,
        redis_port=REDIS_PORT
    )

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)