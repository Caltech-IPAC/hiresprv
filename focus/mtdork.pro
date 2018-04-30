pro   mtdork,fitsnm

;   rdfits,x,'/data/sdata7/hires3/09oct96/'+fitsnm+'.fits',h
   rdfits,x,'/data/sdata101/hires3/01dec96/'+fitsnm+'.fits',h
;   rdfits,x,'/data/sdata101/hires3/02dec96/'+fitsnm+'.fits',h
;   expt=fix(hdrdr(h,'EXPOSURE'))
   expt=fix(hdrdr(h,'ELAPTIME'))
   dum=hdrdr(h,'UT')
   hr=fix(strmid(dum,1,2))
   mn=fix(strmid(dum,4,2))
   sc=fix(strmid(dum,7,2))

   sc=sc+(expt/2.)
   if sc ge 60 then begin
      mnadd=fix(sc/60.)
      sc=sc-60.*mnadd
      mn=fix(mn+mnadd)
   endif
   if mn ge 60 then begin
      hradd=fix(mn/60.)
      mn=fix(mn-60.*hradd)
      hr=fix(hr+hradd)
   endif

hr=strtrim(string(hr),2)
min=strtrim(string(mn),2)
sec=strtrim(string(fix(sc)),2)
deltat=strtrim(string(fix(expt)),2)
;print,'UT BEGIN = ' + dum + ',  EXPOSURE = '+string(expt)
print,'*************************************************'
print,'*  File#       MIDTIME    Delta T'  
print,'*  '+fitsnm +'      ' +hr +':'+ min +':'+ sec +'    '+deltat  
print,'*************************************************'
print,' '
return
end
