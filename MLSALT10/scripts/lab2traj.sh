#! /bin/tcsh 
 
###########################################################################
## The system as a whole and most of the files in it are distributed      #
## under the following copyright and conditions                           #
##                                                                        #
##                The HMM-based Speech Synthesis Systems                  #
##             for the Blizzard Challenge and EMIME project               #
##                Centre for Speech Technology Research                   #
##                     University of Edinburgh, UK                        #
##                      Copyright (c) 2007-2008                           #
##                        All Rights Reserved.                            #
##                                                                        #
##  Permission is hereby granted, free of charge, to use and distribute   #
##  this software and its documentation without restriction, including    #
##  without limitation the rights to use, copy, modify, merge, publish,   #
##  distribute, sublicense, and/or sell copies of this work, and to       #
##  permit persons to whom this work is furnished to do so, subject to    #
##  the following conditions:                                             #
##   1. The code must retain the above copyright notice, this list of     #
##      conditions and the following disclaimer.                          #
##   2. Any modifications must be clearly marked as such.                 #
##   3. Original authors' names are not deleted.                          #
##   4. The authors' names are not used to endorse or promote products    #
##      derived from this software without specific prior written         #
##      permission.                                                       #
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
##                         Date:   25 Feb 2009                            #
##                         Contact: jyamagis@inf.ed.ac.uk                 #
###########################################################################
##                                                                        #
##                  Speech Synthesis using hts_engine                     #
##                                                                        #
###########################################################################


