#! /bin/tcsh

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
##                         Date:   25 Feb 2011                            #
##                         Contact: jyamagis@inf.ed.ac.uk                 #
###########################################################################
##                                                                        #
##                     Speech Synthesis using HMGenS                      #
##                                                                        #
###########################################################################

if ($# == 0) then
    echo "usage: lab2traj.sh -gv -labdur -hmmdir HMMdir -labdir labeldir -outdir outdir -filename name"
    exit
endif

# Input and output directories 
set HMMdir   = "."    # directory of HMM 
set labeldir = "."    # directory of input label 
set outdir   = "."    # directory of output directory 
set hmgenopt = ""

# Configuration variables
set shift     = 5   # frame shift in ms
set method    = 1   # Spectral analysis method 
                    # 1) Mel-cepstrum 2) Mel-generalized cepstrum 3) Mel-LSP 4) MGC-LSP 
set order     = 59  # mel-cepstral analysis order 
set bands     = 21  # band aperiodicity order

set winlength = 5 
set mgcgamma  = 3 
set rate      = 16000    # Sampling rate 
set scale     = 3        # Variable for scale (1: Mel 2:Bark by Junichi 3: Bark by Julius 4:ERB by Julius)
                         # Julius Smith "Bark and ERB Bilinear transforms 
                         # IEEE Speech & Audio Proc Vol.7 No.6 Nov. 1999

set linear    = 0   # 0) No linear transforms 
                    # 1) MLLRMEAN 2) CMLLR 3) SMAPLR 4) CSMAPLR 5) SEMIT
set regclass  = 0   # 0) Regression class tree 1) Base class
set duradapt  = 0   # 0) Duration adaptation 1) No adaptation for duration
set gentype   = 0   # 0) Single mixture is used and state sequence is independently optimized
                    # 1) EM parameter generation (w.r.t. mixture weights), but state sequence is independently optimized 
                    # 2) EM parameter generation (w.r.t. both of mixture weights and state sequence) 

set  f0scale  = 3   # flag for scale for F0 transform 
                    # 1) log scale
                    # 2) generalized log scale
                    # 3) mel scale 
                    # 4) ERB scale 

set vocoder   = STRAIGHT   # STRAIGHT|HMPD

set resyn     = synthesis_fft    # synthesizer for STRAIGHT

set usegv     = FALSE

echo "F0 transform:"
switch ($f0scale)
    case 1: 
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
    case 4:
    echo "Scale: ERB transform"
    breaksw
    default:
    echo "Unknown scale"
    break
endsw

while ( $#argv )
  switch ( $1 )
     case -labdur:
       set hmgenopt = ( $hmgenopt -m ) ; breaksw
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

set path = ( /usr/local/teach/MLSALT10/Practical/htk/HTKTools /usr/local/teach/MLSALT10/Practical/bin  $path )

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

echo "Speech synthesis using HMMs (HMGenS)"
echo "Sampling rate: $rate  Frame shift: $shift ms  Analysis order: $order"
echo "Alpha for all-pass filter:$alpha"
echo ""

set krate=`echo "$rate / 1000" | bc` # e.g. Frame shift in point (80 = 16000 * 0.005)

# # Calc the number of bands for aperiodicity measures
# cat <<EOF >! $outdir/bc.txt
# nq = $rate/2
# scale = 4
# fbark = 26.81 * nq / (1960 + nq ) - 0.53
# 
# if(fbark<2){
#    fbark += 0.15*(2-fbark)
# }
# 
# if(fbark>20.1){
#    fbark +=  0.22*(fbark-20.1)
# }
# 
# scale=0
# (fbark + 0.5)/1
# quit
# EOF
# set bands = `bc -q $outdir/bc.txt`

# Prepare config files for HMGenS
set veclength = `echo $order + 1 | bc`
#set mineucnorm =  `echo "scale=4 ; (( $order + 1 ) * 3 + 3 + $bands * 3 ) * 0.01 " | bc -l |  awk '{printf "%.4f\n",$1}'`
#set gvepsilon = `echo "scale=4 ; (( $order + 1 ) * 3 + 3 + $bands * 3 ) * 0.0001 " | bc -l |  awk '{printf "%.4f\n",$1}'`
#set mineucnorm =  `echo "scale=4 ; ( $order + 1 ) * 0.01 " | bc -l |  awk '{printf "%.4f\n",$1}'`
#set gvepsilon = `echo "scale=4 ; ( $order + 1 ) * 0.0001 " | bc -l |  awk '{printf "%.4f\n",$1}'`
#set mineucnorm =  `echo "scale=4 ; 0.01 " | bc -l |  awk '{printf "%.4f\n",$1}'`
#set gvepsilon = `echo "scale=4 ; 0.0001 " | bc -l |  awk '{printf "%.4f\n",$1}'`
set mineucnorm =  `echo "scale=4 ; 0.05 " | bc -l |  awk '{printf "%.4f\n",$1}'`
set gvepsilon = `echo "scale=4 ; 0.0005 " | bc -l |  awk '{printf "%.4f\n",$1}'`
# LSD 
set mineucnorm =  `echo "scale=4 ; 0.05 " | bc -l |  awk '{printf "%.4f\n",$1}'`
set gvepsilon = `echo "scale=4 ; 0.1 " | bc -l |  awk '{printf "%.4f\n",$1}'`



cat <<EOF >! $outdir/gen.conf
NATURALREADORDER  = T
NATURALWRITEORDER = T
TREEMERGE         = F
APPLYVFLOOR       = F
PDFSTRSIZE        = "IntVec 3 1 3 1"
PDFSTRORDER       = "IntVec 3 $veclength 1 $bands"
PDFSTREXT         = "StrVec 3 mcep f0 apf"
WINDIR            = "$outdir"
WINFN             = "StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win"
MAXEMITER         = 20
EMEPSILON         = 0.000100
USEGV             = $usegv
GVMODELMMF        = "$HMMdir/gv.mmf"
GVHMMLIST         = "$outdir/list.gv"
MAXGVITER         = 1000
MINEUCNORM        = $mineucnorm
GVEPSILON         = $gvepsilon
STEPINIT          = 1
STEPINC           = 1.1
STEPDEC           = 0.5
HMMWEIGHT         = 1.0
GVWEIGHT          = 1.0 
GVINITWEIGHT      = 1.0 
OPTKIND           = LBFGS
EOF

if ( (-e $HMMdir/logspec-gv.mmf) && ( $method == 4 ) ) then
    cat <<EOF >! $outdir/gen.conf
NATURALREADORDER  = T
NATURALWRITEORDER = T
TREEMERGE         = F
APPLYVFLOOR       = F
PDFSTRSIZE        = "IntVec 3 1 3 1"
PDFSTRORDER       = "IntVec 3 $veclength 1 $bands"
PDFSTREXT         = "StrVec 3 mcep f0 apf"
WINDIR            = "$outdir"
WINFN             = "StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win"
MAXEMITER         = 20
EMEPSILON         = 0.000100
USEGV             = $usegv
USEGVSPEC         = $usegv
GVOFFMODEL        = "StrVec 2 \# pau"
GVMODELMMF        = "$HMMdir/logspec-gv.mmf"
GVHMMLIST         = "$outdir/list.gv"
MAXGVITER         = 10
MINEUCNORM        = $mineucnorm
GVEPSILON         = $gvepsilon
STEPINIT          = 0.001
STEPINC           = 1.2
STEPDEC           = 0.5
HMMWEIGHT         = 1.0
GVWEIGHT          = 1.0
GVINITWEIGHT      = 1.0
ALPHA             = $alpha
GAMMA             = $mgcgamma
FFTLEN            = $fftlen
OPTKIND           = STEEPEST
EOF
endif

if ( -e $HMMdir/nosil-gv.mmf ) then
    cat <<EOF >! $outdir/nosilgv-gen.conf
NATURALREADORDER  = T
NATURALWRITEORDER = T
TREEMERGE         = F
APPLYVFLOOR       = F
PDFSTRSIZE        = "IntVec 3 1 3 1"
PDFSTRORDER       = "IntVec 3 $veclength 1 $bands"
PDFSTREXT         = "StrVec 3 mcep f0 apf"
WINDIR            = "$outdir"
WINFN             = "StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win"
MAXEMITER         = 20
EMEPSILON         = 0.000100
USEGV             = $usegv
GVOFFMODEL        = "StrVec 2 \# pau"
GVMODELMMF        = "$HMMdir/nosil-gv.mmf"
GVHMMLIST         = "$outdir/list.gv"
MAXGVITER         = 1000
MINEUCNORM        = $mineucnorm
GVEPSILON         = $gvepsilon
STEPINIT          = 1
STEPINC           = 1.2
STEPDEC           = 0.5
HMMWEIGHT         = 1.0
GVWEIGHT          = 1.0 
GVINITWEIGHT      = 1.0 
OPTKIND           = LBFGS
EOF
endif

if ( (-e $HMMdir/nosil-logspec-gv.mmf) && ( $method == 4 ) ) then
    cat <<EOF >! $outdir/nosilgv-gen.conf
NATURALREADORDER  = T
NATURALWRITEORDER = T
TREEMERGE         = F
APPLYVFLOOR       = F
PDFSTRSIZE        = "IntVec 3 1 3 1"
PDFSTRORDER       = "IntVec 3 $veclength 1 $bands"
PDFSTREXT         = "StrVec 3 mcep f0 apf"
WINDIR            = "$outdir"
WINFN             = "StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win StrVec 3 sta.win dyn.win acc.win"
MAXEMITER         = 20
EMEPSILON         = 0.000100
USEGV             = $usegv
USEGVSPEC         = $usegv
GVOFFMODEL        = "StrVec 2 \# pau"
GVMODELMMF        = "$HMMdir/nosil-logspec-gv.mmf"
GVHMMLIST         = "$outdir/list.gv"
MAXGVITER         = 1000
MINEUCNORM        = $mineucnorm
GVEPSILON         = $gvepsilon
STEPINIT          = 0.001
STEPINC           = 1.2
STEPDEC           = 0.5
HMMWEIGHT         = 1.0
GVWEIGHT          = 1.0
GVINITWEIGHT      = 1.0
ALPHA             = $alpha
GAMMA             = $mgcgamma
FFTLEN            = $fftlen
OPTKIND           = STEEPEST
EOF
endif

# Config files for CMLLR/CSMAPLR trnasforms
cat <<EOF >! $outdir/fullc.conf
 HADAPT:SAVEFULLC = TRUE
EOF

# Generate awk function for sorting and voting
cat <<EOF >! $outdir/max.awk
#!/usr/local/bin/gawk -f
{
 printf "%.3f\n", mid(\$1,\$2,\$3)

}
function max(a,b,c){
 tmax = a;
 if(tmax<b){
   tmax=b;
 }
 if(tmax<c){
   tmax=c;
 }
 return tmax;
}

function min(a,b,c){
 tmin = a;
 if(tmin>b){
   tmin=b;
 }
 if(tmin>c){
   tmin=c;
 }
 return tmin;
}

function mid(a,b,c){
 f0[1] = a;
 f0[2] = b;
 f0[3] = c;

 sort(f0,3);
 return f0[2];
}

# sort function -- sort numbers in ascending order
function sort(ARRAY, ELEMENTS, temp, i, j) {
   for (i = 2; i <= ELEMENTS; ++i) {
      for (j = i; ARRAY[j-1] > ARRAY[j]; --j) { 
           temp = ARRAY[j]
           ARRAY[j] = ARRAY[j-1]
           ARRAY[j-1] = temp
      }
   }
   return 
}

EOF

# Generate awk function for smoothing (this should be improved) 
cat <<EOF >! $outdir/smooth.awk
#!/usr/local/bin/gawk -f
{
 printf "%.3f\n", smooth(\$1,\$2,\$3)

}
function smooth(a,b,c){
 tsmt = b;
 if((a!=0.0) && (b!=0.0) && (c!=0.0)){
   tsmt = (a + c)/4 + b/2;
 }
 return tsmt;
}

EOF


# Generate ascii window files
rm -f $outdir/sta.win $outdir/dyn.win $outdir/acc.win 
echo "1 1.0" > $outdir/sta.win
set dyncoef=`calcwin -l $winlength | x2x -o +fa`
echo $winlength $dyncoef > $outdir/dyn.win
set acccoef=`calcwin -l $winlength -a | x2x -o +fa`
echo $winlength $acccoef > $outdir/acc.win

# Generate several files required
rm -f $outdir/list.gv
echo "gv" > $outdir/list.gv

rm -f $outdir/context.lst.tmp
rm -f $outdir/synlabel.dat

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

foreach lab ( $lablist)
   cat $lab | awk '{print $NF}' >>! $outdir/context.lst.tmp
   echo $lab >>! $outdir/synlabel.dat
end 
sort $outdir/context.lst.tmp | uniq >! $outdir/context.lst
rm -f $outdir/context.lst.tmp  

# HHEd files.
# If necessary do the model transformation using linear transforms 
cat <<EOF >! $outdir/add.cmp.hed 
 LT $HMMdir/tree.mcep.inf 
 LT $HMMdir/tree.logF0.inf
 LT $HMMdir/tree.bndap.inf
 AU $outdir/context.lst
EOF

cat <<EOF >! $outdir/add.dur.hed
 LT $HMMdir/tree.dur.inf
 AU $outdir/context.lst
EOF

cat <<EOF >! $outdir/trans.cmp.hed 
 LT $HMMdir/tree.mcep.inf 
 LT $HMMdir/tree.logF0.inf
 LT $HMMdir/tree.bndap.inf
 CM $outdir/
 AU $outdir/context.lst
EOF

cat <<EOF >! $outdir/trans.dur.hed
 LT $HMMdir/tree.dur.inf
 CM $outdir/
 AU $outdir/context.lst
EOF

cat <<EOF >! $outdir/semit.cmp.hed 
 AX $HMMdir/SEMITIED
 LT $HMMdir/tree.mcep.inf 
 LT $HMMdir/tree.logF0.inf
 LT $HMMdir/tree.bndap.inf
 CM $outdir/
 AU $outdir/context.lst
EOF

# Prepare unseen models 
switch ($linear)
case 0: # No input linear transforms. Just generate parameters from given HMMs
    echo ""
    HHEd -A  -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.cmp.mmf -w $outdir/clustered.cmp.mmf $outdir/add.cmp.hed $HMMdir/context.cmp.list 
    HHEd -A  -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -w $outdir/clustered.dur.mmf $outdir/add.dur.hed $HMMdir/context.dur.list
    breaksw
case 1: # MLLR 
case 3: # SMAPLR Transform given models
    set treeoption = ""
    if ($regclass == 0) then
       $treeoption = "-H $HMMdir/dectree_cmp.tree"
       $dtreeoption = "-H $HMMdir/dectree_dur.tree"
    endif
    HHEd -A -B -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.cmp.mmf -H $HMMdir/dectree_cmp.base $treeoption -w $outdir/clustered.cmp.mmf $outdir/trans.cmp.hed $HMMdir/context.cmp.list 
    if ($duradapt == 1) then
        HHEd -A -B -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -H $HMMdir/dectree_dur.base $dtreeoption -w $outdir/clustered.dur.mmf $outdir/trans.dur.hed $HMMdir/context.dur.list
    else
        HHEd -A -B -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -w $outdir/clustered.dur.mmf $outdir/add.dur.hed $HMMdir/context.dur.list
    endif
    rm $outdir/pdf.*
     breaksw
case 2: # CMLLR 
case 4: # CSMAPLR Transform given models and make covariance matrices full
    set treeoption = ""
    if ($regclass == 0) then
       $treeoption = "-H $HMMdir/dectree_cmp.tree"
       $dtreeoption = "-H $HMMdir/dectree_dur.tree"
    endif
    HHEd -A -B -C $outdir/gen.conf -C $outdir/fullc.conf -D -V -T 1 -i -p -H $HMMdir/clustered.cmp.mmf -H $HMMdir/dectree_cmp.base $treeoption -w $outdir/clustered.cmp.mmf $outdir/trans.cmp.hed $HMMdir/context.cmp.list
    if ($duradapt == 1) then 
        HHEd -A -B -C $outdir/gen.conf -C $outdir/fullc.conf -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -H $HMMdir/dectree_dur.base $dtreeoption -w $outdir/clustered.dur.mmf $outdir/trans.dur.hed $HMMdir/context.dur.list
    else
        HHEd -A -B -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -w $outdir/clustered.dur.mmf $outdir/add.dur.hed $HMMdir/context.dur.list
    endif
    rm $outdir/pdf.*
    breaksw
case 5: # SEMIT
    HHEd -A -B -C $outdir/gen.conf -C $outdir/fullc.conf -D -V -T 1 -i -p -H $HMMdir/clustered.cmp.mmf.stc -H $HMMdir/dectree_cmp.base -H $HMMdir/SEMITIED -w $outdir/clustered.cmp.mmf $outdir/semit.cmp.hed $HMMdir/context.cmp.list
    HHEd -A -B -C $outdir/gen.conf -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -w $outdir/clustered.dur.mmf $outdir/add.dur.hed $HMMdir/context.dur.list
    rm $outdir/pdf.*
    breaksw
default:
    echo "Unknown transforms"
    break
endsw

# Do parameter geneation
if (( -e $HMMdir/nosil-gv.mmf ) || ( -e $HMMdir/nosil-logspec-gv.mmf )) then
    HMGenS $hmgenopt -r 1.0 -A -B -C $outdir/nosilgv-gen.conf -D -V -T 1 -c $gentype -S $outdir/synlabel.dat -H $outdir/clustered.cmp.mmf -N $outdir/clustered.dur.mmf -M $outdir $outdir/context.lst $outdir/context.lst 
else
    HMGenS $hmgenopt -r 1.0 -A -B -C $outdir/gen.conf -D -V -T 1 -c $gentype -S $outdir/synlabel.dat -H $outdir/clustered.cmp.mmf -N $outdir/clustered.dur.mmf -M $outdir $outdir/context.lst $outdir/context.lst 
endif

foreach lab ($lablist)
    set f0    = $outdir/$lab:t:r.f0
    set mcep  = $outdir/$lab:t:r.mcep
    set sspec = $outdir/$lab:t:r.spec
    set apf   = $outdir/$lab:t:r.apf
    set wav   = $outdir/$lab:t:r.wav

    x2x -o +fd $apf  > $apf.double
    # F0 transform
    switch ($f0scale)
    case 1: 
        x2x -o +fa $f0 | awk '$1==-1e+10{printf "0.0\n"}$1!=-1e+10{printf "%f\n",exp($1)}' > $f0.txt
        breaksw
    case 2: 
        x2x -o +fa $f0 | awk '$1==-1e+10{printf "0.0\n"}$1!=-1e+10{printf "%f\n",exp(log('"${lambda}"'*$1+1)/'"${lambda}"')}' > $f0.txt
        breaksw
    case 3: 
        x2x -o +fa $f0 | awk '$1==-1e+10{printf "0.0\n"}$1!=-1e+10{printf "%f\n", 700*(exp($1/1127)-1)}' > $f0.txt
        breaksw
    case 4: 
        x2x -o +fa $f0 | awk '$1==-1e+10{printf "0.0\n"}$1!=-1e+10{printf "%f\n", ((exp($1/21.4 *log(10))-1)/0.00437)}' > $f0.txt
        breaksw   
    default:
    echo "Unknown scale"
    break
    endsw

    echo "Moving median filter (1st)" 
    x2x -o +af $f0.txt | delay -s 1 -f | x2x -o +fa >! $f0.delay
    echo "0.000000" > ! $f0.zero
    x2x -o +af $f0.txt | bcut +f -s 1 | x2x -o +fa | cat - $f0.zero >! $f0.shift 
    paste $f0.delay $f0.txt $f0.shift | gawk -f $outdir/max.awk >! $f0.median

    echo "Moving median filter (2nd)"
    x2x -o +af $f0.median | delay -s 1 -f | x2x -o +fa >! $f0.delay
    echo "0.000000" > ! $f0.zero
    x2x -o +af $f0.median | bcut +f -s 1 | x2x -o +fa | cat - $f0.zero >! $f0.shift
    paste $f0.delay $f0.median $f0.shift | gawk -f $outdir/max.awk >! $f0.median2

    echo "Moving mean (linear) filter"
    x2x -o +af $f0.median2 | delay -s 1 -f | x2x -o +fa >! $f0.delay
    x2x -o +af $f0.median2 | bcut +f -s 1 | x2x -o +fa | cat - $f0.zero >! $f0.shift
    paste $f0.delay $f0.median2 $f0.shift | gawk -f $outdir/smooth.awk >! $f0.smooth
    rm -f $f0.zero

end

# rm -f $outdir/context.lst $outdir/synlabel.dat $outdir/add.cmp.hed $outdir/add.dur.hed $outdir/trans.cmp.hed $outdir/trans.dur.hed $outdir/clustered.cmp.mmf $outdir/clustered.dur.mmf
# rm -f $outdir/gen.conf $outdir/fullc.conf
# rm -f $outdir/list.gv $outdir/*.win $outdir/*.dur 
# rm -f $outdir/bc.txt
