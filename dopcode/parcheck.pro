Function parcheck,par, info=info
check = 1                       ;+1 --> pars are acceptable

;     if par(0) gt 3. or par(0) le 0. then begin
;        print,'STARSYN: Abort because of absurd par(0)=',par(0)
;        return,-1
;     end

;     if par(2) gt 3. or par(2) le 0. then begin
;        print,'STARSYN: Abort because of absurd par(2)=',par(2)
;        return,-1
;     end

if par(11) lt -1. or par(11) gt 2. or par(13) le 0. then begin
    if 1-info.noprint then begin
        print,'STARSYN: Abort because of absurd input wavelength scale.'
        print,'par(11)=',par(11)
        print,'par(13)=',par(13)
    endif
    return,-1
end

vel = par(12)*2.9979d8 
if abs(vel) gt 2d5 then begin ;|vel| > 60,000 m/s 
;        message,'STARSYN: Vel = '+str(vel)+' Not Possible',/ioerror
    if 1-info.noprint then $
      print,'STARSYN: Vel = '+str(vel)+' Not Possible'
    return, -1
end
return,check
End
