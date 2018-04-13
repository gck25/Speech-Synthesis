import codecs
import gzip
import sys
import re
import unicodedata
import xml.etree.ElementTree as ET

from optparse import OptionParser
from operator import itemgetter

# ----------------------------------------------------------------------------
# arguments
# ----------------------------------------------------------------------------
usage = "usage: %prog hmmfn contextlist outfile"
parser = OptionParser(usage)
parser.add_option('-f',help='features',dest='ftype',default='')
# parser.add_option('-e',help='error file',dest='efn',default='')

(options, args) = parser.parse_args()

ftype = options.ftype

if len(args) != 3:
   parser.error("incorrect number of arguments")

hmmfn  = args[0]
contextfn = args[1]
outfn  = args[2]

# --------------------------------------------------------------------
# Main Program
# --------------------------------------------------------------------

# open the map.txt phone mapping file
# read this into a python dictionary

hmmin = open(hmmfn, 'r')
contextin = open(contextfn, 'r')

fout = open(outfn, 'w')

# start by getting the set of words that there are dictionary entries for
mstreamtab={}
vstreamtab={}
hmmtab={}
validmean=0
validvar=0
validstream=0
streamm=''
hmmm=''
dim=0


for line in hmmin:
   hmmlist = line.split()

   if (validmean == 1) and (streamm <> ''):
      if (streamm in mstreamtab):
         mstreamtab[streamm] = mstreamtab[streamm] + ' ' + hmmlist[dim] 
      else:
         mstreamtab[streamm] = hmmlist[dim] 
      validmean=0

   if (validvar == 1)  and (streamm <> ''):
      if (streamm in vstreamtab):
         vstreamtab[streamm] = vstreamtab[streamm] + ' ' + hmmlist[dim] 
      else:
         vstreamtab[streamm] = hmmlist[dim] 
      validvar=0

   if (hmmlist[0] == '~s' ):
      streamm = hmmlist[1]
      if (hmmm <> '') & (streamm in mstreamtab):
         if not (hmmm in hmmtab):
            hmmtab[hmmm] = mstreamtab[streamm] + ' ' + vstreamtab[streamm]

   if (hmmlist[0] == '<MEAN>'):
      validmean=1
   else:
      validmean=0

   if (hmmlist[0] == '<VARIANCE>'):
      validvar=1
   else:
      validvar=0

   if (hmmlist[0] == '~h'):
      hmmm = hmmlist[1]

for line in contextin:
   contxt = line.split()[0]
   contxt = '"' + contxt + '"'
   print >> fout, contxt
   if (contxt in hmmtab):
      print >> fout,  hmmtab[contxt]
   else:
      print >> fout, 'Missing ', contxt



hmmin.close()




         

