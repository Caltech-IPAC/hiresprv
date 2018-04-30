pro hamfoc,INPUT=input,LOC=loc,COUDE=coude,SILENT=silent,$
         LINELIST=linelist,HDCPY=hdcpy
spawn,'clear'
print,' '
print,'* * * * * * HAMILTON SPECTROGRAPH FOCUSING PROGRAM * * * * * *'
print,' '
print,'calling sequence: [/input,/loc,/coude,/silent,/linelist,/hdcpy]'
print,''
if keyword_set(loc) then print,'data disk selected: ucscloc/data' 
if keyword_set(coude) then print,'data disk selected: coude/data' 
print,'--------------------------------------------------------------'
print,' '
;
; PURPOSE:
; User focusing program for the Lick Observatory Hamilton Echelle.
; Interactively creates linelist of th-ar postitons if keyword
; "linelist" is not set.
; Accepts one or more input th-ar images from disk (loc or coude).
; Computes FWHM, FW@10%, and asymetry of thorium lines specified by 
; coordinates in the 'lines list'. 
;
; CALLING SEQUENCE: IDL> hamfoc,/input,/silent,/makelist,/hdcpy
;
; INPUTS:  
;       1.  Th-ar image must exist in /scratch/scr.ccd on coude,
;           or in /scratch/scr.ccd on ucscloc (keyword "loc" or "coude"). 
;           OR, if "input" keyword set, file(s) must be in /data on coude 
;           or in /data on ucscloc (keyword "loc" or "coude"). 
;           Th-ar files must be of the form d#.ccd, and, if >1 file, 
;           numbered sequentially.
;       2.  If keyword "linelist" is set. the user is prompted for an
;           existing list of th-ar line positions. The file containing
;           the list must be on shane in /u/user/focus.  If keyword in
;           not set, code to interactively create linelist is invoked.
;           Default line list filename is /u/user/focus/linelist.ham.
;
; OUTPUTS: If keyword "linelist" not set, make_ham_list is called and user
;          specifies filename for th-ar position file it creates. All
;          linelists are stored on shane in /u/user/focus; default output
;          filename is linelist.ham. 
;
; KEYWORDS: 
;       INPUT     Invoke prompt for input file, or series of files;
;                 if keyword not set, input file is scratch.
;       LOC       if keyword set, look for images on ucscloc in /data.
;       COUDE     if keyword set, look for images on coude in /data.
;       SILENT    Supress printing of each line's stats to screen. 
;       LINELIST  Get an exisiting linelist (make_ham_list not called).
;       HDCPY     Make a hardcopy of the final focus curve.
;    
; METHOD:
;       Thorium lines at prescribed pixel locations (given in
;       linelist.ham) are mashed and interpolated
;       by spline.  The FWHM is the number of pixels above the 
;       1/2 peak counts.  FW@10% is # of pixels above "LEVEL" (10%).

; HISTORY:  
;    24 Oct 1994, Create  G.Marcy,T.Misch,P.Butler
;    10 Jan 1995, Revised for Output of Peak Cts and FWHM and Saturation (GM)
;    14 Jan 1995, Revised for FW10% and Asymmetry parameter and Plotting
;    Apr. 95', UFOC.PRO cloned from FOC.PRO. Ability to read multiple input
;              files added.Output of fitted plot of avg.fwhm vs focus 
;              position added. T.M.
;    Dec '95, LOC keyword added; hardcopy keyword added. T.M.
;    May '96, integrated make_ham_list into hamfoc;  T.M. 
;    Jun '96  streamlined user interface; modified program to run on shane 
;             but to act on images on ucscloc or coude.  Added keyword COUDE.
;             Made call to make_ham_list the default.  T.M.
;
 filename = ' '
 fnum= ' '
 ans = ' '
 disk=' '
 listname=' '
 infilename=' '
;
;Test that either loc or coude keyword is set.
if not (keyword_set(loc)) and not (keyword_set(coude)) then begin
   print,''
   print,'Either "loc" or "coude" keyword must be set.
   print,'Please try again'
   print,''
   return
