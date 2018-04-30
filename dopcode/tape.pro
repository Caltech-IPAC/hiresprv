function tape, cf, num=num, float=float
type = size(cf,/type)
if type eq 7 then obnm = cf else obnm = cf.obnm
nob = n_elements(obnm)
if keyword_set(float) then val = dblarr(nob) else val = strarr(nob)
for i = 0, nob-1 do begin
    parts = strsplit(obnm[i],'.',/ext)
    np = n_elements(parts)
    case 1 of
        keyword_set(num): val[i] = strmid(parts[0], 2) 
        keyword_set(float): begin
            let = strmid(obnm[i], 1, 1)
            u = where(let eq 'k', nu) ;;; obsolete
            if nu gt 0 then let[u] = 'i' 
            num1 = byte(let)
            num1 = reform(num1, n_elements(num1))
            num2 = float(strmid(parts[0], 2, 3))
            if np eq 1 then val[i] = num1*100d0 + num2 else begin
                num3 = float(parts[1])
                val[i] = num1*100d0 + num2 + num3*1d-4
            endelse
        end
        else: val[i] = parts[0]
    endcase
endfor
return, val
end
