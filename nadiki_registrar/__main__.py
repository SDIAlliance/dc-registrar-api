#!/usr/bin/env python3
import connexion
from nadiki_registrar import encoder
import os
from dotenv import load_dotenv
load_dotenv()  # This loads variables from .env into the environment

AUTH_USERNAME = os.getenv('AUTH_USER')
AUTH_PASSWORD = os.getenv('AUTH_PASSWORD')

PASSWD = { AUTH_USERNAME: AUTH_PASSWORD } if AUTH_USERNAME and AUTH_PASSWORD else {}

# this function is registered via the openapi.yaml file
# components:
#   securitySchemes:
#     basic:
#       type: http
#       scheme: basic
#       x-basicInfoFunc: app.basic_auth # --> this is the reference to this function
def basic_auth(username, password):
    if PASSWD.get(username) == password:
        return {"sub": username}
    # optional: raise exception for custom error response
    return None

def main():
    app = connexion.App(__name__, specification_dir='./openapi/')
    app.app.json_encoder = encoder.JSONEncoder
    app.add_api('openapi.yaml',
                arguments={'title': 'Facility Registry API'},
                pythonic_params=True)

    #app.run(port=8080)
    return app


if __name__ == '__main__':
    main().run(port=8080)
