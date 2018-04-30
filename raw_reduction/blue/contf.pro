pro contf,s,c,sbin=sbin,nord=nord,frac=frac,plot=pl,edit=excl,term=t,mask=mask,$
		bot=bot
;Basri 7/88		DEFAULTS
;Valenti 7/15/93	Added mask keyword. Revamped interactive masking logic.
;Basri 1/94	Added BOT keyword to do bottom of spectrum rather than top
;Valenti 7/16/94	Commented out the oplot in the code segment where the
;			 mask is applied. There is existing software that
;			 uses this routine without the plot flag in which case
;			 a bare oplot will fail, fail, fail.
;Valenti 12/15/94	Replaced mean() with total() intrinsic.
if n_params() lt 2 then begin
  print,'contf,s,c [,sbin= ,nord= ,frac= ,plot= ,mask= ,/bot ,/edit ,/term]'
  print
  print,'Finds a continuum C,on a spectrum S.
  print,'SBINS:  # of bins used'
  print,'NORD:  order of the curve fitting (>6 is spline)'
  print,'FRAC:  the upper fraction points defined as cont '
  print,'PLOT:  plot keyword (1 on, 2 more info,0 off)'
  print,'MASK:  indicies of points to use (or used) in fit'
  print,'BOT:   if set then bottom of spectrum is fit
  print,'EDIT:  manuel editing by point (1 on, 0 off)'
  print,'TERM:  selects terminal version of point'
  print,'Default values: SBIN=10, NORD=3, FRAC=.15'
  return
endif
if not keyword_set(sbin) then sbin = 10 ;smaller if flat,bigger if curvy
if not keyword_set(nord) then nord = 3 	;smaller is simpler
if not keyword_set(frac) then frac = 0.15	;bigger for more points
if not keyword_set(pl) then pl = 0

;***set parameters
	len = n_elements(s)
	st = 0 
	w = lindgen(len)
	if pl eq 1 or keyword_set(excl) then begin
          ss = s
	  if n_elements(mask) gt 0 then begin
            ss = replicate(3*max(s), len)
            ss(mask)=s(mask)
          endif
          plot,w,ss,/xsty,/ynoz,max=2*max(s)
        endif
	mbin = fltarr(sbin) 
	mbw = mbin
	mid = 1			;affects how FRAC is interpreted(originally 2)

;Interactively construct a continuum mask, if "/edit" keyword is set.
  if keyword_set(excl) then begin	;true: must interactively mask
    cflags = replicate(1,len)		;init continuum flag (1=use, 0=exclude)
    print,'contf: Indicate left and right edges of regions to exclude.'
    print,'contf: Click above or below plot when all regions are marked.'

    point,w,s,px,py,ia			;get first edge
    while (py ge !y.crange(0)) $
      and (py le !y.crange(1)) do begin	;true: point in plot - not done
      point,w,s,px,py,ib		;get second edge
      i1 = (ia < ib) > 0		;get lower point - prevent edge error
      i2 = (ia > ib) < (len-1)		;get upper point - prevent edge error
      cflags(i1:i2) = 0			;unset continuum flag for chosen pixels
      point,w,s,px,py,ia		;get another first edge
    endwhile

    mask = where(cflags eq 1,nmask)	;indicies of continuum points to fit
  endif
    
;Mask out portions of spectrum, if a valid mask was passed or constructed.
  if n_elements(mask) gt 1 then begin	;true: valid mask exists
    wsec = w(mask)			;wavelengths of valid continuum points
    ssec = s(mask)			;valid continuum points
;Commented out by JAV 7/16/94. You can't expect me to already have a plot!
;   oplot,wsec,ssec-(max(s)/2.),line=1
  endif else begin			;else: use all points
    wsec = w				;just copy input spectrum
    ssec = s
  endelse
  len = n_elements(ssec)
  lb = long(len/sbin)

;***find continuum in each bin
	st = 0L
	bpt=lb*(1.-frac/mid)
	if keyword_set(bot) then bpt=lb*frac/mid
	for nbin =1,sbin do begin
		nd = st +lb -1
		wb = wsec(st:nd)   &   bin = ssec(st:nd)
		sorted = sort(bin)
		cnt = bin(sorted(bpt))
		cnw = wb(sorted(bpt))
		st = nd + 1
		mbin(nbin-1) = cnt   &   mbw(nbin-1) = cnw
	endfor
;***catch the end if not already gotten
	if st lt len-lb/3 then begin
		bin = ssec(st:len-1)
		wb = wsec(st:len-1)
		llb = len-1-st
		bpe=llb*(1.-frac/mid)
		if keyword_set(bot) then bpe=llb*frac/mid
		sorted = sort(bin)
		cnt = bin(sorted(bpe))
		cnw = wb(sorted(bpe))
		mbw = [mbw,cnw]   &   mbin = [mbin,cnt]
	endif
	if pl eq 1 then oplot,mbw,mbin,psym=6
	;oplot,wc,sc,psym=1
;***polynomial or spline fit to continuum
	npl = nord 
	x = mbw & y = mbin
	if nord le 6 then begin
		if nord ge sbin then npl = sbin-1
		nx = n_elements(x)
		mn = total(x)/nx   &   x=x - mn   &   wf=float(w-mn)
;		mn = mean(x)   &   x=x - mn   &   wf=float(w-mn)
		cf = poly_fit(x,y,npl,/double)	;call poly_fit(intrinsic)
		c = poly(double(wf),cf)		;call poly(user written)
		;print,cf
	endif else begin
		wf = float(w)
;		c = spline(x,y,wf)		;call spline
		c = fspline(x,y,wf)		;fast FORTRAN spline
	endelse
	if pl eq 1 then oplot,w,c,co=2
	if pl eq 2 then begin
	   !p.multi=[0,1,2]
	   plot,w,s,/ynoz
	   if keyword_set(excl) then oplot,wsec,ssec-.75e5,lines=1,co=2
	   oplot,mbw,mbin,psym=6,co=2
	   oplot,w,c,co=2

	   plot,w,s/c,/ynoz
	   !p.multi=0
	endif
	

end