endif
;
;Create a new lines list using make_ham_list.pro if "makelist" set 
if not keyword_set(linelist) then begin
  print,'* * * * * * * INTERACTIVELY CREATE A LINE LIST * * * * * * *'
  print,' '
  print,'> This section allows the user to interactively select a number
  print,'> of thorium/argon lines for use by the focusing program.
  print,'--------------------------------------------------------------'
  print,' '
  print,'> Enter the path and file name of the th/ar image from which
  print,'> the lines will be selected.  If that image is in the scratch
  print,'> buffer (i.e. it is the last unrecorded frame), type return'  
  print,'--------------------------------------------------------------'
  print,' '
  read,'Enter the input file name (return for scr.ccd): ',infilename
  if infilename eq '' then begin
    if keyword_set(loc) then infilename='/mnt/ucscloc/scratch/scr.ccd' 
    if keyword_set(coude) then infilename='/mnt/coude/scratch/scr.ccd'
  end else begin
    if keyword_set(loc) then infilename='/mnt/ucscloc/'+infilename
    if keyword_set(coude) then infilename='/mnt/coude/'+infilename
  endelse
  print,'--------------------------------------------------------------'
  print,''
  print,'> Enter a filename for the line list file or type return to 
  print,'> assign the default filename: /u/user/focus/linelist.ham.  
  print,'> (Linelists will be saved on shane in /u/user/focus.) 
  print,'--------------------------------------------------------------'
  print,''
  read, 'Enter the output file name (return for default): ',listname
  if listname eq '' then listname='/u/user/focus/linelist.ham'$ 
    else listname='/u/user/focus/'+listname
  spawn,'clear'
  print,''
  print,'> File for creating line list: ',infilename,'.'
  print,'> Linelist will be written to: ',listname,' on shane.' 
  print,''
  if keyword_set(loc) then disk='/mnt/ucscloc/'
  if keyword_set(coude) then disk='/mnt/coude/'
  make_ham_list,infilename,listname,disk   ;call to make_ham_list   
end else begin  ;Get existing line list if keyword "makelist" not set 
  print,'* * * * * * * * * GET AN EXISTING LINE LIST * * * * * * * * *'
  print,''
  print,'Linelists must be on shane in the directory /u/user/focus.
  print,''
  print,'Enter the filename of an exisiting linelist,'
  read,'or type return for the default (linelist.ham): ',listname 
  if listname eq '' then listname='/u/user/focus/linelist.ham'$
    else listname='/u/user/focus/'+listname 
  spawn,'clear'
endelse
;
;Get input for focus files, if on disk  
print,' '
if keyword_set(input) then begin 
  if keyword_set(loc) then $
     print,'* * * * Th-Ar FILES MUST BE IN /DATA ON UCSCLOC, * * *'
  if keyword_set(coude) then $
     print,'* * * * Th-Ar FILES MUST BE IN /DATA ON COUDE, * * * *' 
  print,   '* * * * * * * * NUMBERED SEQUENTIALLY, * * * * * * * *'
  print,   '* * * * * * * * AND OF THE FORM d#.ccd * * * * * * * *'
  print,' '
  read,'Enter the total number of th-ar files to be measured: ',fcount
  read,'Enter the number of the first th-ar file (numerical part only): ',fnum
  read,'Enter the first focus position: ',focus
  read,'Enter the focus increment (negative if decrementing): ',finc
  spawn,'clear'
end else begin
  if keyword_set(loc) then $
     filename='/mnt/ucscloc/scratch/scr.ccd'            ;image on ucscloc
  if keyword_set(coude) then $ 
     filename='/mnt/coude/scratch/scr.ccd'              ;image on coude
  fcount=1 & finc=0
  print,''
  print,'Linelist will be read from: ',listname,'.'
  print,'Data will be read from ',filename
  print,'--------------------------------------------------------------'