if ($# == 0) then
    echo "usage: lab2traj.sh -gv -labdur -hmmdir HMMdir -labdir labeldir -outdir outdir -filename name"
    exit
endif

set ALLARGS=($*)

# Input and output directories 
set HMMdir   = "."   # directory of HMM 
set labeldir = "."   # directory of input label 
set outdir   = "."   # directory of output directory 
set htsopt = ""

# Configuration variables
set shift     = 5   # frame shift in ms
set method    = 1   # Spectral analysis method 
                    # 1) Mel-cepstrum 2) Mel-generalized cepstrum 3) Mel-LSP 4) MGC-LSP 
set order     = 59  # mel-cepstral analysis order 
set mgcgamma  = 3 
set rate      = 16000    # Sampling rate 
set scale     = 3        # Variable for scale (1: Mel 2:Bark by Junichi 3: Bark by Julius 4:ERB by Julius)
                         # Julius Smith "Bark and ERB Bilinear transforms 
                         # IEEE Speech & Audio Proc Vol.7 No.6 Nov. 1999

set f0scale = 3          # flag for scale for F0 transform 
                         # 1) log scale
                         # 2) generalized log scale
                         # 3) mel scale 

echo "F0 transform:" 
switch ($f0scale)
    case 1: 
    set lambda = 0.0
    echo "Log transform"
    breaksw
    case 2: 
    set lambda = 0.770387       # parameter for power transform (optimized value for a female speaker Meg)
    echo "Generalized log transform"
    echo "(lambda = $lambda)"
    breaksw
    case 3: 
    set lambda = -1.0
    echo "Mel transform"
    breaksw
    default:
    echo "Unknown scale"
    break
endsw

while ( $#argv )
  switch ( $1 )
     case -gv:
       set gvopt = 1 ; breaksw
     case -labdur:
       set htsopt = ( $htsopt -vp ) ; breaksw
     case -hmmdir:
       set HMMdir = $2; shift; breaksw
     case -labdir:
       set labeldir = $2; shift; breaksw
     case -outdir:
       set outdir = $2; shift; breaksw
     case -filename:
       set file = $2; shift; breaksw
     default:
       echo "Incorrect option $1"
       exit 1
       break
  endsw
  shift
end

if ( $?gvopt ) then
    set htsopt = ( $htsopt -gf $HMMdir/gv-lf0.pdf -gm $HMMdir/gv-mcep.pdf -ga $HMMdir/gv-bndap.pdf )
endif


set path = ( /usr/local/teach/MLSALT10/Practical/bin ../../bin $path )
set hts   = hts_engine_straight
set resyn = synthesis_fft

mkdir -p $outdir

switch ($rate)
    case 48000
        set fftlen = 4096
        switch ($scale)
        case 1: 
            echo "Mel scale"
            set alpha  = "0.55"
            breaksw
        case 2: 
            echo "Bark scale (by Junichi)"
            set alpha  = "0.68"
            breaksw
        case 3: 
            echo "Bark scale (by Julius)"
            set alpha  = "0.77"
            breaksw
        case 4: 
            echo "ERB scale (by Julius)"
            set alpha  = "0.74"
            breaksw
        default:
            echo "Unknown method"
            break
        endsw
        breaksw
    case 44100: 
        set fftlen = 4096 
        switch ($scale)
        case 1: 
            echo "Mel scale"
            set alpha  = "0.53"
            breaksw
        case 2: 
            echo "Bark scale (by Junichi)"
            set alpha  = "0.67"
            breaksw
        case 3: 
            echo "Bark scale (by Julius)"
            set alpha  = "0.76"
            breaksw
        case 4: 
            echo "ERB scale (by Julius)"
            set alpha  = "0.74"
            breaksw
        default:
            echo "Unknown method"
            break
        endsw
        breaksw
    case 32000: 
        set fftlen = 2048
        switch ($scale)
        case 1: 
            echo "Mel scale"
            set alpha  = "0.45"
            breaksw
        case 2: 
            echo "Bark scale (by Junichi)"
            set alpha  = "0.59"
            breaksw
        case 3: 
            echo "Bark scale (by Julius)"
            set alpha  = "0.71"
            breaksw
        case 4: 
            echo "ERB scale (by Julius)"
            set alpha  = "0.72"
            breaksw
        default:
            echo "Unknown method"
            break
        endsw
        breaksw
    case 22050: 
        set fftlen = 1024 
        switch ($scale)
        case 1: 
            echo "Mel scale"
            set alpha  = "0.45"
            breaksw
        case 2: 
            echo "Bark scale (by Junichi)"
            set alpha  = "0.59"
            breaksw
        case 3: 
            echo "Bark scale (by Julius)"
            set alpha  = "0.65"
            breaksw
        case 4: 
            echo "ERB scale (by Julius)"
            set alpha  = "0.70"
            breaksw
        default:
            echo "Unknown method"
            break
        endsw
        breaksw
    case 16000: 
        set fftlen = 1024 
        switch ($scale)
        case 1: 
            echo "Mel scale"
            set alpha  = "0.42"
            breaksw
        case 2: 
            echo "Bark scale (by Junichi)"
            set alpha  = "0.55"
            breaksw
        case 3: 
            echo "Bark scale (by Julius)"
            set alpha  = "0.58"
            breaksw
        case 4: 
            echo "ERB scale (by Julius)"
            set alpha  = "0.67"
            breaksw
        default:
            echo "Unknown method"
            break
        endsw
        breaksw
    default:
        echo "Unknown sampling rate"
        break
endsw

if ( $?file ) then
    if ( -f $labeldir/${file}.lab ) then
        set lablist = $labeldir/${file}.lab
    else 
        echo "file missing:  $labeldir/${file}.lab"
        exit 1
   endif
else 
    set lablist = `ls -1 $labeldir/*.lab`
endif

foreach lab ( $lablist )
    set f0    = $outdir/$lab:t:r.f0
    set mcep  = $outdir/$lab:t:r.mcep
    set apf   = $outdir/$lab:t:r.apf
    set sspec = $outdir/$lab:t:r.spec
    set wav   = $outdir/$lab:t:r.wav
    set LOG   = $outdir/$lab:t:r.LOG

    echo "$0 $ALLARGS" > $LOG

    $hts \
        -td $HMMdir/tree-duration.inf \
        -tf $HMMdir/tree-logF0.inf \
        -tm $HMMdir/tree-mcep.inf \
        -ta $HMMdir/tree-bndap.inf \
        -md $HMMdir/duration.pdf \
        -mf $HMMdir/logF0.pdf \
        -mm $HMMdir/mcep.pdf \
        -ma $HMMdir/bndap.pdf \
        -df $HMMdir/logF0_d1.win \
        -df $HMMdir/logF0_d2.win \
        -dm $HMMdir/mcep_d1.win \
        -dm $HMMdir/mcep_d2.win \
        -da $HMMdir/bndap_d1.win \
        -da $HMMdir/bndap_d2.win \
        -e $lambda \
        -of $f0 \
        -om $mcep \
        -oa $apf \
        $htsopt \
        $lab >>& $LOG

    x2x +fd $apf  > $apf.double
    x2x +fa $f0   > $f0.txt

end
