pro velplot, velst, timebin, dates, speed, errv, cai, nav, dumcf, $
             yrs=yrs, tspan=tspan, nocolor=nocolor, yra=yra, nobox=nobox, median=median,  $
             nosig=nosig, subtt=subtt, noplot=noplot, nozero=nozero, nave=nave, lzr=lzr,errcut=errcut,szfac=szfac,postscript=postscript,outfile=outfile,title=title,days=days,eps=eps, timetrim=timetrim, bincf=bincf,xrange=xrange,psym=psym

;
;Plot Radial Velocity vs. Time, based on data in VST structure.
;VST structure is generated in VEL.PRO
;
;INPUT:
;  velst  (input structure)  from VEL.PRO.  Contains Time of Obs (VELST.JD),
;                        mean and median velocities  (velst.mnvel, velst.mdvel)
;   
;OPTIONAL INPUT:
;  starname       (string)     Name of Star
;  timebin        (float)      Time interval (DAYS) to "bin" velocities
;  tspan          fltarr(2)    vector of starting and ending time (JD or yrs)
;  cai            float        Calcium IR triplet index
;
;OPTIONAL KEYWORDS:
;  yrs      (0 or 1)  /yrs  forces abscissa to be in years, not JD   
;  nocolor  (0 or 1)  /nocolor for a monochrome terminal
;  nosig    (0 or 1)   if nosig eq 0 then standard default, else don't xyout,sig
;  nobox    (0, 1, 2)  if nobox eq 0 then standard default
;                      if nobox eq 1 then don't plot the timebin averages
;                      if nobox eq 2 then don't plot the error bars
;  errcut   (real, 1.5 or 2 or 2.5) toss points with cf.errvel worse than (errcut)*median(cf.errvel)
;
if 1-keyword_set(psym) then psym = 6
IF n_params () lt 1 then begin
    print,'Syntax: '
    print,' VELPLOT,velst, [starname, timebin (days), dates, speed, errv], yrs=yrs, tspan=[start,end],nocolor=nocolor'
    return
ENDIF

if n_elements(szfac) lt 1 then szfac=1.
dd=velst.jd

if min(dd) gt 2440000. then dd=dd-2440000. ;reduced JD
;	

av = velst                      ;Protect Structure containing results from VEL.PRO
tagnam=tag_names(av)
obdex=first_el(where(tagnam eq 'OBNM'))
if obdex eq -1 then obdex=first_el(where(tagnam eq 'OBNAM'))

IF n_elements(nave) eq 1 then if nave eq 1 then begin ;apply nightly corrections
    print,'Making **Primitive** Nightly Correction'
    print,'here here here'
    rascii,nave,4,'~/idle/vel/nave.ascii',skip=1
    for n=0,n_elements(av)-1 do begin
        nnd=minloc(abs(reform(nave(0,*)) - dd(n)),/first) ;make correction
        if abs(dd(n)-nave(0,nnd)) lt 0.6 then av(n).mnvel=av(n).mnvel-nave(1,nnd) $
        else print,'No nightly correction for the night of: '+strtrim(dd(n),2)
    endfor
ENDIF

vel = av.mnvel
errvel = av.errvel
cat = intarr(n_elements(errvel)) ;CAT initially set to 0
cair = av.sp1                   ;Calcium IR triplet index
obnm0 = av.obnm

if keyword_set(median) then vel=av.mdvel
if not keyword_set(nozero) then vel=vel-median(vel)
numobs = n_elements(av.jd)
if n_elements(starname) lt 1 then starname=' '
if n_elements(timebin) ne 1 then timebin=0
if n_elements(nobox) ne 1 then nobox=0
if n_elements(nosig) ne 1 then nosig=0
if n_elements(subtt) ne 1 then subtt=' '
;