endelse
;
;Read FITS header of 1st file to get info for idl-FITS coordinate transformation
  if keyword_set(input) then begin
    sfnum=strtrim(fnum,2)
    if keyword_set(loc) then $                        
      filename='/mnt/ucscloc/data/d' + sfnum + '.ccd'  ;image on ucscloc
    if keyword_set(coude) then $
      filename='/mnt/coude/data/d' + sfnum + '.ccd'    ;image on coude
  end else begin
    if keyword_set(loc) then $                         
      filename='/mnt/ucscloc/scratch/scr.ccd'          ;image on ucscloc
    if keyword_set(coude) then $
      filename='/mnt/coude/scratch/scr.ccd'      ;image on coude
  endelse
  rdhead,foo,filename,head 
  numcol=head(3)                          ;number of columns 
  numrow=head(4)                          ;number of rows
  colstart=head(6)                        ;first column
  rowstart=head(7)                        ;first row 
  numcol = fix(StrMid(numcol,20,21))
  numrow = fix(StrMid(numrow,20,21))
  colstart = fix(StrMid(colstart,20,21))
  rowstart = fix(StrMid(rowstart,20,21))
  lastrow=rowstart+numrow
  lastcol=colstart+numcol
;
;Call "urascii.pro" to read lines list 
;Line list is assumed to be in FITS coordinates
 urascii,lines,2,listname,skip=1 
 xF = reform(lines(0,*))
 yF = reform(lines(1,*))  
;transform x and y to IDL coordinate system
 x=xF-colstart & y=yF-rowstart  
;
;Set some Parameters
  sz=5                ;half width of box around lines
  boxsz = sz*2+1      ;11 x 11 pixels around each Th line.
  thresh = 25000      ;thresh for "saturated" signal to be sent.
  level = 0.1         ;level at which Full Width and Asymm are computed
  ind = findgen(boxsz)
  osamp = 50.                        ;oversample 50 subpixels per pixel
  finelen = (boxsz-1)*osamp          ;length of oversampled spectra
  finecen = 0.5*finelen
  fineind = findgen(finelen)/osamp   ;oversampled index
 ; numcol = dimen(im,0)               ;No. of col's
 ; numrow = dimen(im,1)               ;No. of rows
  xmid = numcol/2.                   ; middle col of chip
  ymid = numrow/2.                   ; middle row of chip
  nfound = 0
  focplot=fltarr(2,50);to hold avg fwhms and foc positions for all images
  scrnum=0  ;index for multiple scratch files
;
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
  allprofs= fltarr(finelen,nl)       ;all Thorium profiles
  r     = sqrt((x-xmid)^2 + (y-ymid)^2)   ;radial distance from image center 
;
xbuf=x & ybuf=y  ;save x and y 
;
ANOTHER:      ;goto label if another scratch image is to be taken
;
if not keyword_set(input) then begin 
 print,''
 read,'Enter focus position: ',focus 
 print,'--------------------------------------------------------------'
 print,''
endif 
;
FOR floop=0,fcount-1 do begin            ;BEGIN LOOPING THROUGH ALL FILES
; if floop GT 0 then begin ;restore some variables after each iteration
   x=xbuf 
   y=ybuf  
   fwhmx=fltarr(nl)
   fwhmy=fltarr(nl)
   fw10x=fltarr(nl)
   asym=fltarr(nl)
   allprofs= fltarr(finelen,nl)
 ;endif
 if (floop GT 0) and (keyword_set(input)) then begin  ;increment the filename
   fnum=fnum+1  
   sfnum=strtrim(fnum,2)
   if keyword_set(loc) then $
     filename='/mnt/ucscloc/data/d' + sfnum + '.ccd'    ;images on ucscloc 
   if keyword_set(coude) then $
     filename='/mnt/coude/data/d' + sfnum + '.ccd'      ;images on coude
 endif
 print,'  READING FILE ',filename
 rdfits,im,filename,head                 ;read FITS file
 print,' '
 colstart=head(6)                        ;extract some info from header
 rowstart=head(7)
 colstart = fix(StrMid(colstart,20,21))
 rowstart = fix(StrMid(rowstart,20,21))
;
if not keyword_set(silent) then begin
  print,' '
  print,' _____________________________________________________________ '
  print,'|  Column     Row   Peak Cts      FWHM    FW@10%  ASYM(RT/LT) |'  
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
    dum = max(mashcol,rowloc) & rowloc=fix(rowloc(0))
    dum = max(mashrow,colloc) & colloc=fix(colloc(0))
