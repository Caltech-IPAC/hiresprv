pro foc,avgpro,plt=plt,inpfile=inpfile,mark=mark, $
        findloc=findloc, pr=pr, jpeg = jpeg, coloff = coloff, rowoff = rowoff $
	,inpdir=inpdir 
;
; PURPOSE:
; Focussing Program for the Keck Observatory HIRES.

; If disk storage is off, thorium goes into 'path'+backup.fits

; Computes FWHM of each Thorium line (preselected), and the average FWHM.
; Uses Gaussian fitting to each selected thorium line.
; Currently runs only on COUDE.UCSC.EDU that has an IDL license.
;      print,'Warning:  Program does not work upstairs on UCSCLOC' & print,' '
;
; CALLING EXAMPLES:  IDL> foc,/plt            
;
; INPUTS:  
;       1.  Thorium Image must exist in:
;          /catbox.ccdtmp/scr.ccd    (on COUDE)
;          (Scratch file, /scratch/scr.ccd, upstairs not accessible.)
;       2.  Thorium line list must exist in: LINES.ASCII 
;
; OUTPUTS: 
;        To screen:  CCD position,  Avg. FWHM
;        x      columns of the line locations
;        fwhmx  FWHM (in dispersion direction)
;
; KEYWORDS: 
;       INPFILE   Invoke Alternative input file of Thorium (instead of scr)
;                 eg.,   foc,inpfile = '/data/d13.ccd'
;       /PLT       Invoke Plotting Diagnostics (strongly advised)
;       PR        Invoke Printing Diagnostics
;       /MARK     Marks positions of lines
;       /FINDLOC  Allows user to mark and store locations of th lines
;       /jpeg  make jpeg file of final plot
;    
; METHOD:
;       Thorium lines at prescribed pixel locations (given in
;       lines.ascii) are mashed and interpolated
;       by spline.  The FWHM is the number of pixels above the 
;       1/2 peak counts.  FW@10% is # of pixels above "LEVEL" (10%).
;       The ASYM is the displacement of the bisector at 10% relative
;       to that at 50%.

; HISTORY:  
;    24 Oct 1994, Create  G.Marcy,T.Misch,P.Butler
;    10 Jan 1995, Revised for Output of Peak Cts and FWHM and Saturation (GM)
;    14 Jan 1995, Revised for FW10% and Asymmetry parameter and Plotting
;    20 Feb 1995, Revised to do Gaussian fitting.
;    23 Oct 2004, JJ added INPDIR keyword. Specify the data directory and
;                 FOC will find the last file written, which is presumably
;                 the latest ThAr spectrum.
 fname = ' '
 ans = ' '
pr =  1
;
; read,'Enter CCD focus position:',focus
 ;
 ; For 3-m
 ; filename = '/scratch/scr.ccd'
;
 filename = '/catbox.ccdtmp/scr.ccd'

;;;JJ addition
if keyword_set(inpdir) then begin
	spawn,'ls -ltr '+inpdir,files,err
	nf = n_elements(files)
	line = files[nf-1]
	dum = strsplit(line,' ',/ext)
	nd = n_elements(dum)
	fn = inpdir + '/' + dum[nd-1]
endif
;;;end JJ addition

 ; 
 ;For Alternate input file
  IF keyword_set(inpfile) then filename = inpfile
;
; rdfits,im,filename

;New Section to read images in
if n_elements(fn) eq 0 then fn = inpfile

dum =  mrdfits(fn, 0, hd)
cofraw =  hdrdr(hd, 'COFRAW')
cafraw =  hdrdr(hd, 'CAFRAW')
cofhd =  'COFRAW='+string(cofraw)
cafhd =  'CAFRAW='+string(cafraw)
expt=hdrdr(hd,'EXPTIME')
print,cofhd
print,cafhd
hiraw, im, fn
;End new section
;
; FINDLINES,im,x,y,/silent            ;find x,y positions of Th-Ar lines
;
 ;RESTORE LINES for IODINE SET-UP
