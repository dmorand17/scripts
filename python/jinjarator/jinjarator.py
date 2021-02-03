#!/usr/bin/python3

import argparse
import logging
import os
from datetime import datetime
import time
import yaml
import jinja2
import json

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def parse_args():
    parser = argparse.ArgumentParser(description='HL7 Explorer to display message transactions, messages, histograms.')    
    parser.add_argument('-v', '--verbose', help='Verbose logging (-v,-vv,etc)', action='count', default=0)
    parser.add_argument('-i', '--input', help='Input YAML file', action='store', required=True)
    parser.add_argument('-t', '--template', help='Template file to be used', action='store', required=True)
    parser.add_argument('-o', '--output', help='Output filename', action='store', default='output.txt')
    parser.add_argument('--trim_blocks', help='Set trim_blocks for jinja2 environment', action='store_true')
    return parser.parse_args()

class style():
    BLACK = '\033[30m'
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    UNDERLINE = '\033[4m'
    RESET = '\033[0m'

def header_decorator(func):
    # Decorator to print messages before/after calling function
    def wrapper():
        print(f"\n{style.BLUE}Starting [{func.__name__}]{style.RESET}")
        start = time.time()
        func()
        end = time.time()
        print(f"{style.BLUE}Finished [{func.__name__}]{style.RESET} in {end-start:.4f} seconds \n")
    return wrapper

def is_blank(str):
    return str is None or not str

def blankIfNull(str):
    return "" if str is None or not str else str

def print_json(dict_str):
    print(json.dumps(dict_str,indent=2))   

def error(msg):
    print(f"{style.RED}{msg}{style.RESET}") 

"""
    Jinja filters to be used in templates
"""
def dateformat(value, input_format=None, output_format=None):
    DEFAULT_FORMAT = "%Y%m%d"
    if type(value) == str:
        date_parsed = datetime.strptime(value,input_format)
        return date_parsed.strftime(output_format or DEFAULT_FORMAT)
    if type(value) == datetime:
        return value.strftime(output_format or DEFAULT_FORMAT)

def jinja_filters():
    return {
        'dateformat': dateformat
    }

@header_decorator
def yaml_to_jinja():
    templateLoader = jinja2.FileSystemLoader(searchpath='./')
    jEnv = jinja2.Environment(loader=templateLoader,trim_blocks=args.trim_blocks)
    jEnv.filters.update(jinja_filters())

    jTemplate = jEnv.get_template(args.template)
    with open(args.input) as f:
        yaml_input = yaml.safe_load(f)
    
    output = jTemplate.render(yaml_input)
    if(args.verbose):
        logger.debug(f"{print_json(yaml_input)}")
        print(f"{output}")

    # write output to a file
    with open(args.output,"w") as f:
        f.write(output)
    print(f"{style.YELLOW}{args.output}{style.RESET} created!")

def main():
    yaml_to_jinja()

if __name__ == '__main__':
    args = parse_args()
    main()