;
  if abs(rowloc-sz) gt 4 or abs(colloc-sz) gt 4 then begin
      col = fix(colloc+c1)
      row = fix(rowloc+r1)
      cts = fix(im(colloc+c1,rowloc+r1))
      flag = ' NF'
      fwhmx(j) = 0.
      colF=col+colstart & rowF=row+rowstart  ;FITS coordinates for display
if not keyword_set(silent) then begin
print, format=form,'|', colF, rowF , cts, flag,fwhmx(j),fw10x(j),' |'
end
      x(j)=-1   ;x(j)=-1 means line not found, for later rejection, PB 11/15/94
  endif else begin 
;
;    omashcol = spline(ind,mashcol,fineind)    ; oversampled 
     omashrow = spline(ind,mashrow,fineind)     ; oversampled, mashed row 
;    dum = where(omashcol ge max(omashcol)/2.,num) ;indices where cts > .5*peak
;    fwhmy(j) = num/osamp                          ;# osamp'd pxls over half peak
;   FWHM
    dum = where(omashrow ge 0.5*max(omashrow),num) ;indices where cts > .5*peak
    fwhmx(j) = num/osamp ;FWHM in rows

;   FW at 10%,  i.e., "level = 0.10"
    indlev = where(omashrow ge level*max(omashrow),num) ;indices where cts > .1*peak
    fw10x(j) = num/osamp                       ;Full width at 10% peak

;   ASYMMETRY:  Displacement (from peak location) of 10% bisector.
    dummax = max(omashrow, maxloc)   ;get index of peak (maxloc)
    leftdis = indlev(0) ;dist. from center to left level
    ritdis =  indlev(num-1)   ;dist. from center to right level
       asym(j) = 0.5*(leftdis+ritdis) - maxloc  ;dist. maxloc to 10% Bisector
       asym(j) = asym(j)/osamp ;put displacement in CCD pixels units

;   STORE PROFILES
    profsz = osamp*4
    cenprof = shift(omashrow,-1*(maxloc-finecen))  ;Center profile
    allprofs(*,j) = cenprof/max(cenprof)   ;normalize to peak
;   plot,fineind,allprofs(*,j),yr=[0,max(allprofs(*,j))] & wait,1
;
;   Print diagnostics
      col = fix(colloc+c1)
      row = fix(rowloc+r1)
      cts = fix(im(colloc+c1,rowloc+r1))
      flag='   ' & if cts gt thresh then flag='***'   ;Saturated???
      colF=col+colstart & rowF=row+rowstart  ;FITS coordinates for display
if not keyword_set(silent) then begin
print, format=form,'|', colF, rowF , cts, flag,fwhmx(j),fw10x(j),asym(j),' |'
end
  endelse                                       ;PB Kludge  11/15/94
END   ;END LOOP THROUGH ALL LINES
if not keyword_set(silent) then begin
  print,'|_____________________________________________________________|'
  print,'|    NF = Line Not Found; rejected from AVG                   |'
  print,'|_____________________________________________________________|'
  print,' '
end
;
;Reject lines that could not be found above
good=where(x gt 0,nl)
x=x(good)
y=y(good)
fwhmx = fwhmx(good)
fw10x = fw10x(good)
asym = asym(good)
allprofs = allprofs(*,good)
;fwhmy=fwhmy(good)
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
;
;Take AVERAGES
avgfwhmx = mean(fwhmx)
avgfw10x = mean(fw10x)
avgasym = mean(asym)
avgprof = total(allprofs,2)/(nl-4.)
avgprof = avgprof/max(avgprof)
;
;Reference Gaussian
   xo = fineind(finecen)  ;center of Gaussian in CCD pixels units
   sig = 0.60  ;in CCD pixels
   gau= exp(-(fineind-xo)^2/(2.*(sig)^2))
   avgpro = avgprof/max(avgprof)
   dif = avgprof - gau
;
;Compute Asymmetry:  Ratio of Areas of Difference  prof-Gaussian
    dummy = max(avgpro,pkloc)
