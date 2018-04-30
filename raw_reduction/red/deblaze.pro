pro deblaze,file=file
; Removes the non-physical blaze function from each individual order of the three HIRES ccds
;
; INPUT:
;    Reduced spectrum in directory defined by environment variable
;
; OUTPUT
;    Deblazed spectrum in directory defined by environment variable
;
; EXAMPLE:
;    deblaze,file='rj285.86.fits'
;
; NOTES:
;    The final deblazed file contains:
;      (1) The deblazed, reduced spectrum with gain applied: spec = readfits('rj123.123.fits',exten=0) 
;      (2) An error spectrum: errspec = readfits('rj123.123.fits',exten=1)
;      (3) The standard Keck wavelength scale: wav = readfits('rj123.123.fits',exten=2)
;      (4) The original FITS header information: hdr = headfits('rj123.123.fits')
;
; 02-Oct-13 KIC  Ready for prime-time.
; Mar 2018  HTI  References to dependent directories now environmental variables.

trace,5,'DEBLAZE: Starting the deblazing process for ' + file

; Use an environmnet variable to control directory output.
ioddir = getenv("RAW_ALL_OUT_FITS")     ; same for all chips
savedir = getenv("RAW_ALL_OUT_FITS_DB") ;same for all chips
reduce_dir = getenv("RAW_MID")
prefix = 'j'

