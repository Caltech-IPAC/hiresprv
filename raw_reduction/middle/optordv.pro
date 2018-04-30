pro optordv,data,modl,munc,int,sint,sig = sig, sky = sky, changes = changes, stop=stop

;  This routine performs the fitting of the slit function to the data using
;  analytically derived equations for the least squares solution.  It
;  also returns the uncertainty in the solution, and optionally the simply
;  mashed spectrum and its uncertainty (but still using the slit
;  function to correct bad pixels).  
;  The INPUTS are:
;     data  - The array of data along on order in the spectrum (perpendicular
;                to the dispersion direction)
;     modl  - The vector (same length as data) representing the slit function
;                centered over the data column.
;     munc  - The vector (same length as modl) representing the
;             uncertainty in the slit function
;  The optional INPUTS are:
;     sig   - Cosmic ray rejection threshold in sigma.  If not set
;             will be set by the global value of ham_cosmic_sig
;     sky   - Array contianing scattered light which has been removed
;             from data for purposes of calculating noise.
;  The OUTPUTS are:
;     int   - The intensity scaling factor required to scale the slit function
;                to the data.
;     sint  - The uncertainty in the intensity scaling factor.
;  The optional outputs are:
;     changes  - An array containing the changes to the spectrum made
;                (presumably cosmic rays)
;     
;
;  30-Mar-1998  CMJ JAV  Written from analytic_opt (IR package).
;  08-Dec-1998  JAV      Implemented a median normalization for the slit
;                         function the first time through the loop. Should
;			  be more robust than a least-squares fit that may
;			  include bad pixels. Forced at least two passes
;			  through the loop to guarantee a least squares fit
;			  in the end.
;  22-Jun-2001  JTW      Heavily re-written for HIRES reduction.  In
;                        particular, vectorized and allow changes to
;                        be passed back to caller.
; 25-nov-2009 HTI   Reduced threshold for exiting while loop
;					Set iteration of while loop to not gt 5
;					Allow 3 or fewer pixels to be corrected (was lt 3)

@ham.common

npar=n_params()
if npar lt 4 then begin
   print,'Syntax is : optord,data,modl,munc[,tot,stot,sig=sig,sky=sky,changes=changes,/stop]'
   retall
endif

ncol = n_elements(data[0, *])

; Define some necessary quantities.

if(keyword_set(sig)) then xsd = sig else xsd=ham_cosmic_sig 
                                ; set number of standard devs.
                                ; for bad pixel rejection
                                ; to common value if not explicitly
                                ; passed in.
                                ; 5 is a good value.

sizes = (size(data))
ncol = sizes[2]                 ;columns on the chip are rows here, for speed
npix = sizes[1]                 ;extraction width in pixels
indices = lindgen(npix, ncol)   ;array for going from 2D to 1D indexing 
mask = data*0.+1.               ; initialize mask array for flagging potential cosmics 
good = 0.*data[0, *]            ; set DONE flag (used to signal that a 
                                ; column is clean of cosmics)

gain = ham_gain                 ;get the gain
pbg = ham_pbg                   ;get the read noise/other sources of constant noise

changes = data*0.               ;initialize the changes array to store cosmic rays

sd2=pbg^2.+abs(data+sky)/gain   ;1st guess at noise is just poisson+read

sint = data*0.                  ;initialize array containing uncertainty in spectrum
int = sint-1.e6                 ; set bogus int value.  
                                ; It's an array for speed and
                                ; vectorization; it could be a vector instead

iloop = 0                       ; set loop counter

; Make intial guess assuming no bad pixels


for icol = 0, ncol-1 do begin
  
  imodl = modl[*, icol]           ;prefix i means "subset for this particular iteration"
  isd2 = sd2[*, icol]             ;in this case, isd2 = "subset of sd2 for column icol"
  icore = where(imodl gt 0.1*max(imodl)-min(imodl), ncore)
                                ;the "core" of the profile where most
                                ;of the flux is

  if (ncore lt 1) then begin 
    int[*, icol] = total(data[*, icol]*imodl/isd2, 1)/total(imodl^2./isd2, 1) ; find solution
                                ;the solution is equivalent to a
                                ;least-squares fit of the model to the
                                ;data with only the amplitude allowed
                                ;to vary.
    good[icol] = 1 
  endif else int[*, icol] = median(data[icore, icol]/imodl[icore]) 

