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
usage = "usage: %prog hmmfn stream dim contextlist outfile"
parser = OptionParser(usage)
parser.add_option('-f',help='features',dest='ftype',default='')
# parser.add_option('-e',help='error file',dest='efn',default='')

(options, args) = parser.parse_args()

ftype = options.ftype

if len(args) != 5:
   parser.error("incorrect number of arguments")

hmmfn  = args[0]
stream_str=args[1]
stream = int(float(stream_str))
dim_str = args[2]
dim    = int(float(dim_str))
contextfn = args[3]
outfn  = args[4]

# --------------------------------------------------------------------
# Main Program
# --------------------------------------------------------------------

# open the map.txt phone mapping file
# read this into a python dictionary

hmmin = open(hmmfn, 'r')
contextin = open(contextfn, 'r')

fout = open(outfn, 'w')

# start by getting the set of words that there are dictionary entries for
streamtab={}
hmmtab={}
validmean=0
validvar=0
validstream=0
streamm=''
hmmm=''
odim=1

for line in hmmin:
   hmmlist = line.split()

   if ((validmean == 1) & (validstream == 1)):
      streamtab[streamm] = hmmlist[dim] + ' ' + hmmlist[dim+odim]  + ' ' + hmmlist[dim+2*odim]
      validmean=0

   if ((validvar == 1) & (validstream == 1)):
      streamtab[streamm] = streamtab[streamm] + ' ' + hmmlist[dim] + ' ' + hmmlist[dim+odim]  + ' ' + hmmlist[dim+2*odim]
      validvar=0

   if (hmmlist[0] == '~p' ):
      streamm = hmmlist[1]
      if (validstream == 1):
         if (hmmm <> '') & (streamm in streamtab):
            if not (hmmm in hmmtab):
               hmmtab[hmmm] = {}
            ltab = hmmtab[hmmm]
            ltab[stateid] = streamtab[streamm]

   if (hmmlist[0] == '<STATE>'):
      stateid=int(float(hmmlist[1]))

   if (hmmlist[0] == '<GCONST>'):
      validstream=0
      
   if (hmmlist[0] == '<STREAM>'):
      if (hmmlist[1] == stream_str):
         validstream=1
      else:
         validstream=0

   if ((hmmlist[0] == '<MEAN>') & (validstream == 1)):
      odim=int(float(hmmlist[1]))/3
      if (dim>odim):
         print "Dimensionality inconsistsency", odim
         sys.exit(0)
      validmean=1
   else:
      validmean=0

   if ((hmmlist[0] == '<VARIANCE>')  & (validstream == 1)):
      odim=int(float(hmmlist[1]))/3
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
      ltab = hmmtab[contxt] 
      for val in range  (2, 7):
         if  (val in ltab):
            print >> fout,  ltab[val]
         else:
            print >> fout, 'Missing ', val



hmmin.close()




         

