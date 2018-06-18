pro gaialookup, name, inpcoords, coords, epoch, pm, prlax, radvel, raarr, decarr, searchrad=searchrad, cat=cat, verbose=verbose

;INPUT
;     name      string    Name of the star, must be queryable in Simbad
;     inpcoords array    [ra_deg, dec_deg] of the star
;
;OUTPUT
;     coords   [ra, dec]                decimal [hours,degrees]
;     Epoch    float                    Epoch  of coordinates' relevance.
;     pm       [ra_motion, dec_motion]  proper motion  [arcseconds/yr]
;     prlax    float                    parallax       [arcseconds]
;     radvel   float                    radial velocity  [m/s]
;     raarr    array version of RA
;     decarr   array version of DEC
;KEYWORDS
;     searchrad float      search radius in arcminutes
;     verbose   bool       print extra information about Gaia query
;
; NOTES
; EQUINOX 2000 is assumed.
; Target assumed to be brighter than Gmag < 18

IF NOT keyword_set(searchrad) THEN searchrad = 0.5
IF NOT keyword_set(cat) THEN cat = "I/345/gaia2"
IF NOT keyword_set(verbose) THEN verbose = 0
name = strcompress(strtrim(strupcase(name),2),/remove_all) ;get rid of blanks

barydir = getenv("MIR3_BARY")
otherfile = barydir+'kother.ascii'

ira = inpcoords[0]
idec = inpcoords[1]

isnum = valid_num(name)
IF isnum EQ 1 THEN name = "HD"+name

; First check otherfile (by target name) to see if the star is already there
checkother, name, otherfile, coords, epoch, pm, prlax, radvel, raarr, decarr, found

; query Gaia DR2 from Vizier if not in otherfile
IF NOT found THEN BEGIN
    IF verbose EQ 1 THEN print, "Querying Gaia DR2"
    query = QueryVizier("I/345/gaia2", name, searchrad, constraint="Gmag<18", /cfa, /allcolumns)

    IF typename(query) EQ "LONG" THEN BEGIN
        IF verbose EQ 1 THEN print, "Querying by coordinates"
        query = QueryVizier("I/345/gaia2", inpcoords, searchrad, constraint="Gmag<18", /cfa, /allcolumns)
    ENDIF
    IF typename(query) EQ "LONG" THEN BEGIN
        print, "ERROR: no matches found at coordinates" + str(ira) + " " + str(idec)
        coords = [-99.d0, -99.d0]
    ENDIF ELSE BEGIN
        dim = n_elements(query)
        IF dim GT 1 THEN BEGIN
            IF verbose THEN print, "WARNING: "+str(dim, format="(I2)")+" matches found within +"+str(searchrad, format="(F5.2)")+"' for target " + str(name)
            IF verbose THEN print, "selecting brightest match"
            mags = query.GMAG
            pos = where(mags EQ min(mags))
            query = query[pos]
        ENDIF

        ra = query.RA_ICRS / 15.0
        dec = query.DE_ICRS
        coords = [ra, dec]
        epoch = query.epoch
        pm_ra = query.PMRA / 1000.
        pm_dec = query.PMDE / 1000.
        pm = [pm_ra, pm_dec]
        prlax = query.plx / 1000.
        radvel = query.RV * 1000.
    ENDELSE

    rag = sixty(coords(0))
    raarr = [fix(rag(0:1)),rag(2)]
    decarr = fix(sixty(coords(1)))

    IF decarr[0] EQ 0 AND (decarr[1] LT 0 OR decarr[2] LT 0) THEN BEGIN
        dec_strd = "-00"
        dec_strm = abs(decarr[1])
        dec_strs = abs(decarr[2])
    ENDIF ELSE BEGIN
        dec_strd = str(decarr[0], format='(I+03)')
        dec_strm = decarr[1]
        dec_strs = decarr[2]
    ENDELSE

    openw, lun, otherfile, /get_lun, /append
    printf, lun, name, raarr[0], raarr[1], raarr[2], dec_strd, dec_strm, dec_strs, epoch, pm_ra, pm_dec, prlax, radvel, $
        format='(A16, 1X, I02, 1X, I02, 1X, F05.2, 2X, A3, 1X, I02, 1X, F05.2, 2X, F7.1, 2X, F8.4, 1X, F8.4, 2X, F8.6, 1X, F10.2)'
    free_lun, lun

    ; reread from file to avoid differences with rounding
    checkother, name, otherfile, coords, epoch, pm, prlax, radvel, raarr, decarr, found

ENDIF

if n_elements(prlax) ge 2 then prlax = prlax(0)
;Determine secular acceleration
; Note (sec_acc =-99 flag caused problems)

if prlax eq 0.0 then sec_acc = 0 else sec_acc = 0.0458/2. * total(pm*pm)/prlax

if verbose EQ 1 then begin
    print,'Name = ',name
    print,'RA  =',sixty(coords(0))
    print,'DEC =',sixty(coords(1))
    print,'Epoch: ',epoch
    print,'Proper Motion (ra,dec)= ',pm(0),' ',pm(1), ' arcsec/yr'
    print,'Parallax = ',prlax
    print,'Secular Acceleration:',sec_acc, ' m/s per yr'
endif


END
