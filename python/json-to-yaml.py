import yaml
import json
import sys
import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Converts json to yaml')
    parser.add_argument('-i','--input', help="Input json file", required=True)
    args = parser.parse_args()

    with open(args.input, 'r') as f:
        json_object = json.load(f) # yaml_object will be a list or a dict
        print(yaml.dump(json_object))