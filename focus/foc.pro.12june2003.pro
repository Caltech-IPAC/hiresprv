pro foc,avgpro,plt=plt,dewar6=dewar6,inpfile=inpfile,mark=mark, $
        findloc=findloc, pr=pr
;
; PURPOSE:
; Focussing Program for the Keck Observatory HIRES.

; If disk storage is off, thorium goes into 'path'+backup.fits

; Computes FWHM of each Thorium line (preselected), and the average FWHM.
; Uses Gaussian fitting to each selected thorium line.
; Currently runs only on COUDE.UCSC.EDU that has an IDL license.
;      print,'Warning:  Program does not work upstairs on UCSCLOC' & print,' '
;
; CALLING EXAMPLES:  IDL> foc,/plt             (for dewar #13 line locations)
;                    IDL> foc,/plt,/dewar6     (for dewar #6 line locations)
;
; INPUTS:  
;       1.  Thorium Image must exist in:
;          /catbox.ccdtmp/scr.ccd    (on COUDE)
;          (Scratch file, /scratch/scr.ccd, upstairs not accessible.)
;       2.  Thorium line list must exist in: LINES.ASCII or LINES.DEWAR6
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
;       /DEWAR6   Invokes the DEWAR #6 Thorium locations.    
;       /MARK     Marks positions of lines
;       /FINDLOC  Allows user to mark and store locations of th lines
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
;
 fname = ' '
 ans = ' '
;
; read,'Enter CCD focus position:',focus
 ;
 ; For 3-m
 ; filename = '/scratch/scr.ccd'
;
 filename = '/catbox.ccdtmp/scr.ccd'
 ;For CAT
;  if keyword_set(cat) then filename = '/catbox.ccdtmp/scr.ccd'
 ; 
 ;For Alternate input file
  IF keyword_set(inpfile) then filename = inpfile
;
 rdfits,im,filename

;
; FINDLINES,im,x,y,/silent            ;find x,y positions of Th-Ar lines
;
 ;RESTORE LINES for IODINE SET-UP
; rdsk,lines,'/u/user/gmarcy/focus/thlines.dsk'  ;old storage
;Use IDL program called, "rascii.pro" located in /u/usr/gmarcy/focus .

if keyword_set(dewar6) then begin
   print,'Using  Dewar 6 Th Positions and Reversing Image L-R'
   rascii,lines,2,'lines.dewar6',skip=1 
   im = reverse(im,1)
end else begin
   print,'Using TH Positions for Keck/HIRES.'
   rascii,lines,2,'lines.ascii',skip=1    ;read ascii file 'lines.ascii'
end
 x = reform(lines(0,*))
 y = reform(lines(1,*))
;Kludge to keep box locations consistent with July 10, 1996.
y = y - 1.
; y = 0.5*y
;end kludge
;

;MARK the LOCATIONS of the FOCUS Th LINES
!p.multi=0
if keyword_set(findloc) then mark=1
IF keyword_set(mark) then begin  window,0,xsize=1000,ysize=600,title='Planet-Hunting PSF Focus'
  !p.multi=0
  minim = median(im)
  xs=indgen(n_elements(im(*,0)))
  ys=indgen(n_elements(im(0,*)))
!p.charsize=1.8
  titl = '!6HIRES Thorium Lines and Locations of Focus Lines'
  yt='ROW #'
  xt='COL #'
 ; display,im(*,400:999),xs,ys,min=minim,max=500,titl=titl,ytit=yt,xtit=xt
  ;!p.color=300
  ;display,im,xs,ys,min=880,max=970,titl=titl,ytit=yt,xtit=xt
  ;loadct,0
  ;display,im,xs,ys,min=950,max=1500,titl=titl,ytit=yt,xtit=xt
  !p.charsize=1.3
  display,im,xs,ys,min=950,max=1500,titl=titl,ytit=yt,xtit=xt,/psfine
  oplot,x,y+2,ps=6,symsize=2,thick=1 ;boxes at LINE LOC's (+1 is kludge)
;  oplot,x,y+2,ps=6,symsize=1.8,thick=2 ; at LINE LOC's (+1 is kludge)
;  oplot,x,y+2,ps=6,symsize=1.8,thick=2 ;at LINE LOC's (+1 is kludge)
;loadct,13
;  oplot,x,y+2,ps=6,symsize=1.8,thick=2,co=20
; SPECIAL SECTION TO FIND LINE LOCATIONS OF NEW CCD
   IF keyword_set(findloc) then begin
;  Find Line Locations on a new CCD chip
   print,'New Line Locations will be stored in lines.found '
   openw,2,'lines.found'
   nl = n_elements(x)        ;Final No. of Th lines
   sz = 7
   boxsz = sz*2+1      ;11 x 11 pixels around each Th line.
   FOR j=0,nl-1 do begin

     oplot,[x(j)],[y(j)],ps=6,symsize=2
     cursor,a,b 
     c1 = a-sz  & c2 = a+sz
     r1 = b-sz  & r2 = b+sz
     box = float(im(c1:c2 , r1:r2))       ;box within image containing Th line
     bckg = median([box(0,0:boxsz-1),box(boxsz-1,0:boxsz-1)])   ;lft, rt edges
     box = box - bckg                     ;sub backgr
     mashcol = total(box,1)    ;mashed cols w/i box
     mashrow = total(box,2)    ;mashed rows
;     dum = max(mashcol,rowloc) & rowloc=fix(rowloc(0))+r1+.5
     dum = max(mashcol,rowloc) & rowloc=b  ;kludge in cursor position
     dum = max(mashrow,colloc) & colloc=fix(colloc(0))+c1+.5
     printf,2,colloc,rowloc
     print,colloc,rowloc
     wait,1
   END
   close,2
   END      ;END FIND LINE LOCATIONS
read,'Hit <RETURN> to proceed on: ',ans
END


;Set some Parameters
  sz=7                ;half width of box around lines
  boxsz = sz*2+1      ;11 x 11 pixels around each Th line.
  thresh = 25000      ;thresh for "saturated" signal to be sent.
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
;
IF keyword_set(plt) then begin
  !p.charsize=1.
  !p.multi = [0,2,2]
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
if keyword_set(pr) then begin
  print,' '
  print,' _____________________________________________________________ '
  print,'|  Column     Row   Peak Cts      FWHM    FW@10%    ASYM      |'  
  print,'|_____________________________________________________________|'
end
 form='(A1,I8,I8,I8,A3,F10.2,F10.2,F10.2,A5)'
;
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
    dum = max(mashrow,colloc) & colloc=fix(colloc(0))
;
  IF abs(rowloc-sz) gt 4 or abs(colloc-sz) gt 4 then begin
      col = fix(colloc+c1)
      row = fix(rowloc+r1)
      cts = fix(im(colloc+c1,rowloc+r1))
      flag = ' NF'    ;line not found
      fwhmx(j) = 0. 
      fwhmy(j) = 0.
      dx(j)=0. & dy(j)=0.

      if keyword_set(pr) then begin
        print, format=form,'|', col, row , cts, flag,fwhmx(j),fw10x(j),' |'
      end
      x(j)=-1   ;x(j)=-1 means line not found, for later rejection, PB 11/15/94
  ENDIF else begin 
;
;    omashcol = spline(ind,mashcol,fineind,3)    ; oversampled 
     omashrow = spline(ind,mashrow,fineind,3)     ; oversampled, mashed row 
;
; FWHM   (50% level)
; Use Gaussian to get height and width
    fit = gauss_fit(ind,mashrow,a)
    fwhmx(j) = a(2) * 2.3548 ; a(2)*2.*sqrt(2.*alog(2.)) Convert sigma to FWHM
    mashrow = mashrow/a(0)        ;normalize height
    omashrow= omashrow/a(0)       ;normalize
    indHM = where(omashrow ge 0.5*max(omashrow),num) ;indices where cts > .5*peak
    midfwhm = a(1) * osamp   ;peak loc. of Gaussian in osamp units
    IF keyword_set(plt) then begin  ;plot each line fit.
      plot,ind,mashrow,ps=8,yr=[0,1.2],/ysty,syms=1.8
      gaussian,fineind,a,fit  ;evaluate Gaussian on fine abscissa
      oplot,fineind,fit/a(0)
      xyouts,1,0.95,'c='+strtrim(fix(x(j)),2),size=1.3
      xyouts,1,0.85,'r='+strtrim(fix(y(j)),2),size=1.3
    END
    if j/4. - j/4 gt 0.7 then wait,1
;
; FW at 10%,  i.e., "level = 0.10"
    indlev = where(omashrow ge level,num) ;indices where cts > .1*peak
    fw10x(j) = num/osamp                      ;Full width at 10% peak
    midlev = 0.5*(indlev(0) + indlev(num-1))  ;midpoint of chord at level (10%)

; ASYMMETRY:  Displacement (from peak location) of 10% bisector.
    asym(j) = (midlev - midfwhm)/osamp    ;dist.to 10% Bisector
;
; STORE PROFILES
    profsz = osamp*4
    cenprof = shift(omashrow,-1*(midfwhm-finecen))  ;Center profile w/ midFWHM
    allprofs(*,j) = cenprof    ;normalize to peak
;
;   Print diagnostics
      col = fix(colloc+c1)
      row = fix(rowloc+r1)
      dx(j) = colloc+c1 - x(j)  ;found - expected column position
      dy(j) = rowloc+r1 - y(j)  ;found - expected row position
      cts = fix(max(box))
      flag='   ' & if cts gt thresh then flag='SAT'   ;Saturated???
   if keyword_set(pr) then begin
    print, format=form,'|', col, row , cts, flag,fwhmx(j),fw10x(j),asym(j),' |'
   end
  ENDELSE                                       
END   ;end LOOP THROUGH ALL LINES
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
  avgfwhmx = mean(fwhmx)
  avgfw10x = mean(fw10x)
  avgasym = mean(asym)
  avgpro = total(allprofs,2)
  avgpro = avgpro/max(avgpro)
  avgdx = mean(dx)
  avgdy = mean(dy)
;
;Reference Gaussian
   xo = fineind(finecen)  ;center of Gaussian in CCD pixels units
   sig = 0.77  ;in CCD pixels
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
 print,format='(A15,F8.3,A13)','AVG FWHM =  ',avgfwhmx,'   1.7 - 1.8 (HIRES)'
 print,format='(A15,F8.3,A13)','AVG FW@10%= ',avgfw10x,'   3 - 4'
 print,format='(A15,F8.3,A15)','ASYM:10%Bisect=',avgasym,'   -0.05 - 0.05'

print,'--------------------------------------'
print,' '

;
;
 if abs(avgdx) gt 1 then begin
  print,' '
  print,'*******************************************************************'
  print,'*  WARNING: Thorium lines sit',avgdx,' columns away from nominal  *'
  print,'*******************************************************************'
  print,'   Move Echelle Grating Angle: ',0.001*avgdx, ' degrees  (HIRES) .'
  end else begin
  print,''
  print,'  No Echelle Grating move needed.'
  print,' '
  endelse

 if abs(avgdy) gt 1.0 then begin
  print,' '
  print,'Warning:  Thorium lines sit',avgdy,' rows away from nominal'
  print,'          Move X-Dispersor Angle: ',0.0023*avgdy,' degrees.'
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
  yr=[min(fwhmx)-.1,max(fwhmx)+.1]
  plot,x,fwhmx,ps=8,titl=titl,xtit=xtit,ytit=ytit,/ysty,yr=yr,/xsty
  xp = .5*max(x)
  yp = max(fwhmx)+.02  ;-.05*(max(fwhmx)-min(fwhmx))
  st = '!6<FWHM>='+strmid(strtrim(string(avgfwhmx),2),0,5)
;  !p.color=270
;  oldc = !p.color 
  xyouts,xp, yp,st,size=1.4
;  xyouts,400,yp-0.04,'Hermite #2 = '+string(h2),size=2 
; !p.color = oldc
;
; FW10% vs Column
  titl='!6FW@10% vs  Column#'
  xtit='!6 Column'
  ytit='!6 FW@10% (pixels)'
  yr=[min(fw10x)-.2,max(fw10x)+.2]
  plot,x,fw10x,ps=8,titl=titl,xtit=xtit,ytit=ytit,/ysty,yr=yr,/xsty
  yp = max(fw10x)+.04  ;-.05*(max(fwhmx)-min(fwhmx))
  st = '!6<FW10%>='+strmid(strtrim(string(avgfw10x),2),0,5)
;  oldc = !p.color & !p.color=270
  xyouts,xp, yp,st,size=1.4
  xyouts,400,yp-0.3,'Hermite #3 = '+string(h3),size=1.4
;  !p.color = oldc
;
; ASYMMETRY vs Column
  titl='!6ASYMMETRY (10% Bisector) vs  Column#'
  xtit='!6 Column'
  ytit='!6 Displacement of Bisector at 10%'
  yr=[min(asym)-.1,max(asym)+.1]
  plot,x,asym,ps=8,titl=titl,xtit=xtit,ytit=ytit,/ysty,yr=yr,/xsty
;  oldc = !p.color & !p.color=270
  xyouts,xp,max(asym)+0.02,'Asym=' + strmid( string(avgasym),2,7 ),size=1.4
;  !p.color = oldc
;
  ti='!6MEAN THORIUM LINE' 
  xt='!6 Pixel'
  yt='!6 CTS'
  xra=[-3,3]

;   sampind = indgen(4.*finelen/osamp)*osamp/4.
   plot,fineind-sz,avgpro,titl=ti,xtit=xt,ytit=yt,$
     xr=xra,/xsty,yr=[-.1,1],/ysty,thick=3
   oplot,[.8,.95],[.9,.9],thick=3
   xyouts,1.,.89,'!6Mean Line',size=1.3

;   

; Reference Profile (stored from July 15, 1995)
;   col=260
;   oplot,fineind-sz,gau,co=col,thick=.3
;   oplot,[.8,.95],[.8,.8],co=col,thick=.3 
;   !p.color = col
   oplot,fineind-sz,gau,thick=.3
   oplot,[.8,.95],[.8,.8],thick=.3 
   xyouts,1.,.79,'Ref. Prof.',size=1.3
   xyouts,-2.8,.8,'Sig.Dif.='+sigdif,size=1.3

   oplot,fineind-sz, dif*3, ps=3   ; DIF
   xyouts,-.6,-.07,'!6 DIF x3',size=1
;   !p.color = oldc
;    !p.multi=0
ENDIF  ;end plotting section
end













































