bgain = 1.95  ; blue ccd low gain (http://www2.keck.hawaii.edu/inst/hires/ccdgain.html)
rgain = 2.09  ; green ccd low gain (http://www2.keck.hawaii.edu/inst/hires/ccdgain.html)
igain = 2.09  ; red ccd low gain (http://www2.keck.hawaii.edu/inst/hires/ccdgain.html)

pos1 = strpos(file,prefix)
chip = strmid(file,pos1-1,1)
filename = strmid(file,pos1-1,strlen(file))

if chip eq 'b' then bbstar = readfits(reduce_dir+'bluebstar.fits')
if chip eq 'r' then rbstar = readfits(reduce_dir+'iodbstar.fits')
if chip eq 'i' then ibstar = readfits(reduce_dir+'redbstar.fits')

if chip eq 'b' then begin
    bdum = size(bbstar)
    bnorders = bdum[2]
    bstarname = ioddir + filename
print,"Bstarname:",bstarname
    bstar = readfits(bstarname,bh)


    bstardum = bstar * bgain
    a = where(bstardum le 0,nzero)   ;search for zeros and negatives
    if nzero ge 1 then bstardum(a) = median(bstardum)  ;replace zeros and negs with mean
    berrspec = sqrt(1./bstardum + 0.005^2)

    bluespec = fltarr(4021,bnorders)
    
endif
if chip eq 'r' then begin
    rdum = size(rbstar)
    rnorders = rdum[2]        
    rstarname = ioddir + filename
    rstar = readfits(rstarname,rh)

    rstardum = rstar * rgain
    a = where(rstardum le 0,nzero)   ;search for zeros and negatives
    if nzero ge 1 then rstardum(a) = median(rstardum)  ;replace zeros and negs with mean
    rerrspec = sqrt(1./rstardum + 0.005^2)

    iodspec = fltarr(4021,rnorders)
    
endif
if chip eq 'i' then begin
    idum = size(ibstar)
    inorders = idum[2]
    istarname = ioddir + filename
    istar = readfits(istarname,ih)

    istardum = istar * igain
    a = where(istardum le 0,nzero)   ;search for zeros and negatives
    if nzero ge 1 then istardum(a) = median(istardum)  ;replace zeros and negs with mean
    ierrspec = sqrt(1./istardum + 0.005^2)
    
    redspec = fltarr(4021,inorders)
    
endif

  
 if chip eq 'b' then begin
  for i = 0, bnorders-1 do begin

    ist = strtrim(string(i),2)

    bspec = bbstar[*,i]
    spec = bstar[*,i]

    bstarmax = max(bspec)
    starmax = max(spec)

    if (i eq 0) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 1) then begin
      a = indgen(109-0)
      b = indgen(2157-2094) + 2094
      c = indgen(2819-2756) + 2756
      d = indgen(4020-3660) + 3660
      mask = [a,b,c,d]
      sbin = 20
      nord = 5
      frac = 0.05
      smask = [-1]
      ssbin = 11
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 2) then begin
      a = indgen(70-0)
      b = indgen(521-412) + 412
      c = indgen(1347-1199) + 1199
      d = indgen(2398-2313) + 2313
      e = indgen(4020-3699) + 3699
      mask = [a,b,c,d,e]
      sbin = 20
      nord = 5
      frac = 0.05
      smask = [-1]
      ssbin = 6
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 3) then begin
      a = indgen(163-0)
      b = indgen(1600-1417) + 1417
      c = indgen(4020-3021) + 3021
      mask = [a,b,c]
      sbin = 40
      nord = 6
      frac = 0.05
      smask = [-1]
      ssbin = 6
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 4) then begin
      a = indgen(942-0)
      b = indgen(1432-1355) + 1355
      c = indgen(4020-2718) + 2718
      mask = [a,b,c]
      sbin = 75
      nord = 6
      frac = 0.05
      d = indgen(1400-0)
      e = indgen(4020-2500) + 2500
      smask = [d,e]
      ssbin = 5
      snord = 4
      sfrac = 0.04
    endif

    if (i eq 5) then begin
      a = indgen(1947-0)
      b = indgen(4020-3457) + 3457
      mask = [a,b]
      sbin = 20
      nord = 7
      frac = 0.05
      smask = [-1]
      ssbin = 6
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 6) then begin
      a = indgen(31-0)
      b = indgen(2585-1370) + 1370
      c = indgen(4020-3708) + 3708
      mask = [a,b,c]
      sbin = 50
      nord = 5
      frac = 0.05
      c = indgen(2300-0)
      d = indgen(4020-3400) + 3400
      smask = [c,d]
      ssbin = 5
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 7) then begin
      a = indgen(171-0)
      b = indgen(1760-700) + 700
      c = indgen(4020-3263) + 3263
      mask = [a,b,c]
      sbin = 50
      nord = 8
      frac = 0.05
      c = indgen(100-0)
      d = indgen(1800-1000) + 1000
      e = indgen(4020-2900) + 2900
      smask = [c,d,e]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 8) then begin
      a = indgen(1830-0)
      b = indgen(2850-2476) + 2476
      c = indgen(4020-3457) + 3457
      mask = [a,b,c]
      sbin = 20
      nord = 5
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 4
      sfrac = 0.04
    endif

    if (i eq 9) then begin
      a = indgen(295-0)
      b = indgen(4020-911) + 911
      mask = [a,b]
      sbin = 40
      nord = 5
      frac = 0.05
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif
    
    if (i eq 10) then begin
      a = indgen(1000-0)
      b = indgen(4020-2982) + 2982
      mask = [a,b]
      sbin = 75
      nord = 8
      frac = 0.05
      c = indgen(1800-0)
      d = indgen(4020-2500) + 2500
      smask = [c,d]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 11) then begin
      a = indgen(1690-0)
      b = indgen(4020-2157) + 2157
      mask = [a,b]
      sbin = 50
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 12
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 12) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      a = indgen(3000-0)
      smask = [a]
      ssbin = 7
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 13) then begin
      a = indgen(3356-0)
      b = indgen(4020-3894) + 3894
      mask = [a,b]
      sbin = 60
      nord = 5
      frac = 0.32
	  a = indgen(200-0)
	  b = indgen(2200-2000) + 2000
	  c = indgen(3200-3000) + 3000
	  d = indgen(4020-3900) + 3900
      smask = [a,b,c,d]
      ssbin = 4
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 14) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 15) then begin
      a = indgen(800-0)
      b = indgen(4020-2600) + 2600
      mask = [a,b]
      sbin = 60
      nord = 6
      frac = 0.32
      c = indgen(1300-0)
      d = indgen(4020-2000) + 2000
      smask = [c,d]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 16) then begin
      a = indgen(973-0)
      b = indgen(4020-1549) + 1549
      mask = [a,b]
      sbin = 20
      nord = 6
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 17) then begin
      a = indgen(2406-0)
      b = indgen(3006-2959) + 2959
      c = indgen(4020-3473) + 3473
      mask = [a,b,c]
      sbin = 60
      nord = 6
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 18) then begin
      a = indgen(194-0)
      b = indgen(4020-615) + 615
      mask = [a,b]
      sbin = 90
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i gt 18 and i lt 22) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif
    
    if (i eq 22) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 1
      sfrac = 0.04
    endif

    if (mask[0] ne -1) then contf_kic,bspec,c,sbin=sbin,nord=nord,frac=frac,mask=mask
    if (mask[0] eq -1) then contf_kic,bspec,c,sbin=sbin,nord=nord,frac=frac
    
    cmed = median(c)
    medc = c/cmed

    lamp = strtrim(sxpar(bh,'LAMPNAME'),2)

    if (median(spec) lt 100 or lamp ne 'none') then begin  ; only divide by bstar continuum, don't do additional contf_kic to remove trends
    
      newbspec = spec/medc
      
    endif else begin 

      if (smask[0] ne -1) then contf_kic,spec/medc,cspec,sbin=ssbin,nord=snord,frac=sfrac,mask=smask
      if (smask[0] eq -1) then contf_kic,spec/medc,cspec,sbin=ssbin,nord=snord,frac=sfrac
    
      cspecmed = median(cspec)
      medcspec = cspec/cspecmed

      newbspec = (spec/medc)/medcspec

    endelse

    bluespec[*,i] = newbspec

  endfor
  
  endif

