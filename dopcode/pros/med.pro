;+
; NAME:
;       MED
;
;
; PURPOSE:
;       Take the median of each column (or row) in a 2D array to 
;       form  1D median array. Also return a vector of the standard
;       deviations of each column (or row).
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;       result = med(array [,/row, /mean, std=std])
;
;
; INPUTS:
;       ARRAY - 2D array
;
;
; KEYWORD PARAMETERS:
;       ROW - Default is the median of each column. Set
;             transpose to do rows.
;       MEAN - Take the mean of each column or row rather.
;
; OUTPUTS:
;       RESULT - Vector holding the median of each row
;
;
; OPTIONAL OUTPUTS:
;       STD - Standard deviation of the mean of each column 
;             or row is returned through this keyword if /MEAN
;             is used.
;
; SIDE EFFECTS:
;       Can't get around using loops. This plus the use of MEDIAN
;       means this procedure is slooooowwww...
;
;
; RESTRICTIONS:
;       Don't use this if you need to go fast. I usually only use 
;       this for analysis at the command line.
;
; EXAMPLE:
;    IDL> array = [[1,2,6],[2,4,8],[0,99,1]]
;    IDL> print,array
;           1       2       6
;           2       4       8
;           0      99       1
;    IDL> print,med(array)
;         1.00000      4.00000      6.00000
;
; MODIFICATION HISTORY:
; Written a long time ago by JohnJohn
;-

function med,funcin,row=row,mean=mean,stdev=stdev
if keyword_set(row) then func = transpose(funcin) else func = funcin
sz = size(func)
ncol = sz[1]
nrow = sz[2]
med = fltarr(ncol)
even = (nrow mod 2 eq 0) ? 1 : 0
if not keyword_set(mean) then begin
    for i=0,ncol-1 do begin      ;gotta loop to do the median
        med[i] = median(func[i,*], even=even)
    endfor  
endif else begin
    med = total(func,2)/nrow     ;no loop needed for mean
    medarr = fan(med,nrow)
    stdev = sqrt(total((medarr-func)^2/(nrow-1),2))/sqrt(nrow)
endelse

return,med
end