; rdsk,lines,'/u/user/gmarcy/focus/thlines.dsk'  ;old storage
;Use IDL program called, "rascii.pro" located in /u/usr/gmarcy/focus .

   print,'Using TH Positions for Keck/HIRES.'
   rascii,lines,2,'lines.ascii',skip=1    ;read ascii file 'lines.ascii'

 x = reform(lines(0,*))
 y = reform(lines(1,*))

;Fudge factors for lines.ascii (mostly for binning = 3)
x = x+1
yfac = 1./3.
yfud = 86
y=yfac*y
y = y+yfud


if keyword_set(coloff) then x =  x+coloff   ;offset for columns
if keyword_set(rowoff) then y =  y+rowoff   ;offset for rows

;MARK the LOCATIONS of the FOCUS Th LINES
!p.multi=0
if keyword_set(findloc) then mark=1

IF keyword_set(mark) then begin  
  !p.multi=0
  minim = median(im)
  xs=indgen(n_elements(im(*,0)))
  ys=indgen(n_elements(im(0,*)))
!p.charsize=1.8
  titl = '!6HIRES Thorium Lines and Locations of Focus Lines'
  yt='ROW #'
  xt='COL #'

;if keyword_set(mark) then begin 
  window, 1, xsize = 400,  ysize = 600, title = 'Whole Image'
  maxgray = 5000
  display, im, xs, ys, min = 950, max = maxgray, titl = titl, ytit = yt, xtit = xt, /psfine
  oplot, [0, 4096], [2200, 2200]
  oplot, [0, 4096], [4250, 4250]
  window, 0, xsize = 1000, ysize = 1200, title = 'Planet-Hunting PSF Focus'
  !p.charsize=1.3
  display,im,xs,ys,min=950,max=maxgray,titl=titl,ytit=yt,xtit=xt,/psfine
  oplot,x,y+2,ps=6,symsize=2,thick=1 ;boxes at LINE LOC's (+1 is kludge)

;Put Argon lines in for a Fail Safe locator

xarg =  [1197, 3524, 659, 1155, 1879, 2503]
yarg =  yfac*[5709, 5589, 5259, 4701, 5094, 4936]
yarg = yarg + yfud
oplot, xarg, yarg, ps = 4, syms = 5
xyouts, xarg(0)+100, yarg(0), 'Argon Lines', size = 1.5


; SPECIAL SECTION TO FIND LINE LOCATIONS OF NEW CCD
  IF keyword_set(findloc) then begin
;  Find Line Locations on a new CCD chip
    print, 'New Line Locations will be stored in lines.found '
    openw, 2, 'lines.found'
    nl = n_elements(x)          ;Final No. of Th lines
    sz = 7
    boxsz = sz*2+1              ;11 x 11 pixels around each Th line.
nl = 10
    FOR j = 0, nl-1 do begin
      oplot, [x(j)], [y(j)], ps = 6, symsize = 2
      cursor, a, b 
      c1 = a-sz  & c2 = a+sz
      r1 = b-sz  & r2 = b+sz
      box = float(im(c1:c2, r1:r2)) ;box within image containing Th line
      bckg = median([box(0, 0:boxsz-1), box(boxsz-1, 0:boxsz-1)]) ;lft, rt edges
      box = box - bckg          ;sub backgr
      mashcol = total(box, 1)   ;mashed cols w/i box
      mashrow = total(box, 2)   ;mashed rows
;     dum = max(mashcol,rowloc) & rowloc=fix(rowloc(0))+r1+.5
      dum = max(mashcol, rowloc) & rowloc = b ;kludge in cursor position
      dum = max(mashrow, colloc) 
;      help,colloc
      colloc = fix(colloc(0))+c1+.5
;      help,colloc
;stop
      printf, 2, colloc, rowloc
      print, colloc, rowloc
;      wait, 1
    END
    close, 2
  END                           ;END FIND LINE LOCATIONS
  read, 'Hit <RETURN> to proceed on: ', ans
END


