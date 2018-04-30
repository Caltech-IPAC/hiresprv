pro klookup,name,coords,epoch,pm,prlax,radvel,raarr, decarr,hip=hip,$
            barydir=barydir,sec_acc=sec_acc,print=print,slow=slow,silent=silent,$
            trans=trans,cat=cat,bv=bv,dumped=dumped,found=found,tyc=tyc


;To add new stars on the fly,  edit the file:  kother.ascii
;Ultimately all stars being searched for planets should be in <obs>_st.dat
; Note a translation file is used to translate starnames into HIP
; numbers.
;INPUT  
;     name     string    Standard Name of star on Keck Program
;
;OUTPUT
;     coords   [ra, dec]                decimal [hours,degrees]
;     Epoch    float                    Epoch  of coordinates' relevance.
;     pm       [ra_motion, dec_motion]  proper motion
;     radvel   float                    radial velocity
;     raarr    array version of RA
;     decarr   array version of DEC
;KEYWORDS
;     hip      structure   use hip=hip for repeated calls to this program
;     trans    array       same with hip. Use trans=trans to aviod  restoring from disk.
;     slow     /slow       Use 1 second pause after error message
;     cat      cat         Catalog, ie keck_st.dat cat = dum 
;ONCE STAR IS FOUND, SET FOUND = 1 AND JUMP TO END

; EQUINOX 2000 is now assumed.  
; LOOKUP PROGRAM REVISED: So that coordinates for bary are the same as
; those we are pointing to, ie from <obs>_st.dat, as a first
; priority.  Failing that, stars can be looked up in HIPPARCOS, or in
; other.ascii.  
; Modified to look in Tycho Catalog also

if n_params() eq 0  then begin
    print,'klookup,name,coords,epoch,pm,prlax,radvel,hip=hip,barydir=barydir,'
    print,'      sec_acc=sec_acc,print=print,silent=silent,trans=trans'
    retall
endif
if n_params() lt 2 then print = 1 ; assume you want to see SOMETHING
barydir = getenv("MIR3_BARY")
strucfile = getenv("DOP_KECK_STRUC")

if keyword_set(silent) then silent = 1 else silent = 0
dumped = 0
spt = ''

; DEFINE DIRECTORIES, etc.
transfile = barydir+'ktranslation.dat'
otherfile = barydir+'kother.ascii'
hipfile = barydir+'hip.dat' 
tycfile = barydir + 'tycho.dat'
catfile = strucfile 

digits = strtrim(sindgen(10),2) ; 0,1,...

;altcat  = 'hj_st.dat'           ; Put alternate catalogs in the bary directory
;altcatvar = 'HJ'                ; this is the *variable name* for each alternate catalog

lastchar=' ' & found = 0 
radvel = 0 & absmag= -99        ; These could be improved
bv = 0
if n_elements(cat) eq 0 then begin
    restore,catfile
    cat = dum
end


name = strcompress(strtrim(strupcase(name),2),/remove_all) ;get rid of blanks
comm = 'no comment.'


; First CHECK TO SEE IF IT IS IN OUR STANDARD CATALOG (CAT=DUM)

ind = where(strupcase(cat.name) eq name,cnt)
if cnt gt 1 then begin
;    message,'********WARNING',/info
    print,'Note: There  were ',strtrim(string(cnt),2),' entries in the target structure for ',name
;    print,'using the last one for now.  This should be looked into!'
;    print,'********WARNING'
    ind = ind(cnt-1)
endif

if  ind(0) ne -1 then begin     ;its in our cat
    coords = [cat(ind).ra,cat(ind).dec ] 
    epoch = cat(ind).epoch
    spt = cat(ind).sptype+cat(ind).spclass
    pm = [cat(ind).pmr,cat(ind).pmd]
;    prlax = cat(ind).plx
    prlax = cat(ind).par
    vmag = cat(ind).V
    bv = cat(ind).bv
    radvel = cat(ind).radvel
    absmag = vmag-(5.*alog10(1./prlax) - 5.)

    decarr = sixty(coords(1))   ; these are not really used
    rag = sixty(coords(0))
    raarr = [fix(rag(0:1)),rag(2)]
    comm = cat(ind).comments
    if epoch lt 1900 or epoch gt 2050 then message,$ ; This should never happen
      'Star found in *_st.dat.  Error in epoch date: '+epoch 
    found = 1
endif 


