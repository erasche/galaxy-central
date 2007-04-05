#!/usr/bin/env python2.4
#Dan Blankenberg
"""
Reads a list of block numbers and a maf. Produces a new maf containing the
blocks specified by number.
"""

import sys
import pkg_resources; pkg_resources.require( "bx-python" )
import bx.align.maf

def __main__():

    input_block_filename = sys.argv[1].strip()
    input_maf_filename = sys.argv[2].strip()
    output_filename1 = sys.argv[3].strip()
    block_col = int(sys.argv[4].strip())-1
    if block_col < 0:
        print >> sys.stderr, "Invalid column specified"
        sys.exit(0)
    
    maf_writer = bx.align.maf.Writer( open(output_filename1, 'w') )
    #we want to maintain order of block file and write blocks as many times as they are listed
    ctr = 0
    failed_lines = []
    for line in open(input_block_filename, 'r'):
        ctr += 1
        try:
            block_wanted = int(line.split("\t")[block_col].strip())
        except:
            failed_lines.append(str(ctr))
            continue
        maf_reader = bx.align.maf.Reader( open(input_maf_filename, 'r') )
        count = 0
        for m in maf_reader:
            if count == block_wanted:
                maf_writer.write(m)
                break
            count += 1
    if len(failed_lines) > 0: print "Failed to extract from %i lines (%s)." % (len(failed_lines), ",".join(failed_lines))
if __name__ == "__main__": __main__()