;int[*, icol] = median(data[icore, icol]/imodl[icore]) ; normal scaling


endfor

prevint = int                   ; we're iterating, so we need to check for 
                                ;convergeance by keeping track of
                                ;previous iteration's values

while min(good) ne 1 do begin     ;as long as some columns aren't done yet...


  ido = where(good ne 1, ndo)   ;these columns aren't done yet
  imodl = modl[*, ido]          ;load up the arrays
  isky = sky[*, ido]
  idata = data[*, ido]
  imunc = munc[*, ido]
  iint = int[*, ido]
  ginds = indices[*, ido]

  corspec = imodl*iint          ;compute the "correct" or model spectrum

  sd2[*, ido] = (imunc*iint)^2+(pbg)^2.+abs(corspec+isky)/gain > 1
  isd2 = sd2[*, ido]         
                                ; recalculate noise, including the
                                ; uncertainty in the model.  

  idif = idata-corspec          ; Calculate the residuals

  mask[*, ido] = idata*0.+1.    ; Re-initialize mask
  thresh = (xsd)*sqrt(isd2) > 20   ; Calculate the threshold
  ibad = where(idif gt thresh, nbad)    ;Which pixels are bad?
;if keyword_set(stop) then stop      
  if nbad gt 0 then begin
    mask[ginds[ibad]] = 0.      ; Mask them out  
  endif
  imask = mask[*, ido]          

  tmp = total(imask*idata*imodl/isd2, 1)/total(imask*imodl^2./isd2, 1) 
                                ; find new solution

  if n_elements(tmp) gt 1 then $
      int[*, ido] = (fltarr(sizes[1])+1.)#tmp $
  else $
      int[*, ido] = replicate(tmp,sizes[1])
  
                                ;fan out the vector tmp into the array int

;  igd = where ((abs(int[0, ido]-prevint[0, ido])-iint*1.0e-4) lt 0., ngood)
  igd =where((abs(int[0,ido]-prevint[0,ido])-iint*3.0e-4) lt 0.,ngood); hti11/09
                                ;which columns have converged?

  if ngood gt 0 then begin      ;flag them
    good[ido[igd]] = 1
  endif

  prevint = int         ; set previous scale factor

  iloop = iloop+1      ; increment the loop counter
  
;  if iloop gt 9 then begin
  if iloop gt 4 then begin
  	message, /inf, 'Iterated 5 times to find bad pixels.'
    good[*] = 1                 ; stop an infinite loop
  endif
  
endwhile

potcos = sizes[1]-total(mask, 1) ;how many columns have been 
                                ;flagged as containing cosmic rays?

;rep = where(potcos gt 0. and potcos lt 3., nrep) ; changed hti 11/09
rep = where(potcos gt 0. and potcos le 3., nrep)
                                ;Don't let it get carried away.  3
                                ;pixels is a substantial fraction of
                                ;all of the pixels in the slit
                                ;function.  If more than 3 are flagged
                                ;the routine probably got confused

if nrep gt 0 then begin         ;if there are any cosmics in this order
  masked = mask[*, rep]         ;where are they?
  corrected = (int*modl)(*, rep);what should the values of those pixels be?
  original = data[*, rep]       ;what are they now?
  changes[*, rep] = (original-corrected)*(1.-masked) ;what changes should be made?
;  for i = 0, nrep-1 do begin       ;plotting diagnostics
;    plot, data(*, rep(i)), psym = 2
;    oplot, original(*, i), psym = -2, color = 2
;    oplot, corrected(*, i), color = 3
;    junk = get_kbrd(1)
;  endfor
  data[*, rep] = corrected*(1.-masked)+masked*original ;make them.
endif


int = int[0, *]       ;optimally extracted spectrum

sint = 1./total(mask*modl^2./sd2, 1) ; find uncertainty in solution
 
sint = sqrt(sint)


end

