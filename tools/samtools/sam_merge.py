#! /usr/bin/python

"""
Merges any number of BAM files
usage: %prog [options]
    input1
    output1
    input2
    [input3[,input4[,input5[,...]]]]
"""

import os, subprocess, sys

def stop_err( msg ):
    sys.stderr.write( '%s\n' % msg )
    sys.exit()

def __main__():
    infile =  sys.argv[1]
    outfile = sys.argv[2]
    if len( sys.argv ) < 3:
        stop_err( 'There are not enough files to merge' )
    filenames = sys.argv[3:]
    cmd = 'samtools merge %s %s %s' % ( outfile, infile, ' '.join( filenames ) )
    try:
        proc = subprocess.Popen( args=cmd, shell=True, stderr=subprocess.PIPE )
        returncode = proc.wait()
        # get stderr, allowing for case where it's very large
        stderr = ''
        buffsize = 1048576
        try:
            while True:
                stderr += proc.stderr.read( buffsize )
                if not stderr or len( stderr ) % buffsize != 0:
                    break
        except OverflowError:
            pass
        if returncode != 0:
            raise Exception, stderr
    except Exception, e:
        stop_err( 'Error running SAMtools merge tool\n' + str( e ) )
    if os.path.getsize( outfile ) > 0:
        sys.stdout.write( '%s files merged.' % ( len( sys.argv ) - 2 ) )
    else:
        stop_err( 'The output file is empty, there may be an error with one of your input files.' )

if __name__ == "__main__" : __main__()
