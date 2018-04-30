function cftape, cf, num=num, float=float
type = size(cf,/type)
if type eq 7 then obnm = cf else obnm = cf.obnm
case 1 of
    keyword_set(num): begin
        nel = n_elements(obnm)
        num = fltarr(nel)
        for i = 0, nel-1 do num[i] = float(strmid((strsplit(obnm[i],'.',/ext))[0], 2))
        return, num
    end
    keyword_set(float): begin
        let = strmid(obnm, 1, 1)
        u = where(let eq 'k', nu) ;;; obsolete
        nel = n_elements(obnm)
        if nu gt 0 then let[u] = 'i' 
        num1 = byte(let)
        num1 = reform(num1, n_elements(num1))
        parts0 = strarr(nel)
        parts1 = fltarr(nel)
        for i = 0, nel-1 do begin
            parts0[i] = (strsplit(obnm[i],'.',/ext))[0]
            parts1[i] = (strsplit(obnm[i],'.',/ext))[1]
        endfor
        num2 = float(strmid(parts0, 2))
;        num3 = float(strmid(obnm, 5))
        num3 = float(parts1)
        return, num1*100. + num2 + num3*1d-4
    end
    else: return, strmid(obnm, 0, 4)
endcase

  
end