;TIME MATTERS (ABSCISSA: JD or years, TIMEBIN UNITS)
xarr = av.jd
xarrorig = xarr
xtit = '!6 Julian Date - 2440000'
timetrim = 0.
prepost=9675.                   ;pre/post Julian Date
IF keyword_set(yrs) then begin  ; YEARS?
    prepost=1994.87             ;pre/post year
    xarr = 1987. + (xarr - 6796.5)/365.25 ;1987.0 = 2446796.5 JD
    xtit = '!6Time (Years)'
    timebin = timebin/365.25    ;timebin in yrs.
    if ( max(xarr) - min(xarr) ) lt 2.5 then begin
        xtit='!6Time  (Year-'+strtrim(fix(min(xarr)),2)+')'
        prepost=prepost-fix(min(xarr))
        xarr=xarr-fix(min(xarr))
    endif
endif else if max(xarr) lt (min(xarr) + 300) then begin ; <300 days?
    dum = fix(xarr(0)/100) * 100
    timetrim = dum              ;time trimmed off original JD's
    xarr = av.jd-dum
    dumst = strtrim(string(2440000+dum),2)
    xtit = '!6 Julian Date - '+dumst
ENDIF
if keyword_set(days) then begin
    xarr = xarrorig
    dum = fix(xarr[0])
    xarr = xarr-dum
    dumst = strtrim(string(2440000+dum),2)
    xtit = '!6 Julian Date - '+dumst
endif
t0 = long(min(xarr))
if max(av.jd) lt (min(av.jd)+1) then begin ; <1 day?
    xt = 'Julian Date + '+strtrim(long(2440000)+long(min(av.jd)),2)
    timetrim = min(av.jd)
    xarr = av.jd - min(av.jd)
endif
;PLOT CHARACTERISTICS
;      !p.charsize=1.5
;      !p.thick=2
yt='!6Velocity  (m s!e-1!n)'
starname = '!6'+string(starname) ;make duplex Roman Font
dt = max(xarr) - min(xarr)      ;time range
if keyword_set(xrange) then xr = xrange else xr = [min(xarr)-0.05*dt, max(xarr)+0.05*dt ] ;plot limits
if keyword_set(tspan) then xr = tspan
yr = [-100,100]
if max(vel + errvel) gt yr(1) or min(vel - errvel) lt yr(0) then $
  yr = [min(vel-errvel)-10, max(vel+errvel)+10]
yr = [-1,1]*((max(abs(vel)+errvel))+5)
;      if max(yr) lt max(vel) then yr=yr+10   ;PB kludge, 24 Sept 1997
if n_elements(yra) eq 2 then yr = yra
a=findgen(32) * (!pi*2/32.)
usersym,cos(a),sin(a),/fill     ;circle plot sym #8
;
;COLOR SETTINGS
IF not keyword_set(nocolor) then BEGIN ;for Color Monitor
;     loadct,13
    col = [100, 180, 80, 90, 260, 240, 141]
END ELSE begin
;     loadct,0
    col = [300, 300, 300, 300, 300, 300] ;for B+W Monitor
ENDELSE
;

nocolor=1
if 1-keyword_set(outfile) then outfile='/home/johnjohn/velplot.ps'
if keyword_set(postscript) then begin
    psopen,outfile,xs=9,ys=7,/inch,enc=eps
    PLOT, xarr, vel, xtit=xtit, ytit=yt, titl=title,charsize=2, $
          xr=xr, yra=yr, /xsty, /ysty, psym=psym,syms=0.4*szfac, subtitle=subtt $
          , xthick=5, ythick=5, charth=3, /nodata
    sharpcorners, thick=5
    xyoutth=2
endif else begin
    if 1-keyword_set(noplot) then $
      PLOT, xarr, vel, xtit=xtit, ytit=yt, titl=title,charsize=2, /nodata, $
            xr=xr, yra=yr, /xsty, /ysty, psym=psym,syms=0.4*szfac, subtitle=subtt 
endelse
;TELESCOPE OVERPLOT
for qq=0,n_elements(cat)-1 do begin
    dum=chip(av(qq).(obdex),gain,telescope)
    if telescope eq 'CAT' then cat(qq)=1
endfor

