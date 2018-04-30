pro fixpix,im,old=old,dewar=dewar
;this routine replaces bad columns in the 1D spectra with an m-th order
;this routine replaces bad columns in the 1D spectra with an m-th order
;polynomial (where m is currently equal to 2), using the two points nearest
;the bad point.  This is for the windowed I2 cell spectra taken with the
;new chip (butler 3/11/88).  (Revised butler 4/9/88)(Revised butler 6/23/88)
;b1 is the beginning order you wish to apply this routine to (usually 0).
; It will automatically work on 1 to 25 orders.
; modified to run 'benitz' stye spectra on 8/8/88 (butler)
;there are currently 25 usable orders on nsf#4  (d = 24)
;
;11-MAY-93 ECW	Added pixel fixing for dewars #1,2,13 and updated 
;		dewars 6 and 8.  Also changed arguments of code to
;		use the CASE test instead of IF statements when
;		determining which dewar is being used.  NOTE: This
;		code assumes that the value of the keyword has been
;		verified correct externally and will bomb if an unexpected
;		value for the DEWAR keyword is input.  The default for
;		not sending a value to DEWAR is dewar 6 currently.
;           
;               Dewar #39  is for post November 1994 data (61 orders)
;               Dewar #99  is for August 1990 CAT data (52 orders) 
;               Dewar #98  is for August 1991 CAT data (33 orders) 
;               Dewar #101 is for Keck HIRES Data prior to rk5
;               Dewar #102 is for Keck HIRES Data for rk5 and later
;               Dewar #150 is for AAT UCLES Data for ru02 and later
;               Dewar #151 is for AAT UCLES Data for ru44, ru48 and later
;               Dewar #18  is for HAMILTON Data with new Dewar #6
;                                     re (and rb69 and later?)
;               Dewar #161 is for VLT UVES Data rv01 and later
;               Dewar #24  is for HAMILTON with new Dewar #6, April 1998
;


;if n_elements(dewar) ne 1 then dewar=6		;set up default dewar

if n_elements(dewar) ne 1 then dewar=18		;set up default dewar
ncol=n_elements(im(*,0))                        ;number of columns
d=n_elements(im(0,*))-1		                ;determine # of orders
im=float(im)					;set image to non-integer
dum=reform(im(ncol-1,*))                        ;normalization values from last column

;kludge fix for negative normalization
   if (dewar eq 18) or (dewar eq 39) or (dewar ge 101) then begin
      ind=where(dum lt 0,nind)
      if nind gt 0 then dum(ind)=dum(ind)+65536.0
   endif

;normalization for dewars 39, 98, 99, 101, 102, 150, 151 18, 161
   if (dewar eq 39) or (dewar eq 101) or (dewar eq 102) $
    or (dewar eq 98) or (dewar eq 99) or (dewar eq 150) $
    or (dewar eq 151) or (dewar eq 18) or (dewar eq 161) $
    or (dewar eq 24) then begin
;      for n=0,d do im(*,n)=im(*,n)*(1000./dum(n))
      im(ncol-1,*)=im(ncol-3,*)
   endif 

;normalization for dewars 1, 2, 6, 8, 13
   if not keyword_set(old) and (dewar ne 39) and (dewar ne 101) $
       and (dewar ne 102) and (dewar ne 98) and (dewar ne 99) $
       and (dewar ne 150) and (dewar ne 18) and (dewar ne 151) $
       and (dewar ne 161) and (dewar ne 24) then begin
	 im=im*(1000./im(ncol-1,0))             ;scale image back 
         im(ncol-1,*)=im(ncol-3,*)		;last col. reset
   endif