;; NEXT CHECK TO SEE IF IT IS IN  THE alternate catalog
;if not found and (findfile(altcat))(0) ne '' then begin
;    restore,altcat
;    cmd = 'cat = '+altcatvar(0) ; just one cat for now.
;    dummy = execute(cmd)
;    
;    ind = where(strupcase(cat.name) eq name)
;    if  ind(0) ne -1 then begin ;its in our cat
;        coords = [cat(ind).ra,cat(ind).dec ] 
;        epoch = cat(ind).epoch
;        spt = cat(ind).sptype+cat(ind).spclass
;        pm = [cat(ind).pmr,cat(ind).pmd]
;        prlax = cat(ind).par    ;    prlax = cat(ind).plx
;        vmag = cat(ind).V
;        bv = cat(ind).bv
;        radvel = cat(ind).radvel
;        absmag = vmag-(5.*alog10(1./prlax) - 5.)
;
;        decarr = sixty(coords(1)) ; these are not really used
;        rag = sixty(coords(0))
;        raarr = [fix(rag(0:1)),rag(2)]
;        comm = cat(ind).comments
;        found = 1
;    endif 
;endif
 
; THEN CHECK TO SEE IF ITS BEEN DUMPED

if not found and  n_elements(dump) ne 0 then begin  
    ind = (where(strupcase(dump.name) eq name))(0)
    if ind ne -1 then begin
        coords = [dump(ind).ra,dump(ind).dec ] 
        epoch = dump(ind).epoch
        pm = [dump(ind).pmr,dump(ind).pmd]
        if  memberof(tag_names(keck),'plx') then prlax = dump(ind).plx  else $
          prlax = dump(ind).par
;        radvel = dump(ind).radvel
        vmag = dump(ind).V        
        decarr = fix(sixty(coords(1))) ; these are not really used
        rag = sixty(coords(0))
        raarr = [fix(rag(0:1)),rag(2)]
        if not silent then print,'******Star ',name,' has been DUMPED.  (ra,dec)= (',$
          strtrim(dump(ind).ra,2),',',strtrim(dump(ind).dec,2),')'
        dumped = 1
        found = 1
    endif
endif 

 ;  SEE IF IT LOOKS LIKE A TYCHO STAR (eg SIM ref. star) & lookup in TYCHO

;if not found then begin  
if not found and name ne '133P-ELST' then begin  ; Kludge for 133p-elst, added for j183 run.
    fixcnt = 0
    TYCRENAME:
    hyphchar = strpos(name,'-') ; search for hyphen
    if hyphchar(0) ne -1 then begin ; could be tycho
        first1 = strmid(name,0,1)
        first3 = strupcase(strmid(name,0,3))
        if first3 eq 'TYC' then tname = strmid(name,3,999) else tname = name
        if (memberof(digits,first1) or first1 eq 'T') and name ne 'TH-AR' then begin
            if n_elements(tyc) eq 0 then begin
                print,'Restoring Tycho Catalog'
                restore,tycfile
            endif

            ind = (where(strupcase(tyc.tycho) eq tname))(0)
            if ind ne -1 then begin
                coords = [tyc(ind).ra/15.d0,tyc(ind).dec ] 
                epoch = 2000    ; correcty?
                pm = [tyc(ind).pmra/1000.0,tyc(ind).pmdec/1000.0] ;convert to "
                vmag = tyc(ind).V        
                decarr = fix(sixty(coords(1))) ; these are not really used
                rag = sixty(coords(0))
                raarr = [fix(rag(0:1)),rag(2)]
                prlax = 0.000   ; Arbitrary: 2000 pc!
                found = 1
            endif else begin
                print,name+': Not found tycho catalog trying to fix name'
                name = tycfix(name,fixed=fixed)
                fixcnt = fixcnt +1   ; aviod infinite loop for bad starname
                if fixed and fixcnt lt 2 then goto, TYCRENAME
            endelse
        endif                   ;  print,'not searching tycho'
    endif 
endif 


; CHECK TO SEE IF IT'S IN HIPPARCOS
;
if not found then begin
;    if not silent then print,'Star not found in keck_st.dat: ',name
    if n_elements(hip) eq 0 then begin
        print,'Restoring Hipparcos Catalog...'
        restore,hipfile
    end
    len = strlen(name)         
    lastchar = strmid(name,len-1,1) ;strip off A or B: Use Hipparcos 
    if lastchar eq 'A' then begin
        len = strlen(name)
        name = strmid(name,0,len-1)
    end
    j = where(hip.hd eq name, hip_found)
    if lastchar eq 'A'  then name = name+lastchar ;"A" back
    
