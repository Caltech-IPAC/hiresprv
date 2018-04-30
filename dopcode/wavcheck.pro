Function wavcheck,wavobs,wiod,wavstar,wavfine, info=info
;Principle:  WAVFINE must encompass WAVOBS  but also
;            lie within WIOD and WAVSTAR   
check = 1                       ;+1 ---> Wavs OK .

rng_f = minmax(wavfine)         ;rng_f = [min,max]
rng_i = minmax(wiod)
rng_s = minmax(wavstar)
rng_o = minmax(wavobs)

if rng_f(1) lt rng_o(1) or rng_f(0) gt rng_o(0) then begin ;WAVOBS
    if 1-info.noprint then begin
        print,'STARSYN:  WAVFINE does not encompass WAVOBS'
        print,'WAVFINE Range: ',rng_f
        print,'WAVOBS  Range: ',rng_o
    endif
    return,-1
end

if rng_f(1) gt rng_i(1) or rng_f(0) lt rng_i(0) then begin ;WIOD
    if 1-info.noprint then begin
        print,'STARSYN:  WAVFINE does not lie within WAVIOD'
        print,'WAVFINE Range: ',rng_f
        print,'WAVIOD  Range: ',rng_i
        return,-2
    endif
end

if rng_f(1) gt rng_s(1) or rng_f(0) lt rng_s(0) then begin ;WAVSTAR
    if 1-info.noprint then begin
        print,'STARSYN:  WAVFINE does not lie within WAVSTAR'
        print,'WAVFINE Range: ',rng_f
        print,'WAVSTAR  Range: ',rng_s
        return,-3
    endif
end
return,check
End
