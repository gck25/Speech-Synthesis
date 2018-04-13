#! /bin/tcsh -f

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
    echo "usage: traj2wav.sh -trajdir trajdir -outdir outdir -filename"
    exit
endif

set ALLARGS=($*)

# Input and output directories 
set trajdir   = "."   # directory of HMM 
set outdir   = "."   # directory of output directory 

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

while ( $#argv )
  switch ( $1 )
     case -trajdir:
       set trajdir = $2; shift; breaksw
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

set krate=`echo "$rate / 1000" | bc` # e.g. Frame shift in point (80 = 16000 * 0.005)


if ( $?file ) then
    if ( -f $trajdir/${file}.f0 ) then
        set trajlist = $trajdir/${file}.f0
    else 
        echo "file missing:  $trajdir/${file}.f0"
        exit 1
   endif
else 
    set trajlist = `ls -1 $trajdir/*.f0`
endif

foreach traj ( $trajlist )


    set f0    = $trajdir/$traj:t:r.f0
    set mcep  = $trajdir/$traj:t:r.mcep
    set apf   = $trajdir/$traj:t:r.apf
    set sspec = $trajdir/$traj:t:r.spec
    set wav   = $outdir/$traj:t:r.wav
    set LOG   = $outdir/$traj:t:r.LOG

    echo "$0 $ALLARGS" > $LOG


    # Convert given mel-cepstrum or LSP to the smoothed spectrum
    switch ($method)
    case 1: # Mel-cepstral analysis
    case 2: # Mel-generalized cepstral analysis"
        echo "Spectral analysis method: Mel-cepstral analysis" >> $LOG
#        mgc2sp -a $alpha -g 0 -m $order -l $fftlen -o 2 $mcep |\
#        x2x +fd > $sspec.double
        mcpf -a $alpha -m $order -b 0.2 -l 96 $mcep |\
        mgc2sp -a $alpha -g 0 -m $order -l $fftlen -o 2 |\
        x2x +fd > $sspec.double
	echo "done."
        breaksw
    case 3: # Mel-LSP analysis (log gain)"
        echo "Spectral analysis Method: Mel-LSP analysis (log gain)"  >> $LOG
        lspcheck -m $order -s $krate -r 0.01 $mcep |\
        lsp2lpc -m $order -s $krate -l |\
        mgc2mgc -a $alpha -c 1 -m $order -n -u -A $alpha -C 1 -M $order |\
        mgc2sp -a $alpha -c 1 -m $order -l $fftlen -o 2 |\
        x2x +fd > $sspec.double
        breaksw
    case 4: # MGC-LSP analysis (log gain)"
        echo "Spectral analysis Method: MGC-LSP analysis (log gain) MGC-Gamma: $mgcgamma"  >> $LOG
        lspcheck -m $order -s $krate -r 0.01 $mcep |\
        lsp2lpc -m $order -s $krate -l |\
        mgc2mgc -a $alpha -c $mgcgamma -m $order -n -u -A $alpha -C $mgcgamma -M $order |\
        mgc2sp -a $alpha -c $mgcgamma -m $order -l $fftlen -o 2 |\
        x2x +fd > $sspec.double
        breaksw
    default:
        echo "Unknown method"
        break
    endsw
    
    $resyn \
        -f $rate \
        -fftl $fftlen \
        -spec \
        -order $order \
        -shift $shift \
        -sigp 1.2 \
        -sd 0.5 \
        -cornf 4000 \
        -bw 70.0 \
        -delfrac 0.2 \
        -bap \
        -apfile $apf.double \
        $f0.txt \
        $sspec.double \
        $wav >>&  $LOG
        
end
