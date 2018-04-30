pro forp,v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,format=format,outfile=outfile, header=header, ind=ind
on_error,2
npar = n_params()
s = intarr(4,npar)

if npar lt 1 or npar gt 12 then $
  message,'Wrong number of input parameters',/ioerror
j = 0L
if keyword_set(ind) then nel = n_elements(ind) else nel = n_elements(v0)
if keyword_set(outfile) then begin
    openw,1,outfile
    if keyword_set(header) then printf, 1, header
;    for j = 0,nel-1 do begin
    while j lt nel do begin
        if keyword_set(ind) then i = ind[j] else i = j
        case npar of 
            1: printf,1,v0[i],format=format
            2: printf,1,v0[i],v1[i],format=format
            3: printf,1,v0[i],v1[i],v2[i],format=format
            4: printf,1,v0[i],v1[i],v2[i],v3[i],format=format
            5: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],format=format
            6: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],format=format
            7: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],format=format
            8: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],format=format
            9: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],format=format
            10: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],v9[i],format=format
            11: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],v9[i],v10[i],format=format
            12: printf,1,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],v9[i],v10[i],v11[i],format=format
        endcase
;    endfor
        j++
    endwhile
    close,1
endif else begin
;    for j = 0,nel-1 do begin
    while j lt nel do begin
        if keyword_set(ind) then i = ind[j] else i = j
        case npar of 
            1: print,v0[i],format=format
            2: print,v0[i],v1[i],format=format
            3: print,v0[i],v1[i],v2[i],format=format
            4: print,v0[i],v1[i],v2[i],v3[i],format=format
            5: print,v0[i],v1[i],v2[i],v3[i],v4[i],format=format
            6: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],format=format
            7: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],format=format
            8: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],format=format
            9: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],format=format
            10: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],v9[i],format=format
            11: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],v9[i],v10[i],format=format
            12: print,v0[i],v1[i],v2[i],v3[i],v4[i],v5[i],v6[i],v7[i],v8[i],v9[i],v10[i],v11[i],format=format
        endcase
;    endfor
        j++
    endwhile
endelse
end
