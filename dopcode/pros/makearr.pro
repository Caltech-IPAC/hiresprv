;+
; NAME: 
;       MAKEARR 
;
;
; PURPOSE:
;       This procedure will generate an array of lenght N which
;       runs from values MIN to MAX
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;       f = makearr(n, min, max [,fan=, transfan=, /double])
;
;
; INPUTS:
;
;       N:    The number of desired array elements in F
;       MIN:  The value of the first array element in F
;       MAX:  The value of the last array element in F
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
;       FANNED:     Number of times the array is to be repeated.
;                   The final dimensions of F  will be N columns 
;                   by FANNED rows.
;       /TRANSPOSE  Final dimensions of F wil be FAN columns by N 
;                   rows if FAN is specified. 
;
; OUTPUTS:
;
;       F:    Final array
;
; RESTRICTIONS:
;
;       You'll need FAN.PRO to use the fan= keyword. 
;       http://astron.berkeley.edu/~johnjohn/idl.html#FAN
;
; EXAMPLE:
;
;      If you want a 5 element array which runs from 2 to 4:
;
;         IDL> f = makearr(5,2,4)
;         IDL> print, f
;             2.00000      2.50000      3.00000      3.50000      4.00000
;         
; MODIFICATION HISTORY:
; Written by John "JohnJohn" Johnson somewhere around Oct-2001
; 20 Feb 2002 JohnJohn- Added /FAN and /TRANSPOSE keywords.
; 23 Feb 2002 JohnJohn- Calculations performed in double precision. 
;                       Output in double precision if all input 
;                       parameters are double.
; 01 Mar 2002 Tim Robishaw- Spiffed up with a little Tim. 
; 08 Mar 2002 JohnJohn- changed the order of operations to keep the
;                       last number of the array equal to MAX with no
;                       error. Props to Carl Heiles.
; 23 Apr 2002 JohnJohn- Modified the /FAN operation to match my new
;                       FAN procedure. Default direction of the
;                       fanning process is in the column direction,
;                       i.e. a 5-element array with FAN=2 will yeild a
;                       5x2 array rather than the other way around.
; 14 Apr 2005 JohnJohn- Fixed bug where if n_params() eq 2, then MIN
;                       was being modified. Input variable now
;                       protected by renaming MIN as MININ.
;-
function makearr,n,minin,max,fanned=fanned,transpose=transpose
;DEAL WITH HUMANS
on_error,2  ;return to sender if error occurs
if n_params() lt 2 then $
  message,'Syntax: f = makearr(nelements,min,max [,fan] [,/transpose])',/ioerror

if n_params() eq 2 then begin
    max = minin[1]
    min = minin[0]
endif else min = minin

if max lt min then message,'MIN must be less than MAX',/ioerror
if n eq 0 then message,'This program cant make 0-dimensional arrays. N=0 is bad.',/ioerror

;if any of the input parameters are double, the return the answer in
;double precision.
doub = (size(n,/type) eq 5) and (size(min,/type) eq 5) and (size(max,/type) eq 5)

if n gt 1 then a = (dindgen(n)/(n-1))*(max-min)+min else a = min

if n_elements(fanned) ne 0 then begin
    nfan = fanned
    if keyword_set(transpose) then a = fan(a,nfan,/transpose) $
       else a = fan(a,nfan)
endif

if not doub then a = float(a)
return,a
end
