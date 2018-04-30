pro  prop_filt,filter,zero=zero
;this routine returns a proper filter (filled with +1's and -1's)
;when given a casual filter filled with positive, negative, and 0
;numbers
dum=where(filter le 0,num_bad)
filter=filter*0.+1.
if num_bad gt 0 then begin
   if keyword_set(zero) then filter(dum)=0. $
      else filter(dum)=-1.
endif
return
end