sigall = stdev(vel)
xo = max(xarr)-0.35*dt
dy = yr(1) - yr(0)
yo = yr(1) - 0.07*dy
text = strmid(strtrim(sigall,2),0,4)+' ms!u-1!n'
;   IF not keyword_set(nocolor) then !p.color=!white
if 1-keyword_set(noplot) then begin
    if szfac eq 1 then if nosig eq 0 and 1-keyword_set(postscript) then $
      XYOUTS,xo,yo,'!7r!6!d ALL!n ='+ text,size=1.5*szfac, charth=xyoutth
    print,format='(a15,F6.2,a4)','Sigma (all) = ',sigall,' m s!u-1!n'
endif
;   oplot,[xo-0.025*dt],[yo+0.007*dy],psym=8,syms=1.2
;   oplot,[xo-0.025*dt,xo-0.025*dt],[yo+0.04*dy,yo-0.03*dy]


;TIME BINS
IF timebin eq 0 then timebin = 1.e-8 ;tiny time bin
;   IF timebin gt 0 then begin
ct=0

WHILE ct lt numobs do begin
    ind = where(xarr ge xarr(ct) and xarr lt xarr(ct)+timebin, num) 
    wt = (1./errvel(ind))^2.    ;weights based in internal errors
    wt = wt/total(wt)           ;normalized weights
    if ct eq 0 then catday = [max(cat(ind))] $
    else catday = [catday,max(cat(ind))]
    if ct eq 0 then nav = [n_elements(ind)] $
    else nav = [nav,n_elements(ind)]
    if ct eq 0 then dates = [total(xarr(ind)*wt)]      $
    else dates = [dates,total(xarr(ind)*wt)]
    if ct eq 0 then speed = [total(vel(ind)*wt)] $
    else speed=[speed,total(vel(ind)*wt)]
    if ct eq 0 then counts = [total(av(ind).cts)] $
    else counts = [counts,total(av(ind).cts)]
    if ct eq 0 then cai = [total(cair(ind)*wt)] $
    else cai=[cai,total(cair(ind)*wt)]
    if ct eq 0 then obnm = obnm0[ind[0]] else obnm = [obnm, obnm0[ind[0]]]
    if ct eq 0 then begin
        inverr=0. & for qq=min(ind),max(ind) do inverr=inverr+1./errvel(qq)^2.
        errv = [sqrt(1./inverr)]
    endif else begin
        inverr=0. & for qq=min(ind),max(ind) do inverr=inverr+1./errvel(qq)^2.
        errv = [errv,sqrt(1./inverr)]
    endelse
    ct=ct+num

END                             ;while
;print,'nav=',nav

badgate=0
if 1-keyword_set(errcut) then errcut=2.5
if n_elements(errcut) eq 1 then if errcut gt 0. then begin
    i0=where(dates lt prepost,ni0)
;        if ni0 eq 0 then return
    if ni0 gt 1 then begin
        dumz=where(errv ge (errcut*median(errv(i0))) and dates lt prepost)
        if dumz(0) ge 0 then begin
            baddate=dates(dumz)
            badspeed=speed(dumz)
            baderrv=errv(dumz)
            badgate=1
        endif
        dumx=where(errv lt (errcut*median(errv(i0))) and dates lt prepost)
        dates0=dates(dumx)
        speed0=speed(dumx)
        errv0=errv(dumx)
        counts0=counts(dumx)
        cai0=cai(dumx)
    endif                       ;ni0 gt 1

    i1=where(dates gt prepost,ni1)
    if ni1 gt 1 then begin
        dumz=where(errv ge (errcut*median(errv(i1))) and dates gt prepost)
        if dumz(0) ge 0 then begin
            if n_elements(baddate) gt 0 then baddate=[baddate,dates(dumz)] $
            else baddate=dates(dumz)
            if n_elements(badspeed) gt 0 then badspeed=[badspeed,speed(dumz)] $
            else badspeed=speed(dumz)
            if n_elements(baderrv) gt 0 then baderrv=[baderrv,errv(dumz)] $
            else baderrv=errv(dumz)
            badgate=1
        endif
        dumx=where(errv lt (errcut*median(errv(i1))) and dates gt prepost)
        if n_elements(dates0) gt 0 then dates=[dates0,dates(dumx)] else dates=dates(dumx)
        if n_elements(speed0) gt 0 then speed=[speed0,speed(dumx)] else speed=speed(dumx)
        if n_elements(errv0) gt 0 then errv=[errv0,errv(dumx)] else errv=errv(dumx)
        if n_elements(counts0) gt 0 then counts=[counts0,counts(dumx)] else counts=counts(dumx)
        if n_elements(cai0) gt 0 then cai=[cai,cai(dumx)] else cai=cai(dumx)
    endif else begin            ;if ni1 gt 1
        if n_elements(dates0) eq 0 then return
        dates=dates0
        speed=speed0
        errv=errv0
        counts=counts0
        cai=cai0
    endelse