;   lftarea = total(avgpro(0:pkloc-1))          ;Area of left half
;   rtarea  = total(avgpro(pkloc+1:finelen-1))  ;Area of right half
;   avgasym = (rtarea - lftarea)/(rtarea+lftarea)   ;Asymmetry parameter
;
;   FW at 10%,  i.e., "level = 0.10"
  ufinelen = (boxsz-1)*osamp*10           ;length ultra oversampled profile
  ufineind = findgen(ufinelen)/(osamp*10) ;oversampled index
    uavgprof = spline(fineind,avgprof,ufineind)     ;ultra oversampled prof 
    dummy = max(uavgprof,pkloc)
    indlev = where(uavgprof ge level, num) ;indices where cts > .1*peak
    lftlev = indlev(0)
    rtlev  = indlev(num-1)
    avgasym= 0.5*(lftlev + rtlev) - pkloc
    avgasym= avgasym/(10.*osamp)
;PRINT RESULTS
 print,format='(A15,I6)','FOCUS = ',fix(focus)
 print,format='(A15,F8.3,A7)','AVG FWHM =  ',avgfwhmx,' pixels'
 print,format='(A15,F8.3,A7)','AVG FW@10%= ',avgfw10x,' pixels'
 print,'--------------------------------------------------------------'
 print,''
; print,format='(A15,F8.3,A19)','ASYM:10%Bisect=',avgasym,' pixels from center'  
 focstat = sqrt((avgfwhmx-1.55)^2+avgASYM^2)
; print,format='(A29,F8.3)','Sqrt[(FWHM-1.55)^2+ASYM^2] =',focstat
;
; store avg fwhms and focus position for later fitting and plotting
;
if not keyword_set(input) then begin ;if using scratch, do another?
 morescratch=''
 read,'Take another unrecorded image [y/n]? ',morescratch
 if (morescratch eq 'Y') or (morescratch eq 'y') then begin
  focplot(0,scrnum)=focus
  focplot(1,scrnum)=avgfwhmx 
  scrnum=scrnum+1
  print,'--------------------------------------------------------------'
  print,''
  dummie=''
  read,'Make an exposure; When it is read out, type return.',dummie
  print,'--------------------------------------------------------------'
  goto,ANOTHER
 end else begin
  focplot(0,scrnum)=focus      ;get last scratch image into focplot
  focplot(1,scrnum)=avgfwhmx 
 endelse
end else begin ;using disk images
 focplot(0,floop)=focus
 focplot(1,floop)=avgfwhmx
 focus=focus+finc ;increment focus if files are from disk (keyword input set)
endelse
END    ;END LOOP THROUGH ALL FILES 
;
;trim focplot
trim=where(focplot(0,*))
trimplot=fltarr(2,n_elements(trim))
for i=0,n_elements(trim)-1 do trimplot(0,i)=focplot(0,i)
for i=0,n_elements(trim)-1 do trimplot(1,i)=focplot(1,i)
;fit and plot avg fwhmxs for all images, vs. focus position
if n_elements(trimplot) gt 4 then begin
 print,'--------------------------------------------------------------'
 print,''
 print,'--------------------------------------------------------------'
 print,''
  coef=poly_fit(trimplot(0,*),trimplot(1,*),2)  ;do paraboloic fit
  yfit=poly(trimplot(0,*),coef)
  minloc = -1.*coef(1) / (2.*coef(2))  ;find minimum of parabola
  !p.multi=0      ;make a single plot in the window
  plot,trimplot(0,*),trimplot(1,*),ps=4,title='FWHM vs. focus position',$
     xtitle='focus position',ytitle='FWHM (pixels)'
  oplot,trimplot(0,*),yfit
endif
print,'--------------------------------------------------------------'
print,' '
print,'      FOCUS        AVG FWHM'
print,' ' 
print,trimplot(*,sort(trimplot(0,*)))
print,''
if n_elements(trimplot) gt 4 then print,$
   'BEST FOCUS (minimum of parabolic fit): ',minloc
if keyword_set(hdcpy) then begin     ;make a hardcopy of the focus plot
 lzr,'/procedure/focusplot'
 plot,trimplot(0,*),trimplot(1,*),ps=8
 oplot,trimplot(0,*),yfit
 clzr,'/procedure/focusplot'
endif
;
END
