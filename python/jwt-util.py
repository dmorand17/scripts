from jose import jwt
from cryptography import x509
from cryptography.x509.oid import NameOID
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives import serialization
import datetime
import sys 
import base64
import hashlib
import binascii
import argparse
import json

def parse_args():
    parser = argparse.ArgumentParser(description='Build JWT token')
    parser.add_argument('-v','--verbose', help='Enable verbose logging', action='store_true')
    parser.add_argument('--private-key', help='RSA Private Key', required=True, action='store')
    parser.add_argument('--public-key', help='RSA Public Key', required=True, action='store')
    parser.add_argument('--public-key-der', help='Public Cert .der file', required=True, action='store')
    return parser.parse_args()

def getThumbprintFromHashLib():
    ###
    #  hashlib library
    ###
    filename = "/home/dougie/onedrive/orion/security/jwt/cert.der"
    hash_object = hashlib.sha1(open(filename,"rb").read())
    fingerprint = hash_object.hexdigest()
    print("SHA1: {}".format(fingerprint))

    fingerprint_enc = base64.b64encode(fingerprint.encode())
    print("SHA1 (encoded wso2): {}".format(fingerprint_enc.decode('utf-8')))

    #    base64url-encoded SHA-1 thumbprint (a.k.a. digest) of the DER encoding of an X.509 certificate
    fingerprint_bytes_enc = base64.urlsafe_b64encode(hash_object.digest())
    print("SHA1 (encoded): {}".format(fingerprint_bytes_enc.decode('utf-8').rstrip('=')))
    #print("SHA1 (encoded)",fingerprint_bytes_enc.decode('utf-8'))

    return fingerprint_enc
    ###
    # END hashlib library
    ###

def getThumbprintFromx509():
    ###
    #  cryptography library
    ###
    filename = "/home/dougie/onedrive/orion/security/jwt/cert.der"
    cert = x509.load_der_x509_certificate(data=open(filename, "rb").read(), backend=default_backend())

    # Issuer
    orgName = cert.issuer.get_attributes_for_oid(NameOID.ORGANIZATION_NAME) #organizationName
    print("Issuer: {}".format(orgName[0].value))

    # SHA1 fingerprint (byte array)
    fp = cert.fingerprint(hashes.SHA1())
    # Convert from Binary to Hex String
    raw_fp = binascii.hexlify(fp)
    # Convert hex to string
    fingerprint = raw_fp.decode('utf-8')

    #WS02 method of encoding the fingerprint
    print("SHA1 -crypto thumbprint: {}".format(fingerprint)) #hex encoded
    fingerprint_enc = base64.b64encode(fingerprint.encode())
    print("SHA1 -crypto (encoded wso2): {}".format(fingerprint_enc.decode('utf-8')))

    # Base64 URL Encoded fingerprint (x5t)
    # Could use one of the following wso2 or base64 url encoded der
    #   base64.b64encode(fingerprint.encode())
    #   fingerprint_bytes_enc.decode('utf-8').rstrip('=')

    fingerprint_bytes_enc = base64.urlsafe_b64encode(fp)
    x5t = fingerprint_bytes_enc.decode('utf-8').rstrip('=')
    print("SHA1 -crypto (encoded)",x5t)
    ###
    #  END cryptography library
    ###

def main():
    pass

# payload = {
#     "iss": "Orion Health",
#     "sub": "level1.hzn"
#     # "exp": datetime.datetime.utcnow() + datetime.timedelta(minutes=15) # valid for 15 minutes
# }

parser = argparse.ArgumentParser(description='Build a JWT token')
parser.add_argument('-p', '--payload', help='Payload json file', required=True, action='store')
args = parser.parse_args()


payload = json.loads(open(args.payload,"r").read())
print("payload {}".format(payload))
payload["exp"] = datetime.datetime.utcnow() + datetime.timedelta(minutes=15) # valid for 15 minutes

# Handle RS256
# Build a new private key
# openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem -days XXX

# Private Key (RSA) can be retrieved via openssl
# openssl rsa -in key.pem -out key.decrypted.pem

# Public key (RSA) can be retrieved via openssl
# openssl rsa -in key.pem -pubout > key.pub

fingerprint_enc = getThumbprintFromHashLib()
# Encode
privatekey_file = "/home/dougie/onedrive/orion/security/jwt/key.decrypted.pem"
# token = jwt.encode(payload, key=open(privatekey_file,"r").read(), algorithm='RS256', headers={"x5t":x5t})
token = jwt.encode(payload, key=open(privatekey_file,"r").read(), algorithm='RS256', headers={"x5t":fingerprint_enc.decode('utf-8')})
print("token -> {}".format(token))
    

# Decode
# Check the types of token and public_key
pubkey_file = "/home/dougie/onedrive/orion/security/jwt/key.pub"
payload = jwt.decode(token, key=open(pubkey_file,"r").read(), algorithms=['RS256'])
print("")
print("payload -> {}".format(payload))

if __name__ == '__main__':
    main()