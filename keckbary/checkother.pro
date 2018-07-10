PRO checkother, name, otherfile, coords, epoch, pm, prlax, radvel, raarr, decarr, found


rdfile,otherfile, 1,109999,data
absmag = -99 & vmag = -99
othnames = getwrds(data,0)  ;       if lastchar eq 'A' or lastchar eq 'B' then name = name+lastchar
othind = where(strupcase(othnames) eq name)
IF othind NE -1 then begin
    rah = double(getwrd(data(othind),1))
    ram = double(getwrd(data(othind),2))
    ras = double(getwrd(data(othind),3))
    ra = ten([rah,ram,ras])
    decd = double(getwrd(data(othind),4))
    decm = double(getwrd(data(othind),5))
    decs = double(getwrd(data(othind),6))

    ; Added by BJ 01/21/2017 to deal with -00 .. .. declinations
    IF decd EQ 0 THEN BEGIN
        ; print, "Using -00 declination patch addded by BJ on 01/21/2017"
        dstr = getwrd(data(othind),4)
        IF strmid(dstr,0,1) EQ '-' THEN decm = -1 * abs(decm)
    ENDIF
    if decD eq 0 and decm eq 0 then begin
        ; print, "Using -00 declination patch addded by BJ on 01/21/2017"
        dstr = getwrd(data(othind),5)
        IF strmid(dstr,0,1) eq '-' then decs = -1 * abs(decs)
    endif
    ; end section added by BJ

    dec = ten([decd,decm,decs])
    coords = [ra,dec]
    epoch = double(getwrd(data(othind),7)) ;        equinox is assumed 2000
    ra_motion = double(getwrd(data(othind),8)) ;in arcsec (not sec time)
    dec_motion = double(getwrd(data(othind),9)) ;in arcsec
    pm = [ra_motion,dec_motion]
    prlax = double(getwrd(data(othind),10))
    radvel = double(getwrd(data(othind),11))
    found = 1
    coords = [ra, dec]
ENDIF ELSE BEGIN
    found = 0
ENDELSE

END