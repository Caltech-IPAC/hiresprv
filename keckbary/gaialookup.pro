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

ira = inpcoords[0]
idec = inpcoords[1]

isnum = valid_num(name)
IF isnum EQ 1 THEN name = "HD"+name

query = QueryVizier("I/345/gaia2", name, searchrad, constraint="Gmag<18", /cfa, /allcolumns)

IF typename(query) EQ "LONG" THEN BEGIN
    IF verbose THEN print, "Querying by coordinates"
    query = QueryVizier("I/345/gaia2", inpcoords, searchrad, constraint="Gmag<18", /cfa, /allcolumns)
ENDIF
IF typename(query) EQ "LONG" THEN BEGIN
    print, "ERROR: no matches found at coordinates" + str(ira) + " " + str(idec)
    stop
ENDIF

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

if n_elements(prlax) ge 2 then prlax = prlax(0)
;Determine secular acceleration
; Note (sec_acc =-99 flag caused problems)

if prlax eq 0.0 then sec_acc = 0 else sec_acc = 0.0458/2. * total(pm*pm)/prlax

rag = sixty(coords(0))
raarr = [fix(rag(0:1)),rag(2)]
decarr = fix(sixty(coords(1)))

if keyword_set(print) then begin ; you can't have /print and silent at once!
    print,'Name = ',name
    print,'RA  =',sixty(coords(0))
    print,'DEC =',sixty(coords(1))
    print,'Epoch: ',epoch
    print,'Proper Motion (ra,dec)= ',pm(0),' ',pm(1), ' arcsec/yr'
    print,'Parallax = ',prlax
    print,'Vmag = ',vmag,'   Abs_VMag =',absmag
    print,'Spectral Type: ',spt
    print,'Secular Acceleration:',sec_acc, ' m/s per yr'
    print,'Comment: ',comm
endif
end