case dewar of
  1: begin					;adjust for dewar #1
    for n=0,d do begin
    	badpix,im,n,258,1
	badpix,im,n,790,8
	badpix,im,n,654,2
	badpix,im,n,631,1
	badpix,im,n,189,1
	badpix,im,n,662,1
	badpix,im,n,671,1
	badpix,im,n,463,1
    endfor
    for n=7,d do badpix,im,n,110,1
    for n=22,d do badpix,im,n,201,1
    for n=13,d do badpix,im,n,435,1
    for n=5,d do badpix,im,n,619,1
    for n=7,d do badpix,im,n,111,1
    for n=18,d do badpix,im,n,736,1
    for n=18,d do badpix,im,n,329,1
  end

  2: begin					;adjust for dewar #2
    for n=0,d do begin
	badpix,im,n,117,1
	badpix,im,n,258,1
	badpix,im,n,463,1
	badpix,im,n,526,1
	badpix,im,n,662,1
	badpix,im,n,189,1
	badpix,im,n,179,1
	badpix,im,n,655,1
    endfor
    for n=11,d do badpix,im,n,110,2
    for n=22,d do badpix,im,n,202,1
    for n=13,d do badpix,im,n,435,1
    for n=5,d do badpix,im,n,619,1
    for n=15,d do badpix,im,n,736,1
    for n=7,d do badpix,im,n,757,1
  end

  6: begin					;adjust for dewar #6
    for n=0,d do begin
      	badpix,im,n,41,2
	badpix,im,n,424,3
	badpix,im,n,480,1
	badpix,im,n,549,1
	badpix,im,n,554,1
	badpix,im,n,604,1
	badpix,im,n,640,1
	badpix,im,n,679,1
    endfor
  end

  8: begin					;adjust for dewar #8
    for n=0,d do begin
        badpix,im,n,781,1
        badpix,im,n,555,3
    endfor
    for n=2,3 do badpix,im,n,305,11
    for n=4,5 do badpix,im,n,70,26
    badpix,im,24,675,21
    badpix,im,1,79,1
    badpix,im,22,169,1
    badpix,im,6,335,1
  end

  13: begin					;adjust for dewar #13
    for n=15,d do badpix,im,n,785,8
  end

  24: begin
    x=3
  end

  39: begin
     for n=24,51 do badpix,im,n,1341,1
  end

  98: begin                                     ;Old (1990) Cepheid setup
    fix_slave,im
  end


  99: begin					;adjust for dewar #8
    fixcep,im
    for n=0,d do begin
        badpix,im,n,161,1
        badpix,im,n,289,3
        badpix,im,n,332,1
        badpix,im,n,352,3
        badpix,im,n,657,1
    endfor
    im(798,*)=im(797,*)				;last col. reset
    badpix,im,0,60,1
    badpix,im,7,15,1
    badpix,im,16,420,1
    badpix,im,17,20,1
    badpix,im,17,149,12
    badpix,im,19,193,1
    badpix,im,19,249,1
    im(0:179,18)=0.99*max(im(200:797,18))
    im(0:179,19)=0.
  end

  101: begin
     xx=1
  end

  102: begin
; THE BLOB: Order 21, Pixels 949-1059
; possible bad pixels
    for n=0,7 do begin 
        badpix,im,n,1127,1
        badpix,im,n,961,1
    endfor
  end
  103: begin
      xx=1
  end
  104: begin
      xx=1
  end
  111: begin
      xx=1
  end
  150: begin    ;AAT UCLES MIT LL chip ru02 and later
     xx=1
  end

  151: begin    ;AAT UCLES EEV chip ru44, ru48 and later
     xx=1
  end

  18: begin    ;HAMILTON with new Dewar #6, April 1998
    badpix,im,60,354,4
    for n=0,60 do badpix,im,n,1830,2
    for n=11,37 do badpix,im,n,660,1
    for n=19,60 do badpix,im,n,1609,1
    for n=31,60 do badpix,im,n,985,4
    for n=32,39 do badpix,im,n,1005,1
    for n=50,60 do badpix,im,n,1177,2
    for n=51,56 do badpix,im,n,1815,2
    for n=54,60 do badpix,im,n,1415,2
  end

  161: begin    ;VLT UVES rv
     xx=1
  end

  171: begin
      xx=1
  end
  24: begin    ;HAMILTON with new Dewar #8, Oct 2001  DAF
      xx=1
  end

  999: begin
      xx=1
  end
  else: xx=1
endcase

return
end ;fixpix


