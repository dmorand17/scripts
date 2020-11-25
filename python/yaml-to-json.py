import yaml
import json
import sys
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Converts yaml to json')
    parser.add_argument('-i','--input', help="Input yaml file", required=True)
    args = parser.parse_args()

    with open(args.input, 'r') as f:
        yaml_object = yaml.safe_load(f) # yaml_object will be a list or a dict
        print(json.dumps(yaml_object))