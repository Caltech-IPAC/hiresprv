;print,"Enter star name: "
;read,starname,''

path = getenv("DOP_RV_OUTDIR")+'vst'
name=' '
read,'Star Name:',name
restore,path+name+'.dat'
