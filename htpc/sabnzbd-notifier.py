import sys
import requests
import json

try:
    (scriptname, notification_type, notification_title, notification_text, parameters) = sys.argv
except:
    print("No commandline parameters found")
    sys.exit(1)

print("parameters: {}".format(parameters))
msg = "[{}] {} -> {}".format(notification_type,notification_title,notification_text)
data = {"text":msg}
headers = {'content-type':'application/json'}
r = requests.post(parameters,headers=headers,data=json.dumps(data))

# Success code
sys.exit(0)