;Set some Parameters
  sz=7                ;half width of box around lines
  boxsz = sz*2+1      ;11 x 11 pixels around each Th line.
  thresh = 60000      ;thresh for "saturated" signal to be sent.
  level = 0.1         ;level at which Full Width and Asymm are computed
  ind = findgen(boxsz)
  osamp = 50.                        ;oversample 50 subpixels per pixel
  finelen = (boxsz-1)*osamp          ;length of oversampled spectra
  finecen = 0.5*finelen
  fineind = findgen(finelen)/osamp   ;oversampled index
  numcol = dimen(im,0)               ;No. of col's
  numrow = dimen(im,1)               ;No. of rows
  xmid = numcol/2.                   ; middle col of chip
  ymid = numrow/2.                   ; middle row of chip
  nfound = 0
  a = fltarr(3)              ;gauss params: a(1)=cen, a(2)=sigma
print, 'numcol=', numcol
print, 'numrow=', numrow
;
IF keyword_set(plt) then begin
  !p.charsize=1.
  !p.multi = [0,2,2]
  window, 0, title = 'Planet-Hunting PSF Focus'

END
;
;Reject Th lines that lie too close to edges (within sz of edge)
  i = where(x gt sz and x lt numcol-boxsz and $
            y gt sz and y lt numrow-boxsz)     ;indices well within edges
  x = x(i) & y = y(i)      ;Use only Th lines well inside edge of CCD
  nl = n_elements(x)        ;Final No. of Th lines