if chip eq 'r' then begin

  for i = 0, rnorders-1 do begin

    ist = strtrim(string(i),2)

    bspec = rbstar[*,i]
    spec = rstar[*,i]

    bstarmax = max(bspec)
    starmax = max(spec)

    if (i eq 0) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 1) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 2) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      a = indgen(1900-0)
      b = indgen(4020-3000) + 3000
      smask = [a,b]
      ssbin = 5
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 3) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 4) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 5) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 6) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 7) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 8) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 9) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif
    
    if (i eq 10) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      a = indgen(3400-0)
      smask = [a]
      ssbin = 7
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 11) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      a = indgen(4020-600) + 600
      smask = [a]
      ssbin = 8
      snord = 1
      sfrac = 0.04
    endif

    if (i eq 12) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 13) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 10
      snord = 3
      sfrac = 0.04
    endif

    if (mask[0] ne -1) then contf_kic,bspec,c,sbin=sbin,nord=nord,frac=frac,mask=mask
    if (mask[0] eq -1) then contf_kic,bspec,c,sbin=sbin,nord=nord,frac=frac
      
    cmed = median(c)
    medc = c/cmed
    
    lamp = strtrim(sxpar(rh,'LAMPNAME'),2)

    if (median(spec) lt 100 or lamp ne 'none') then begin  ; only divide by bstar continuum, don't do additional contf_kic to remove trends
    
      newrspec = spec/medc
      
    endif else begin 

      if (smask[0] ne -1) then contf_kic,spec/medc,cspec,sbin=ssbin,nord=snord,frac=sfrac,mask=smask
      if (smask[0] eq -1) then contf_kic,spec/medc,cspec,sbin=ssbin,nord=snord,frac=sfrac

      cspecmed = median(cspec)
      medcspec = cspec/cspecmed

      newrspec = (spec/medc)/medcspec
    
    endelse

    iodspec[*,i] = newrspec

  endfor
  
  endif
  
 if chip eq 'i' then begin
  for i = 0, inorders-1 do begin

    ist = strtrim(string(i),2)

    bspec = ibstar[*,i]
    spec = istar[*,i]

    bstarmax = max(bspec)
    starmax = max(spec)

    if (i eq 0) then begin
      a = indgen(101-0)
      b = indgen(4020-1417) + 1417
      mask = [a,b]
      sbin = 68
      nord = 5
      frac = 0.32
      c = indgen(300-0)
      d = indgen(4020-1000) + 1000
      smask = [c,d]
      ssbin = 50
      snord = 5
      sfrac = 0.04
    endif

    if (i eq 1) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 2) then begin
      a = indgen(2328-0)
      b = indgen(4020-2795) + 2795
      mask = [a,b]
      sbin = 45  ;was 89
      nord = 10
      frac = 0.05
      smask = mask
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 3) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.05
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 4) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.05
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 5) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.05
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 6) then begin
      mask = [-1]
      sbin = 100
      nord = 10
      frac = 0.32
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 7) then begin
      bspec[3920:4020] = 260000
      a = indgen(400-0)
      b = indgen(2000-1000) + 1000
      c = indgen(3013-2967) + 2967
      d = indgen(4020-3920) + 3920
      mask = [a,b,c,d]
      sbin = 59
      nord = 5
      frac = 0.32
      e = indgen(1000-400) + 400
      smask = [a,e,b,c]
      ssbin = 20
      snord = 2
      sfrac = 0.04
    endif

    if (i eq 8) then begin
      a = indgen(2383-50) + 50
      b = indgen(4020-3387) + 3387
      mask = [a,b]
      sbin = 75
      nord = 10
      frac = 0.05
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (i eq 9) then begin
      bspec = bspec[200:3300]
      spec = spec[200:3300]
      a = indgen(1000-0)
      b = indgen(1800-1200) + 1200
      c = indgen(4020-2800) + 2800
      mask = [a,b,c]
      sbin = 100
      nord = 5
      frac = 0.05
      smask = [-1]
      ssbin = 20
      snord = 3
      sfrac = 0.04
    endif

    if (mask[0] ne -1) then contf_kic,bspec,c,sbin=sbin,nord=nord,frac=frac,mask=mask
    if (mask[0] eq -1) then contf_kic,bspec,c,sbin=sbin,nord=nord,frac=frac
      
    cmed = median(c)
    medc = c/cmed
    
    lamp = strtrim(sxpar(ih,'LAMPNAME'),2)

    if (median(spec) lt 100 or lamp ne 'none') then begin  ; only divide by bstar continuum, don't do additional contf_kic to remove trends
    
      if (i ne 9) then newispec = spec/medc
      if (i eq 9) then newispec = [indgen(200)*0,spec/medc,indgen(4020-3300)*0]
      
    endif else begin 

      if (smask[0] ne -1) then contf_kic,spec/medc,cspec,sbin=ssbin,nord=snord,frac=sfrac,mask=smask
      if (smask[0] eq -1) then contf_kic,spec/medc,cspec,sbin=ssbin,nord=snord,frac=sfrac
    
      cspecmed = median(cspec)
      medcspec = cspec/cspecmed

      if (i ne 9) then newispec = (spec/medc)/medcspec
      if (i eq 9) then newispec = [indgen(200)*0,(spec/medc)/medcspec,indgen(4020-3300)*0]

    endelse

    redspec[*,i] = newispec

  endfor
  
  endif
  
  if chip eq 'b' then begin
    writefits,savedir + filename,bluespec,bh
    writefits,savedir + filename,berrspec,/append
    bwav = readfits(reduce_dir+'keck_bwav.fits')
    writefits,savedir + filename,bwav,/append
 
  ENDIF
  if chip eq 'r' then begin
    writefits,savedir + filename,iodspec,rh
    writefits,savedir + filename,rerrspec,/append
    rwav = readfits(reduce_dir+'keck_rwav.fits')
    writefits,savedir + filename,rwav,/append
  endif 
  if chip eq 'i' then begin
    writefits,savedir + filename,redspec,ih
    writefits,savedir + filename,ierrspec,/append
    iwav = readfits(reduce_dir+'keck_iwav.fits')
    writefits,savedir + filename,iwav,/append
  endif
  
  spawn,"chmod g+w "+ savedir+filename
  
  trace,5,'DEBLAZE: Finished deblazing process for ' + savedir+filename

end
