#!/bin/bash
#$ -S /bin/bash
###########################################################################
##                                                                        #
##                The HMM-based Speech Synthesis Systems                  #
##                Centre for Speech Technology Research                   #
##                     University of Edinburgh, UK                        #
##                      Copyright (c) 2007-2011                           #
##                        All Rights Reserved.                            #
##                                                                        #
##  THE UNIVERSITY OF EDINBURGH AND THE CONTRIBUTORS TO THIS WORK         #
##  DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING       #
##  ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT    #
##  SHALL THE UNIVERSITY OF EDINBURGH NOR THE CONTRIBUTORS BE LIABLE      #
##  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES     #
##  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN    #
##  AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,           #
##  ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF        #
##  THIS SOFTWARE.                                                        #
###########################################################################
##                         Author: Junichi Yamagishi                      #
##                         Date:   31 July 2011                           #
##                         Contact: jyamagis@inf.ed.ac.uk                 #
###########################################################################

# Check Number of Args

if (( "$#" < "2" )); then
   echo "Usage:"
   echo "$0 txt outdir" 
   exit 1
fi

# Load configure file

#echo "...Load configure file..."
#CONFIG_FILE=lib/cfgs/global.cfg 
#. ${CONFIG_FILE}
#if (( $?>0 ));then echo "Error; exiting."; exit 1; fi

txt=$1
outdir=$2

TMP_DIR=$outdir/tmpdir
FESTIVALDIR=/usr/local/teach/MLSALT10/Practical/festival

echo "Processing:" $txt

# Make temporary directory
# echo "...Make temporary directory..."
mkdir -p ${TMP_DIR}
mkdir -p ${TMP_DIR}/utt
mkdir -p ${TMP_DIR}/feats
mkdir -p ${TMP_DIR}/txt

if test -s $txt
then
    # check text encoding here 
    cleantxt=${TMP_DIR}/txt/`basename $txt .txt`.txt
    # remove unnecessary text symbols and make one line 
    tr -d '\^\"\`\?\!\(\)\*\_\+\=\:\[\]\|\\~\<\>\;\/' < $txt \
        | sed "s/ \'/ /g" | sed "s/\' / /g" | sed 's/\. / /g' | sed 's/\- / /g' | sed 's/ \-/ /g' \
        | sed 's/  / /g'  | sed "s/^\'//g"  | sed "s/\'$//g" \
        | perl -pe 's/\n/ /g' \
        | perl -pe 's/$/\n/g' \
        | perl -pe 's/\.+//g' \
        | perl -pe 's/,+/,/g' \
        > $cleantxt
fi

# Make utterance files
utt=${TMP_DIR}/utt/`basename $txt .txt`.utt
if test -s $cleantxt
then
    echo "...Make utterance files..."
    ${FESTIVALDIR}/bin/festival --script ${FESTIVALDIR}/scripts/text2utt.scm $cleantxt -o $utt \
        >> ${TMP_DIR}/festival.log
fi

# Make feature files
feats=${TMP_DIR}/feats/`basename $utt .utt`.feats
if test -s $utt
then
    echo "...Make feature files..."
    ${FESTIVALDIR}/bin/festival --script ${FESTIVALDIR}/scripts/dumpfeats.scm \
        -eval ${FESTIVALDIR}/scripts/extra_feats_combilex.scm \
        -relation Segment \
        -feats ${FESTIVALDIR}/scripts/label.feats \
        -output $feats $utt \
        >> ${TMP_DIR}/festival.log
fi

# Make full-context labels
if test -s $feats
then
    echo "...Make full-context labels..."
    lab=${outdir}/`basename $feats .feats`.lab
    gvlab=${outdir}/`basename $feats .feats`.gvlab
    awk -f ${FESTIVALDIR}/scripts/label-full.awk $feats > $lab
    head -1 $lab > $gvlab
fi

if test -s $lab
then
    rm -r ${TMP_DIR}
    exit 0
else 
    echo "A label file for ${txt} cannot be generated. Please check this text file"
    exit 1
fi

