FUNCTION hdrdr,hdr,strnm
;
;     hdrdr (header reader) is called from dfitrd
;     it reads the numerical information out of
;     the header of fits formats files.
;     hdr is a strarr which contains the header information
;     strnm (strin_name) is s string specifying which header info is desired
;
dum=where(strtrim(strmid(hdr,0,8),2) eq strnm,ndum)
if ndum lt 1 then begin
    print,'Did not find '+strnm+'!!!!!!!!!! in hdrdr.pro'
    temp=-1
endif else begin
   temp=strtrim(strmid(hdr(dum(0)),9,70),2)
   dum=strlen(temp)
   if strmid(temp,dum-1,1) eq '/' then temp=strtrim(strmid(temp,0,dum-1),2)
endelse
return,temp
end