;
;Initialize Some More Variables (that depend on the # of lines, nl)
  fwhmx = fltarr(nl)   ;FWHM in the COLUMN direction (= 1.18 sigma) 
  fwhmy = fltarr(nl)   ;FWHM in the ROW    direction
  fw10x = fltarr(nl)   ;FW at 10% of peak of each line
  asym  = fltarr(nl)   ;asymmetry index of each line 
  dx    =fltarr(nl)    ;found - expected column position
  dy    =fltarr(nl)    ;found - expected row position
  allprofs= fltarr(finelen,nl)       ;all Thorium profiles
  r     = sqrt((x-xmid)^2 + (y-ymid)^2)   ;radial distance from image center 
;
openw,1,'foc_printout'
if keyword_set(pr) then begin
  print,' '
  print,' ______________________________________________________________________ '
  print,'|  Column     Row   Peak Cts      FWHM    FW@10%    ASYM    Delta Col  |'  
  print,'|______________________________________________________________________|'
  printf,1,'|  Column     Row   Peak Cts      FWHM    FW@10%    ASYM    Delta Col  |'  
  printf,1,'|______________________________________________________________________|'
end
 form='(A1,I8,I8,I8,A3,F10.2,F10.2,F10.2,F10.2,A5)'
;
print, 'Nunber of lines:', nl

;LOOP THROUGH ALL LINES
;
FOR j = 0,nl-1 do begin                ;Loop through all nl lines
  c1 = x(j)-sz  & c2 = x(j)+sz
  r1 = y(j)-sz  & r2 = y(j)+sz
  box = float(im(c1:c2 , r1:r2))       ;box within image containing Th line
  bckg = median([box(0,0:boxsz-1),box(boxsz-1,0:boxsz-1)])   ;lft, rt edges
  box = box - bckg                     ;sub backgr
    mashcol = total(box,1)    ;mashed cols w/i box
    mashrow = total(box,2)    ;mashed rows
    dum = max(mashcol,rowloc) & rowloc=fix(rowloc(0)) ;rowloc is output loc
    dum = max(mashrow,colloc) 
    colloc=fix(colloc(0))
      col = fix(colloc+c1)
      row = fix(rowloc+r1)

;  IF abs(rowloc-sz) gt 4 or abs(colloc-sz) gt 4 then begin
  IF abs(rowloc-sz) gt 7 or abs(colloc-sz) gt 7 then begin
      col = fix(colloc+c1)
      row = fix(rowloc+r1)
;      cts = fix(im(colloc+c1,rowloc+r1))
      cts = im(colloc+c1,rowloc+r1)
      flag = ' NF'    ;line not found
      fwhmx(j) = 0. 
      fwhmy(j) = 0.
      dx(j)=0. & dy(j)=0.

      if keyword_set(pr) then begin
        print, format=form,'|', col, row , cts, flag,fwhmx(j),fw10x(j),dx(j),' |'
;        printf,1,format=form,'|', col, row , cts, flag,fwhmx(j),fw10x(j),dx(j),' |'
      end
      x(j)=-1   ;x(j)=-1 means line not found, for later rejection, PB 11/15/94
  ENDIF else begin 
;
;    omashcol = spline(ind,mashcol,fineind,3)    ; oversampled 
     omashrow = spline(ind,mashrow,fineind,3)     ; oversampled, mashed row 
;
; FWHM   (50% level)
; Use Gaussian to get height and width
;    a = fltarr(4)
    a(2) = 1.05

;New preparatory code for a(0), a(1); Nov 2005
    a(1) =  float(maxloc(mashrow))
    a(0) =  float(max(mashrow))
;    a=[10000.,sz,0.8]
    fit = gauss_fit(ind,mashrow,a)

;    gfit,ind,mashrow,fit,a
    fwhmx(j) = a(2) * 2.3548 ; a(2)*2.*sqrt(2.*alog(2.)) Convert sigma to FWHM
    mashrow = mashrow/a(0)        ;normalize height
    omashrow= omashrow/a(0)       ;normalize
;    indHM = where(omashrow ge 0.5*max(omashrow),num) ;indices where cts > .5*peak
    midfwhm = a(1) * osamp   ;peak loc. of Gaussian in osamp units
    colloc_precise = a(1) + c1  ;add back the column zero-point
;help,x(j)
;help,colloc_precise
;stop
    IF keyword_set(plt) then begin  ;plot each line fit.
      plot,ind,mashrow,ps=4,yr=[0,1.2],/ysty,syms=1.8
;      gaussian,fineind,a,fit  ;evaluate Gaussian on fine abscissa
      gausscon,fineind,a,fit  ;evaluate Gaussian on fine abscissa
      oplot,fineind,fit/a(0)
      xyouts,1,0.95,'c='+strtrim(fix(x(j)),2),size=1.3
      xyouts,1,0.85,'r='+strtrim(fix(y(j)),2),size=1.3
    END
;    if j/4. - j/4 gt 0.7 then wait, 1
;
; FW at 10%,  i.e., "level = 0.10"
    indlev = where(omashrow ge level,num) ;indices where cts > .1*peak
    fw10x(j) = num/osamp                      ;Full width at 10% peak

; ASYMMETRY:  Displacement (from peak location) of 10% bisector.
    if n_elements(indlev) ge 2 then begin
      midpt10 = 0.5*(indlev(0) + indlev(num-1)) ;midpoint of chord at level (10%)
      asym(j) = (midpt10 - midfwhm)/osamp    ;dist.to 10% Bisector
    endif else begin
      asym(j) =  0.
    endelse

;
; STORE PROFILES
    profsz = osamp*4
    cenprof = shift(omashrow,-1*(midfwhm-finecen))  ;Center profile w/ midFWHM
    allprofs(*,j) = cenprof    ;normalize to peak
;
;   Print diagnostics
      col = fix(colloc+c1)
      row = fix(rowloc+r1)
;     New: dx is computed using the Gaussian center;11Apr2006 GM
      dx(j) = colloc_precise - x(j)  ;found-expected, using Gaussian fit
;      dx(j) = colloc+c1 - x(j)  ;found - expected column position
      dy(j) = rowloc+r1 - y(j)  ;found - expected row position
      cts = max(box)
      flag='   ' & if cts gt thresh then flag='Sat'   ;Saturated???
   if keyword_set(pr) then begin
    print, format=form,'|', col, row , cts, flag,fwhmx(j),fw10x(j),asym(j),dx(j),' |'
    printf,1, format=form,'|', col, row , cts, flag,fwhmx(j),fw10x(j),asym(j),dx(j),' |'

   end
  ENDELSE                                       
END   ;end LOOP THROUGH ALL LINES
close,1
print, 'End of Loop.  Number of lines:', n_elements(fwhmx)
;
IF keyword_set(pr) then begin
  print,'|_____________________________________________________________|'
  print,'|   SAT = Saturated!                                          |'
  print,'|    NF = Line Not Found; rejected from AVG                   |'
  print,'|_____________________________________________________________|'
  print,' '
END
;
;Reject lines that could not be found above
  good = where(x gt 0,nl)
  x = x(good)
  y = y(good)
  fwhmx = fwhmx(good)
  ;fwhmy=fwhmy(good)
  fw10x = fw10x(good)
  asym = asym(good)
  allprofs = allprofs(*,good)
  dx = dx(good)
  dy = dy(good)
print, 'Number of good lines:', n_elements(x)
;
;Reject highest and lowest two values of FWHM 
  i = sort(fwhmx)    ;index of lowest, next lowest, etc fwhmx values
  itrim = i(2:nl-3)      ;indices of all but lowest 2 and highest 2 FWHM's.
  x = x(itrim)           ;Extract only the above lines
  y = y(itrim)           ;same as above
  fwhmx = fwhmx(itrim)   ;Extract the above lines only
  fw10x = fw10x(itrim)   ;Extract the above lines only
  asym = asym(itrim)     ;Extract the above lines only
  allprofs = allprofs(*,itrim) ; Extract as above
  dx = dx(itrim)
  dy = dy(itrim)
;
;Take AVERAGES
;  avgfwhmx = mean(fwhmx)
  avgfwhmx = median(fwhmx)
  avgfw10x = mean(fw10x)
  avgasym = mean(asym)
  avgpro = total(allprofs,2)
  avgpro = avgpro/max(avgpro)
;  avgdx = mean(dx)
  avgdx = median(dx)  ;new 11april 2006
  avgdy = mean(dy)
;
;Reference Gaussian
   xo = fineind(finecen)  ;center of Gaussian in CCD pixels units
   sig = 0.77 * 24./15.  ;in CCD pixels for HIRES upgrade
   gau= exp(-(fineind-xo)^2/(2.*(sig)^2))
;  rdsk,refpro,'refpro.dsk'
   
   dif = avgpro - gau
;   dif = avgpro - refpro
   sigdif = stdev(dif)
   sigdif = strtrim(strmid(string(sigdif),0,9),2)
h0 = 0.0268
h1 = 0.00892
h2 = 0.00217
h3 = 0.000913
;
;PRINT RESULTS
; print,' '
; print,format='(A25,A6)','      CCD Position =',strtrim(string(fix(focus)),2)
  print,' '
 print,'                Obtained   Acceptable'
 print,'--------------------------------------'
 print,format='(A15,F8.3,A13)','AVG FWHM =  ',avgfwhmx,'   2.30 - 2.40 (new HIRES)'
 print,format='(A15,F8.3,A13)','AVG FW@10%= ',avgfw10x,'   4 - 5'
 print,format='(A15,F8.3,A15)','ASYM:10%Bisect=',avgasym,'   -0.05 - 0.05'

print,'--------------------------------------'
print,' '

;
; if abs(avgdx) gt 1.0 then begin
  print,'Thorium lines sit',avgdx,' columns away from nominal  *'
  dxthresh = 0.5
 if abs(avgdx) gt dxthresh then begin
  print,' '
  print,'*******************************************************************'
  print,'*  WARNING: Thorium lines sit >',dxthresh,' columns away from nominal  *'
  print,'*******************************************************************'
  print,'   Move Echelle Grating Angle: ',(15./24.)*0.001*avgdx, ' deg (upgraded HIRES) .'
  end else begin
  print,''
  print,'  No Echelle Grating move needed.'
  print,' '
  endelse

 if abs(avgdy) gt 1.0 then begin
  print,' '
  print,'Warning:  Thorium lines sit',avgdy,' rows away from nominal'
;  print,'          Move X-Dispersor Angle: ',0.0023*avgdy,' degrees.'
  print,'          Move X-Dispersor Angle: ',(15./24.)*0.0023*avgdy,' degrees. (upgraded)'
 end
 focstat = sqrt((avgfwhmx-1.55)^2+avgASYM^2)
;
; print,format='(A29,F8.3)','Sqrt[(FWHM-1.55)^2+ASYM^2] =',focstat
IF keyword_set(plt) then begin
  !p.charsize=1.
  !p.multi = [0,2,2]
;  !p.color = 300
;
; FWHM vs Column
  titl='!6FWHM  vs  Column#'
  xtit='!6 Column'
  ytit='!6 FWHM (pixels)'
  yr=[min(fwhmx)-.1,max(fwhmx)+.3]
  i = sort(fwhmx)
  nel = n_elements(fwhmx)
  yr(0) =  fwhmx(i(4))
  yr(1) =  fwhmx(i(nel-5))
  del = yr(1)-yr(0)
  yr(0) = yr(0)-0.5*del
  yr(1) =  yr(1)+0.5*del
  if yr(0) lt 1 then yr(0) =  1
  if yr(1) gt 6 then yr(1) =  6

  plot,x,fwhmx,ps=4,titl=titl,xtit=xtit,ytit=ytit,/ysty,yr=yr,/xsty
  xp = .5*max(x)
  del =  yr(1)-yr(0)
  yp = yr(1)-0.07*del  ;-.05*(max(fwhmx)-min(fwhmx))
  st = '!6<FWHM>='+strmid(strtrim(string(avgfwhmx),2),0,5)
  xyouts,xp, yp,st,size=1.4
;
; FW10% vs Column
  titl='!6FW@10% vs  Column#'
  xtit='!6 Column'
  ytit='!6 FW@10% (pixels)'
  yr=[min(fw10x)-.2,max(fw10x)+.2]
  yr = [2.5, 7.5]
  plot,x,fw10x,ps=4,titl=titl,xtit=xtit,ytit=ytit,/ysty,yr=yr,/xsty
  yp = max(fw10x)+.04  ;-.05*(max(fwhmx)-min(fwhmx))
  st = '!6<FW10%>='+strmid(strtrim(string(avgfw10x),2),0,5)
;  oldc = !p.color & !p.color=270
  xyouts,xp, yr(1)-.5,st,size=1.4
;  xyouts,400,yp-0.3,'Hermite #3 = '+string(h3),size=1.4
;  !p.color = oldc
;
; ASYMMETRY vs Column
  titl='!6ASYMMETRY (10% Bisector) vs  Column#'
  xtit='!6 Column'
  ytit='!6 Displacement of Bisector at 10%'
  yr=[min(asym)-.1,max(asym)+.1]
  yr=[-1.25, 1.25]
  plot,x,asym,ps=4,titl=titl,xtit=xtit,ytit=ytit,/ysty,yr=yr,/xsty
;  oldc = !p.color & !p.color=270
  xyouts,xp,yr(1)-0.1*(yr(1)-yr(0)),'Asym=' + strtrim(strmid(string(avgasym),2,7 ), 2),size=1.4
;  !p.color = oldc
;
  ti='!6MEAN THORIUM LINE' 
  xt='!6 Pixel'
  yt='!6 CTS'
  xra=[-5,5]

;   sampind = indgen(4.*finelen/osamp)*osamp/4.
   plot,fineind-sz,avgpro,titl=ti,xtit=xt,ytit=yt,$
     xr=xra,/xsty,yr=[-.1,1],/ysty,thick=3
   oplot,[.8,.95],[.9,.9],thick=3
   xyouts,1.,.89,'!6Mean Line',size=1.3

; Reference Profile (stored from July 15, 1995)
   oplot,fineind-sz,gau,thick=.3
   oplot,[.8,.95],[.8,.8],thick=.3 
   xyouts,1.,.79,'Ref. Prof.',size=1.3

xyouts, -4.8, 0.85, cofhd
xyouts, -4.8, 0.7, cafhd

ENDIF  ;end plotting section
tvlct, r, g, b, /get
len =  strlen(fn)
fn =  strmid(fn, 0, len-5)
plotfile =  fn + '_foc.png'
;write_png, plotfile, tvrd(true = 1), r, g, b
;spawn, 'open '+plotfile

end













































