; Some stars begin with "hip"
    first3char = strmid(name,0,3) ;read first 3 char
    if strupcase(first3char) eq 'HIP' then begin
        hname = strmid(name,3,len-3) ;trim off "hip"
        j = where(hip.hipno eq hname, hip_found)     
    end   
    
;If star is not "HD" or "HIP", it still may be in HIPPARCOS. Check translation file

    if hip_found le 0 then begin
        if n_elements(trans) eq 0 then restore,transfile ; 24 stars (mostly Gliese) with HIP #
        trans(0,*) = strupcase(trans(0,*)) ;Only restore this structure if its needed!!! 
        trans(1,*) = strtrim(trans(1,*),2)
        
        i = where(trans(0,*) eq name, trans_found) ;translation to HIP
        if trans_found ge 1 then begin
            i=i(0)
            hipno = trans(1,i)  ;hipparcos number  (string)
            j = where(hip.hipno eq hipno, hip_found) ;HIP struct. index, j
            print,name,'  Found in HIPPARCOS via ',transfile
        end
    endif else if not silent then print,'|  Note: resorted  to HIPPARCOS for coordinates. '

;If Hipparcos # found, get the info.
    if hip_found gt 0 then begin
        j = j(0)                ;should check for multiple HD stars
        coords = [hip(j).ra,hip(j).dec]
        equinox = 2000.d0
        pm = [hip(j).ra_motion, hip(j).dec_motion]
        prlax = hip(j).prlax
        radvel = 0.d0
        vmag = hip(j).vmag
        absmag = vmag-(5.*alog10(1./prlax) - 5.)
        epoch = 1991.25
        found = 1
    endif 
endif 

;If Hipparcos # NOT found, then look in 'kother.ascii': last repository

if not found then begin
    rdfile,otherfile, 0,10999,data
    absmag = -99 & vmag = -99
    othnames = getwrds(data,0)  ;       if lastchar eq 'A' or lastchar eq 'B' then name = name+lastchar
    othind = where(strupcase(othnames) eq name)
	;HTI added Error Checking 3/2012
	if othind[0] eq -1 then begin
		print
		print,'% KLOOKUP.PRO  STAR NOT FOUND: ', name
		print,'%             -Add star to kother.ascii or keck_st.dat'
		print
		stop
	endif
    othind = othind(0)
    name_ck = strcompress(getwrd(data(othind),0),/remove_all)       
    if strlowcase(name) ne strlowcase(name_ck) then begin ; spaces in kother.ascii causing misalignment
       print
       print,'% KLOOKUP.PRO: WARNING, misaligned arrays. Star names dont match.'
       print,'%   Check kother.ascii for blank lines.'
       print,'%   Problem occurs above starname: ',name
      print
       stop
       return
    endif

;print
;print,name,data[othind]
;print
;stop 
   if othind eq -1 then begin  ;Check for star not found
        if not keyword_set(silent) then begin
            print 
            print, 'NOTE:  ', name ,' not found. Could be a TYPO,'
            print, 'or a NEW star, or may not need barycentric correction.'
            print, 'Check name or add star to kother.ascii'
            print 
            if  keyword_set(slow) then wait,1
        endif
        coords = [99.d0,99.d0]
        epoch = 0.d0 & radvel = 0.d0
        prlax = 0.d0 & pm = [0.d0,0.d0]
        return
    endif else begin            ; Star WAS found in kother.ascii
;        if not silent then print,'Found star in  ', otherfile
;        if not silent then print,'NOTE: Assuming equinox=2000 reading EPOCH from kother.ascii'
        rah = double(getwrd(data(othind),1))
        ram = double(getwrd(data(othind),2))
        ras = double(getwrd(data(othind),3))
        ra = ten([rah,ram,ras])
        decd = double(getwrd(data(othind),4))
        decm = double(getwrd(data(othind),5))
        decs = double(getwrd(data(othind),6))

        ; Added by BJ 01/21/2017 to deal with -00 .. .. declinations
        IF decd EQ 0 THEN BEGIN
            print, "Using -00 declination patch addded by BJ on 01/21/2017"
            dstr = getwrd(data(othind),4)
            IF strmid(dstr,0,1) EQ '-' THEN decm = -1 * abs(decm)
        ENDIF
        if decD eq 0 and decm eq 0 then begin
            print, "Using -00 declination patch addded by BJ on 01/21/2017"
            dstr = getwrd(data(othind,5)) 
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
    endelse
endif
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
