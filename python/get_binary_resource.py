#!/usr/bin/python3

import subprocess
import logging
import json
import os
import re
import sys
import argparse
import base64

handler = logging.StreamHandler(sys.stdout)
handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.addHandler(handler)

def parse_args():
    parser = argparse.ArgumentParser(usage='Retrieve a Binary resource for one or more resources')
    parser.add_argument('-v','--verbose', help='Enable verbose logging', action='count', default=0)
    parser.add_argument('-e', '--endpoint', help='Endpoint to make requests (e.g. api.dev.xyz.commure.com', default=os.getenv('AUTH_ENDPOINT'), action='store')
    parser.add_argument('-a', '--auth', help='Basic Auth username/password', default=os.getenv('BASIC_AUTH_USERNAME_PASSWORD'), action='store')
    return parser.parse_args()


def exec_cmd(cmd, cwd=None, **kwargs):
    proc = subprocess.Popen(cmd, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd, **kwargs)
    (out, err) = proc.communicate()
    return json.loads(out)

#def get_token(BASIC_AUTH_USERNAME_PASSWORD, AUTH_ENDPOINT):
#    curl_argv = [ 'curl', '-sSL', '-k', '--data', 'grant_type=client_credentials',
#                  '-H', "Authorization: Basic " + BASIC_AUTH_USERNAME_PASSWORD,
#                  '-H', "Content-Type: application/x-www-form-urlencoded",
#                  AUTH_ENDPOINT ]
#    curl = subprocess.Popen(curl_argv, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#    (out, err) = curl.communicate()
#    if err:
#        print(f"error: {err}")
#    return json.loads(out)['access_token']

def get_token():
    curl_argv = [ 'curl', '-sSL', '-k', '--data', 'grant_type=client_credentials',
                  '-H', "Authorization: Basic " + BASIC_AUTH_USERNAME_PASSWORD,
                  '-H', "Content-Type: application/x-www-form-urlencoded",
                  AUTH_ENDPOINT ]
    out = exec_cmd(curl_argv)
    return out.get('access_token')

#def get_token(BASIC_AUTH_USERNAME_PASSWORD, AUTH_ENDPOINT):
#    curl_argv = [ 'curl', '-sSL', '-k',
#                  '-H', "Authorization: Bearer " + AUTH_TOKEN,
#                  AUTH_ENDPOINT ]
#    curl = subprocess.Popen(curl_argv, stdin=None, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
#    (out, err) = curl.communicate()
#    return json.loads(out)

# id - hl7-storage.hl7-receiver-6789.0.1595427485632-74609
#   - strip out the 'hl7-storage' and create a .hl7 file
# data (base64 encoded)

# curl -s -H 'Authorization: Bearer Sec-GhWlp1p8zyzER4kvvSiHkoCwtdw-ceS' https://api.dev.tju.commure.com/api/v1/r4/Binary/hl7-storage.hl7-receiver-6789.0.1595427485632-74609 | jq '.data' -r | base64 -d

# 1. Get Auth Token to query resources (Binary especially)
# 2. Make subsequent call to retrieve all resources that messages should be downloaded
args = parse_args()
AUTH_ENDPOINT = f"https://{args.endpoint}/auth/token"
ENDPOINT = f"https://{args.endpoint}/api/v1/r4"
BASIC_AUTH_USERNAME_PASSWORD = args.auth

token = get_token()
if not token:
    # no Bearer token retrieved
    print(f"uh oh and error occurred")
    pass
else:
    # call resource, and get link to Binary resource
    print(f"token: {token}")
    pass

#base64.decode(str)