endif

dumcf=replicate(av(0),n_elements(dates))
dumcf.jd     = dates + timetrim
dumcf.mnvel  = speed
dumcf.errvel = errv
dumcf.cts    = counts
dumcf.obnm = obnm[0:n_elements(dumcf)-1]
;     dumcf.sp1    = cai
;   endif   ;timebin

sigbin = stdev(speed)

if not keyword_set(noplot) then if nobox lt 1 then begin 
    if keyword_set(postscript) then begin
        OPLOTERROR, dates, speed, errv, psym=psym, symsize=1.5, /nohat, errth=3
    endif else OPLOTERROR, dates, speed, errv, psym=psym, /nohat,syms=1.5,thic=2
    If badgate eq 1 then begin
        OPLOTERROR, baddate, badspeed, baderrv, psym=7, symsize=1.3*szfac, thick=2 
        for bb=0,n_elements(baddate)-1 do begin
            bdd=[baddate(bb),baddate(bb)]
            bvv=[badspeed(bb)-baderrv(bb),badspeed(bb)+baderrv(bb)]
            IF keyword_set(nocolor) then OPLOT, bdd, bvv $
            ELSE OPLOT, bdd, bvv, thick=2,symsize=0.5*szfac
        endfor
    endif                       ;badgate
    ind=where(catday eq 1,nind)
    if nind gt 0 then if keyword_set(nocolor) then $
      OPLOT, dates(ind), speed(ind), psym=psym, symsize=1.3*szfac, thick=2 ELSE $
      OPLOT, dates(ind), speed(ind), psym=psym, symsize=1.3*szfac, thick=2


    text = strmid(strtrim(sigbin,2),0,4)+' ms!u-1!n'
;       IF not keyword_set(nocolor) then !p.color=!white
    if 1-keyword_set(postscript) then     yo = yo - 0.05*dy
    XYOUTS,xo,yo,'!7r!6!d BIN!n ='+ text,size=1.5*szfac
    print,format='(a15,F6.2,a4)','Sigma (binned) = ',sigbin,' m/s'
endif                           ; if not keyword_set(noplot), nobox lt 1 

;openw,4,'6623.dat'
;for jd instead of years, remove /yrs in the call to velplot
;for i=0,n_elements(speed)-1 do printf,4,dates(i)+timetrim,speed(i),errv(i)
;close,4 

if n_elements(errv) lt 2 then begin
    errv = av.errvel            ;error in the mean
    dates = xarr 
    speed = av.mnvel
    if n_elements(catday) ne n_elements(speed) then catday=fix(speed*0)
endif

if 0 then begin
    FOR j=0,n_elements(errv)-1 do begin
        err = errv(j)           ;error in the mean
        x = [dates(j), dates(j)]
        bar = [speed(j)-err, speed(j)+err]
        if nobox ne 2 then begin
            if keyword_set(postscript) then begin
                oplot,x, bar, thick=3 
            endif else oplot,x, bar
            if catday(j) eq 1 then $
              if not keyword_set(nocolor) then oplot,x, bar
        endif
    ENDFOR

endif
text = strmid(strtrim(median(errv),2),0,4)+' ms!u-1!n'
;if 1-keyword_set(postscript) then 
yo = yo - 0.05*dy
;yo = yo - 0.05*dy
if 1-keyword_set(noplot) then $
  XYOUTS,xo,yo,'!7r!6!d INT!n ='+ text,size=1.5*szfac,charth=xyoutth

if keyword_set(postscript) or keyword_set(lzr) then psclose
bincf = dumcf
return
end



