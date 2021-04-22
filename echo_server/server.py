from time import sleep

from flask import Flask, request, Response
from werkzeug.routing import Rule

app = Flask(__name__)
app.url_map.add(Rule('/', endpoint='index'))


@app.endpoint('index')
def echo():
    code = int(request.headers.get('x-response-code', 200))
    timeout = float(request.headers.get('x-sleep', 0.0))
    if timeout:
        sleep(timeout)

    # res_headers = dict(request.headers.items())
    res_headers = list(request.headers.items())
    res_headers.append(('X-Echo-Query', request.query_string.decode('utf-8')))
    # res_headers['X-Echo-Query'] = request.query_string
    return Response(response=request.data,
                    status=code,
                    headers=res_headers,
                    mimetype=request.mimetype,
                    content_type=request.content_type,
                    direct_passthrough=True)
