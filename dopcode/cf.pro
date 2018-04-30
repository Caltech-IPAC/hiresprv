pro cf,starname $
        , barydsst $
        , cfout,cfiod $
		, logfile=logfile $
        , obdsk=obdsk $
        , nik=nik $
        , psfpix=psfpix $
        , psfsig=psfsig
;This code drives the PSF and velocity analysis
;
;INPUT:
;   starname (input string)   Examples: '509' or '4983' or 'GL897'
;   bardsst  (input scalar)   Barycentric correction of the template
;OUTPUT:
;   cfout    (structure)       Information about each observation
;
;OPTIONAL but highly RECOMMENDED:
;   logfile (keyword string)  Specifies log-sheet file to be searched 
;			      rather than the default
;OPTIONAL:
;   cfiod    (structure)      Information about "Iodine" observations
;   first_tape (keyword string)
;                             Specifies that information is wanted
;                             only for observations starting with
;                             a particular tape, and all subsequent
;                             observations
;                             example:  first_tape='rb02'
;   tape     (keyword string or string array)
;			      Specifies a tape or set of tapes
;			      example:  tape='ra40'
;                             example:  tape=['rh50','rh51','rh52','rh53']
;   noi2     (keyword - on/off)  if "/noi2" invoked, the code will not
;		              bother getting I2 information associated
;		              with observations
;
;
;Created August 28, 1993  R.P.B.
;Modified May 1994
;Millions of comments added August 1995

c = 2.99792458d8                ;speed of who?
bnum=0                          ;counter
starname = str(starname)    ;trim blanks from starname
;if n_elements(tape) lt 1 then tape =['?'] else tape=[tape]


;reading iodines and observations from logsheets
;if n_elements(logfile) lt 1 then logfile=[fd0,fd1] 
;if 1-keyword_set(noi2) then $
;  rdbcvel,'iodine',cfiod,obdsk,logfile=logfile,/noprint,obdsk=obdsk, nik=nik

rdbcvel,starname $
		, cf     $
		, obdsk  $
		, logfile=logfile $
		, /noprint        $
		, nik=nik $
        , psfpix=psfpix $
        , psfsig=psfsig

dum=where(cf.obnm ne '?',bnum)
cf=cf(dum)
;end reading iodines and observations from logsheets
if n_elements(cfiod) gt 1 then begin
    dum=sort(cfiod.jd)  &  cfiod=cfiod(dum)
endif
if n_elements(cf) gt 1 then begin
    dum=sort(cf.jd)  &  cf=cf(dum)
endif
cf.z=(barydsst - cf.bc)/c       ;Doppler Z guess
dum=where(cf.dewar ne -1,bnum)
if bnum gt 0 then cf=cf(dum) else begin
    print,'No matching observations for star: '+starname
    print,'For tapes: '+tape
    retall
endelse

cfout=cf

end
