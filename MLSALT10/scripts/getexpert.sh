#! /bin/tcsh -f

if ($# == 0) then
    echo "usage: getexpert.sh -hmmdir hmmdir -labdir labeldir -stream stream -dimension dim -outdir outdir -filename filename"
    exit
endif

while ( $#argv )
  switch ( $1 )
     case -hmmdir:
       set HMMdir = $2; shift; breaksw
     case -labdir:
       set labdir = $2; shift; breaksw
     case -filename:
       set filename = $2; shift; breaksw
     case -stream:
       set stream = $2; shift; breaksw
     case -outdir:
       set outdir = $2; shift; breaksw
     case -dimension:
       set dim = $2; shift; breaksw
     default:
       echo "Incorrect option $1"
       exit 1
       break
  endsw
  shift
end

set path = ( /usr/local/teach/MLSALT10/Practical/htk/HTKTools /usr/local/teach/MLSALT10/Practical/bin  $path )

mkdir -p $outdir/lib

awk '{print $NF}' $labdir/${filename}.lab > $outdir/${filename}.list
sort $outdir/${filename}.list | uniq > $outdir/${filename}.cntxt

cat <<EOF >! $outdir/lib/${filename}.cmp.hed 
 LT $HMMdir/tree.mcep.inf 
 LT $HMMdir/tree.logF0.inf
 LT $HMMdir/tree.bndap.inf
 AU $outdir/${filename}.cntxt
EOF

cat <<EOF >! $outdir/lib/${filename}.dur.hed
 LT $HMMdir/tree.dur.inf
 AU $outdir/${filename}.cntxt
EOF

set LOG=$outdir/${filename}.LOG

# do the generation of the contxt to synthesis
HHEd -C /usr/local/teach/MLSALT10/Practical/lib/cfgs/local.cfg -B -A -D -V -T 1 -i -p -H $HMMdir/clustered.cmp.mmf -w $outdir/${filename}.tmp.cmp.mmf $outdir/lib/${filename}.cmp.hed $HMMdir/context.cmp.list > $LOG
HHEd -C /usr/local/teach/MLSALT10/Practical/lib/cfgs/local.cfg -B -A -D -V -T 1 -i -p -H $HMMdir/clustered.dur.mmf -w $outdir/${filename}.tmp.dur.mmf $outdir/lib/${filename}.dur.hed $HMMdir/context.dur.list >> $LOG

# remove all the extra states
HHEd -C /usr/local/teach/MLSALT10/Practical/lib/cfgs/local.cfg -A -D -V -T 1 -i -p -H $outdir/${filename}.tmp.cmp.mmf -w $outdir/${filename}.cmp.mmf /dev/null $outdir/${filename}.cntxt >> $LOG
HHEd -C /usr/local/teach/MLSALT10/Practical/lib/cfgs/local.cfg -A -D -V -T 1 -i -p -H $outdir/${filename}.tmp.dur.mmf -w $outdir/${filename}.dur.mmf /dev/null $outdir/${filename}.cntxt >> $LOG

# and tidy the large models
rm -rf ${outdir}/${filename}.tmp.{cmp,dur}.mmf

# and now extract the experts
python scripts/getexpert.cmp.py  ${outdir}/${filename}.cmp.mmf $stream $dim $outdir/${filename}.list ${outdir}/${filename}.cmp.expt
python scripts/getexpert.dur.py  ${outdir}/${filename}.dur.mmf $outdir/${filename}.list ${outdir}/${filename}.dur.expt

