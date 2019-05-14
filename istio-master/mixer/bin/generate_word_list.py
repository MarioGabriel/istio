#!/usr/bin/env python

#
# Generates golang from a yaml-formatted global attributes list.
#

import os
import argparse

HEADER = """// Code generated by go generate. DO NOT EDIT.
// Source: vendor/istio.io/api/mixer/v1/global_dictionary.yaml

package attribute

func GlobalList() ([]string) { 
    tmp := make([]string, len(globalList))
    copy(tmp, globalList)
    return tmp
}

var ( 
    globalList = []string{
"""

FOOTER = """    }
)
"""

def generate(src, dst):
    code = HEADER
    for line in src:
        if line.startswith("-"):
            code += "\t\t\"" + line[1:].strip().replace("\"", "\\\"") + "\",\n"
    code += FOOTER
    dst.write(code)

def main(args):
    parser = argparse.ArgumentParser(description='Generate global word list code.')
    parser.add_argument('infile', type=argparse.FileType('r'), help='source file for global word list')
    parser.add_argument('outfile', type=argparse.FileType('w'), help='output file for generated code')
    parsed = parser.parse_args(args)
    generate(parsed.infile, parsed.outfile)
    parsed.infile.close()
    parsed.outfile.close()


if __name__ == "__main__":
    import sys
    sys.exit(main(sys.argv[1:]))
