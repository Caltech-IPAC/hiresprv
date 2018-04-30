pro undither, wd_in, dwd_in, sd_in, ud_in, wu, dwu, su, uu, nu $
            , method=method, debug=debug
;
;Purpose:
; Combine multiple dithered spectra to form a coadded "undithered" spectrum,
; using a cubic spline with one node per output point to assign fractional
; pixel weights.
;
;Inputs:
; wd (vector or array(nwd)) central wavelength of each dithered sample
; dwd (vector or array(nwd)) wavelength span of each dithered sample
; sd (vector or array(nwd)) dithered spectrum values
; ud (vector or array(nwd)) uncertainty for each dithered spectrum value
; wu (vector(nwu)) central wavelengths for undithered spectrum
; dwu (vector(nwu)) wavelength span for undithered spectrum
; [method=] (scalar) integer specifying method to use
;
;Outputs:
; su (vector(nwu)) undithered spectrum values
; uu (vector(nwu)) uncertainty for undithered spectrum value
;[nu] (vector(nwu)) number of dithered samples in each undithered point.
;
;Notes:
; Input procedure arguments containing dithered data (with _in suffix) are
; sorted into ascending beginning wavelength order (without _in suffix).
;
;History:
; 2002 Nov 06 Valenti  Initial coding.

if n_params() lt 8 then begin
  print, 'undither, wd, dwd, sd, ud, wu, dwu, su, uu [,nu ,method= ,debug=]'
  return
endif

;Default values for optional parameters.
  if n_elements(method) eq 0 then method = 0
  if n_elements(debug) eq 0 then debug = 0

;Sort dithered data so that  beginning wavelength is in ascending order.
  isort = sort(wd_in - 0.5*dwd_in)		;sort indices
  wd = wd_in(isort)
  dwd = dwd_in(isort)
  sd = sd_in(isort)
  ud = ud_in(isort)

;Calculate beginning and ending wavelengths for dithered and undithered bins.
  wdb = wd - 0.5*dwd				;beg wave of each dith bin
  wde = wd + 0.5*dwd				;end wave of each dith bin
  wub = wu - 0.5*dwu				;beg wave of each undith bin
  wue = wu + 0.5*dwu				;end wave of each undith bin

;Get number of extrema of wavelength vectors.
  nwd = n_elements(wd)				;number of dith wave
  wdmin = wdb(0)				;min beg dith wave
  wdmax = wde(nwd-1)				;max end dith wave
  nwu = n_elements(wu)				;number of undith wave
  wumin = wub(0)				;min beg undith wave
  wumax = wue(nwu-1)				;max end undith wave

;Initialize output arrays.
  su = fltarr(nwu)
  uu = fltarr(nwu)
  nu = intarr(nwu)

;***********************************************************
;full-matrix linear least-squares solution for piston model.
if method eq 3 then begin

;truncate dithered pixels that extend beyond range of undithered pixels.
;otherwise solution is incorrect at ends.
  iwhr = where(wdb lt wub(0) and wde ge wub(0), nwhr)
  if nwhr gt 0 then begin
    sd(iwhr) = sd(iwhr) $
             * (wde(iwhr) - wub(0)) / (wde(iwhr) - wdb(iwhr))
  endif
  iwhr = where(wdb le wue(nwu-1) and wde gt wue(nwu-1), nwhr)
  if nwhr gt 0 then begin
    sd(iwhr) = sd(iwhr) $
             * (wue(nwu-1) - wdb(iwhr)) / (wde(iwhr) - wdb(iwhr))
  endif

;allocate arrays
  a = dblarr(nwu,nwu)
  b = dblarr(nwu)

;advance to the first dithered pixel that overlaps an undithered pixel.
  idb = 0L
  while wde(idb) le wub(0) and idb lt nwd-1 do idb = idb + 1
  if idb eq nwd-1 then begin
    message, 'dithered and undithered wavelengths do not overlap'
  endif

;loop through undithered pixels.
  for iu=0L, nwu-1 do begin

;find set of dithered pixels that overlap undithered pixel with index iu.
    while wde(idb) le wub(iu) and idb lt nwd-1 do idb = idb + 1
    ide = idb
    while wdb(ide) le wue(iu) and ide lt nwd-1 do ide = ide + 1
    if wdb(ide) gt wue(iu) then ide = ide - 1
    nu(iu) = ide - idb + 1
    if debug gt 1 then begin
      print, 'iu=' + strtrim(iu,2) + ': [idb,ide]=[' + strtrim(idb,2) $
           + ',' + strtrim(ide,2) + ']'
      print, ' wub(iu)=' + strtrim(wub(iu),2) + ', wue(iu)=' $
           + strtrim(wue(iu),2)
      print, ' wde(idb)=' + strtrim(wde(idb),2) + ', wdb(ide)=' $
           + strtrim(wdb(ide),2)
    endif

;calculate overlap between dithered pixels and current undithered pixel.
    wb = wdb(idb:ide) > wub(iu)
    we = wde(idb:ide) < wue(iu)
    olap = (we - wb) / dwu(iu)

;calculate b-vector element for current undithered pixel.
    b(iu) = total(sd(idb:ide)*olap/ud(idb:ide)^2)

;calculate a-matrix elements along main diagonal for current undithered pixel.
    a(iu,iu) = total((olap/ud(idb:ide))^2)

;calculate a-matrix elements left of main diagonal for current undith pixel.
    iu2 = iu - 1
    while iu2 ge 0 do begin
      wb2 = wdb(idb:ide) > wub(iu2)
      we2 = wde(idb:ide) < wue(iu2)
      olap2 = (we2 - wb2) / (wue(iu2) - wub(iu2))
      iwhr = where(olap2 gt 0, nwhr)
      if nwhr gt 0 then begin
        a(iu2,iu) = total(olap2(iwhr)*olap(iwhr)/ud(idb:ide)^2)
        if debug gt 1 then begin
          print,' a(' + strtrim(iu2,2) + ',' + strtrim(iu,2) + ')=' $
               + strtrim(a(iu2,iu)/a(iu,iu),2) + '*a(' + strtrim(iu,2) $
               + ',' + strtrim(iu,2) + ')'
        endif
        iu2 = iu2 - 1
      endif else begin
        iu2 = -1					;flag end of loop
      endelse
    endwhile

;calculate a-matrix elements right of main diagonal for current undith pixel.
    iu2 = iu + 1
    while iu2 lt nwu do begin
      wb2 = wdb(idb:ide) > wub(iu2)
      we2 = wde(idb:ide) < wue(iu2)
      olap2 = (we2 - wb2) / (wue(iu2) - wub(iu2))
      iwhr = where(olap2 gt 0, nwhr)
      if nwhr gt 0 then begin
        a(iu2,iu) = total(olap2(iwhr)*olap(iwhr)/ud(idb:ide)^2)
        if debug gt 1 then begin
          print,' a(' + strtrim(iu2,2) + ',' + strtrim(iu,2) + ')=' $
               + strtrim(a(iu2,iu)/a(iu,iu),2) + '*a(' + strtrim(iu,2) $
               + ',' + strtrim(iu,2) + ')'
        endif
        iu2 = iu2 + 1
      endif else begin
        iu2 = nwu					;flag end of loop
      endelse
    endwhile

;debug output
    if debug gt 2 then begin
      plot, idb+lindgen(ide-idb), olap $
          , xtit='Dithered Pixel Index' $
          , ytit='Fraction of Undithered Pixel Overlapping Dithered Pixel' $
          , tit='iu='+strtrim(iu,2) $
          , charsize=1.4, /xsty
    endif

;debug pause
    if debug gt 1 then begin
      junk = get_kbrd(1)
      if junk eq 'q' then retall
    endif

;end of b-vector and a-array building for current undithered pixel.
  endfor

;calculate guess for undithered spectrum using only main diagonal of matrix.
  idiag = (nwu + 1) * lindgen(nwu)
  guess = b / total(a, 1)

;solve least squares problem by inverting full matrix.
  svdc, a, svdw, svdu, svdv, /double
  su = svsol(svdu, svdw, svdv, b, /double)

;calculate covariance array.
  cov = 0
  for iu=0L, nwu-1 do begin
    cov = cov + (svdv(*,iu) # transpose(svdv(*,iu))) / svdw(iu)
  endfor
  uu = sqrt(cov(idiag))

;debug plot
  if debug gt 0 then begin
    print, ' min/max pivot: ' + strtrim(min(svdw)/max(svdw), 2)
    xguess = lindgen(nwu)
    plot, xguess, guess, ps=10 $
        , xtit='Undithered Pixel Index' $
        , ytit='Spectrum Estimate from Main Diagonal' $
        , charsize=1.4, /xsty
    colors
    oplot, !x.crange, [1,1], li=2, co=c24(4)
    oplot, !x.crange, [0,0], li=2, co=c24(4)
    oplot, xguess, 1-uu, ps=10, co=c24(6)
    oplot, xguess, 1+uu, ps=10, co=c24(6)
    oplot, xguess, su, ps=10, co=c24(3)
    junk = get_kbrd(1)
    if junk eq 'q' then retall
  endif

;return values to calling routine.
  return

endif

;*************************************************************
;sparse-matrix linear least-squares solution for piston model.
if method eq 4 then begin

;truncate dithered pixels that extend beyond range of undithered pixels.
;otherwise solution is incorrect at ends.
  iwhr = where(wdb lt wub(0) and wde ge wub(0), nwhr)
  if nwhr gt 0 then begin
    sd(iwhr) = sd(iwhr) $
             * (wde(iwhr) - wub(0)) / (wde(iwhr) - wdb(iwhr))
  endif
  iwhr = where(wdb le wue(nwu-1) and wde gt wue(nwu-1), nwhr)
  if nwhr gt 0 then begin
    sd(iwhr) = sd(iwhr) $
             * (wue(nwu-1) - wdb(iwhr)) / (wde(iwhr) - wdb(iwhr))
  endif

;allocate arrays
  sa = dblarr(nwu+1)				;will grow later
  ija = lonarr(nwu+1)				;will grow later
  b = dblarr(nwu)
  norm = dblarr(nwu)

;advance to the first dithered pixel that overlaps an undithered pixel.
  idb = 0L
  while wde(idb) le wub(0) and idb lt nwd-1 do idb = idb + 1
  if idb eq nwd-1 then begin
    message, 'dithered and undithered wavelengths do not overlap'
  endif

;loop through undithered pixels.
; debug = 0
  for iu=0L, nwu-1 do begin
    row = dblarr(nwu)

;find set of dithered pixels that overlap undithered pixel with index iu.
    while wde(idb) le wub(iu) and idb lt nwd-1 do idb = idb + 1
    ide = idb
    while wdb(ide) le wue(iu) and ide lt nwd-1 do ide = ide + 1
    if wdb(ide) gt wue(iu) then ide = ide - 1
    nu(iu) = ide - idb + 1
    if debug gt 1 then begin
      print, 'iu=' + strtrim(iu,2) + ': [idb,ide]=[' + strtrim(idb,2) $
           + ',' + strtrim(ide,2) + ']'
      print, ' wub(iu)=' + strtrim(wub(iu),2) + ', wue(iu)=' $
           + strtrim(wue(iu),2)
      print, ' wde(idb)=' + strtrim(wde(idb),2) + ', wdb(ide)=' $
           + strtrim(wdb(ide),2)
    endif

;calculate overlap between dithered pixels and current undithered pixel.
    wb = wdb(idb:ide) > wub(iu)
    we = wde(idb:ide) < wue(iu)
    olap = (we - wb) / dwu(iu)

;calculate b-vector element for current undithered pixel.
    b(iu) = total(sd(idb:ide)*olap/ud(idb:ide)^2)

;calculate a-matrix elements along main diagonal for current undithered pixel.
    sa(iu) = total((olap/ud(idb:ide))^2)
    norm(iu) = sa(iu)

;calculate a-matrix elements left of main diagonal for current undith pixel.
    iu2 = iu - 1
    while iu2 ge 0 do begin
      wb2 = wdb(idb:ide) > wub(iu2)
      we2 = wde(idb:ide) < wue(iu2)
      olap2 = (we2 - wb2) / (wue(iu2) - wub(iu2))
      iwhr = where(olap2 gt 0, nwhr)
      if nwhr gt 0 then begin
        row(iu2) = total(olap2(iwhr)*olap(iwhr)/ud(idb:ide)^2)
        if debug gt 1 then begin
          print,' a(' + strtrim(iu2,2) + ',' + strtrim(iu,2) + ')=' $
               + strtrim(row(iu2)/sa(iu),2) + '*a(' + strtrim(iu,2) $
               + ',' + strtrim(iu,2) + ')'
        endif
        iu2 = iu2 - 1
      endif else begin
        iu2 = -1					;flag end of loop
      endelse
    endwhile

;calculate a-matrix elements right of main diagonal for current undith pixel.
    iu2 = iu + 1
    while iu2 lt nwu do begin
      wb2 = wdb(idb:ide) > wub(iu2)
      we2 = wde(idb:ide) < wue(iu2)
      olap2 = (we2 - wb2) / (wue(iu2) - wub(iu2))
      iwhr = where(olap2 gt 0, nwhr)
      if nwhr gt 0 then begin
        row(iu2) = total(olap2(iwhr)*olap(iwhr)/ud(idb:ide)^2)
        if debug gt 1 then begin
          print,' a(' + strtrim(iu2,2) + ',' + strtrim(iu,2) + ')=' $
               + strtrim(row(iu2)/sa(iu),2) + '*a(' + strtrim(iu,2) $
               + ',' + strtrim(iu,2) + ')'
        endif
        iu2 = iu2 + 1
      endif else begin
        iu2 = nwu					;flag end of loop
      endelse
    endwhile

;store nonzero elements for current row.
;also calculate initial guess for current row.
  ija(iu) = 1 + n_elements(sa)		;1+index where off-diag row data begins
  inz = where(row ne 0, nnz)
  if nnz gt 0 then begin
    sa = [temporary(sa), row(inz)]
    ija = [temporary(ija), 1 + inz]
    norm(iu) = norm(iu) + total(row(inz))
  endif

;debug output
    if debug gt 2 then begin
      plot, idb+lindgen(ide-idb), olap $
          , xtit='Dithered Pixel Index' $
          , ytit='Fraction of Undithered Pixel Overlapping Dithered Pixel' $
          , tit='iu='+strtrim(iu,2) $
          , charsize=1.4, /xsty
    endif

;debug pause
    if debug gt 1 then begin
      junk = get_kbrd(1)
      if junk eq 'q' then retall
    endif

;end of b-vector and a-array building for current undithered pixel.
  endfor

;Fill in remaining entry in ija.
  ija(nwu) = 1 + n_elements(sa)

;calculate guess for undithered spectrum.
  guess = b / norm

;construct sparse matrix in standard form required by linbcg routine.
;USE LONG() FOR 32-BIT IDL and LONG64() FOR 64-BIT IDL.
sprs = {sa:temporary(sa), ija:long(temporary(ija))}
; sprs = {sa:temporary(sa), ija:long64(temporary(ija))}

;solve least squares problem using sparse matices.
  su = linbcg(sprs, b, guess, /double)

;calculate covariance array.
; cov = 0
; for iu=0, nwu-1 do begin
;   cov = cov + (svdv(*,iu) # transpose(svdv(*,iu))) / svdw(iu)
; endfor
; uu = sqrt(cov(idiag))

;debug plot
  if debug gt 0 then begin
    xguess = lindgen(nwu)
    plot, xguess, guess, ps=10 $
        , xtit='Undithered Pixel Index' $
        , ytit='Spectrum Estimate from Main Diagonal' $
        , charsize=1.4, /xsty
    colors
    oplot, !x.crange, [1,1], li=2, co=c24(4)
    oplot, !x.crange, [0,0], li=2, co=c24(4)
    oplot, xguess, 1-uu, ps=10, co=c24(6)
    oplot, xguess, 1+uu, ps=10, co=c24(6)
    oplot, xguess, su, ps=10, co=c24(3)
    junk = get_kbrd(1)
    if junk eq 'q' then retall
  endif

;return values to calling routine.
  return

endif

;****************************************************************
;full-matrix linear least-squares solution for trapezoidal model.
if method eq 5 then begin

;truncate dithered pixels that extend beyond range of undithered pixels.
;otherwise solution is incorrect at ends.
  iwhr = where(wdb lt wub(0) and wde ge wub(0), nwhr)
  if nwhr gt 0 then begin
    sd(iwhr) = sd(iwhr) $
             * (wde(iwhr) - wub(0)) / (wde(iwhr) - wdb(iwhr))
  endif
  iwhr = where(wdb le wue(nwu-1) and wde gt wue(nwu-1), nwhr)
  if nwhr gt 0 then begin
    sd(iwhr) = sd(iwhr) $
             * (wue(nwu-1) - wdb(iwhr)) / (wde(iwhr) - wdb(iwhr))
  endif

;allocate arrays
  a = dblarr(nwu,nwu)
  b = dblarr(nwu)

;advance to the first dithered pixel that overlaps an undithered pixel.
  idb = 0L
  while wde(idb) le wub(0) and idb lt nwd-1 do idb = idb + 1
  if idb eq nwd-1 then begin
    message, 'dithered and undithered wavelengths do not overlap'
  endif

;loop through undithered pixels.
; debug = 0
  for iu=0L, nwu-1 do begin

;find set of dithered pixels that overlap undithered pixel with index iu.
    while wde(idb) le wub(iu) and idb lt nwd-1 do idb = idb + 1
    ide = idb
    while wdb(ide) le wue(iu) and ide lt nwd-1 do ide = ide + 1
    if wdb(ide) gt wue(iu) then ide = ide - 1
    nu(iu) = ide - idb + 1
    if debug gt 1 then begin
      print, 'iu=' + strtrim(iu,2) + ': [idb,ide]=[' + strtrim(idb,2) $
           + ',' + strtrim(ide,2) + ']'
      print, ' wub(iu)=' + strtrim(wub(iu),2) + ', wue(iu)=' $
           + strtrim(wue(iu),2)
      print, ' wde(idb)=' + strtrim(wde(idb),2) + ', wdb(ide)=' $
           + strtrim(wdb(ide),2)
    endif

;calculate overlap between dithered pixels and current undithered pixel.
    wb1 = wdb(idb:ide) > wub(iu)		;blue half of pixel
    we1 = wde(idb:ide) < wu(iu)
    olap1 = ((we1 - wb1) / dwu(iu)) > 0
    wb2 = wdb(idb:ide) > wu(iu) < wde(idb:ide)	;red half of pixel
    we2 = wde(idb:ide) < wue(iu)
    olap2 = ((we2 - wb2) / dwu(iu)) > 0
    olap = olap1 + olap2

;debug output
    if debug gt 1 then begin
      yr = minmax([wdb(idb:ide),wde(idb:ide)])
      id = idb+lindgen(ide-idb+1)
      plot, id, wdb(idb:ide) $
          , xtit='Index of Dithered Pixel' $
          , ytit='Wavelength' $
          , tit='iu='+strtrim(iu,2) $
          , charsize=1.4, /xsty, yr=yr, ysty=3
      colors
      oplot, id, wde(idb:ide)
      oplot, id, wb1, li=2, co=c24(4)
      oplot, id, we2, li=2, co=c24(2)
      ib = min(where(olap2 gt 0)) > 0
      ie = min(where(olap1 eq 0))
      if ie eq -1 then ie = max(id)
      oplot, idb+[ib,ie], wu(iu)+[0,0], co=c24(3)
      junk = get_kbrd(1)
      if junk eq 'q' then retall
    endif 

;calculate b-vector element for current undithered pixel.
    b(iu) = total(sd(idb:ide)*olap/ud(idb:ide)^2)

;calculate a-matrix elements along main diagonal for current undithered pixel.
    a(iu,iu) = total((olap/ud(idb:ide))^2)

;calculate a-matrix elements left of main diagonal for current undith pixel.
    iu3 = iu - 1
    while iu3 ge 0 do begin
      wb3 = wdb(idb:ide) > wub(iu3)
      we3 = wde(idb:ide) < wue(iu3)
      olap3 = (we3 - wb3) / (wue(iu3) - wub(iu3))
      iwhr = where(olap3 gt 0, nwhr)
      if nwhr gt 0 then begin
        a(iu3,iu) = total(olap3(iwhr)*olap(iwhr)/ud(idb:ide)^2)
        if debug gt 1 then begin
          print,' a(' + strtrim(iu3,2) + ',' + strtrim(iu,2) + ')=' $
               + strtrim(a(iu3,iu)/a(iu,iu),2) + '*a(' + strtrim(iu,2) $
               + ',' + strtrim(iu,2) + ')'
        endif
        iu3 = iu3 - 1
      endif else begin
        iu3 = -1					;flag end of loop
      endelse
    endwhile

;calculate a-matrix elements right of main diagonal for current undith pixel.
    iu3 = iu + 1
    while iu3 lt nwu do begin
      wb3 = wdb(idb:ide) > wub(iu3)
      we3 = wde(idb:ide) < wue(iu3)
      olap3 = (we3 - wb3) / (wue(iu3) - wub(iu3))
      iwhr = where(olap3 gt 0, nwhr)
      if nwhr gt 0 then begin
        a(iu3,iu) = total(olap3(iwhr)*olap(iwhr)/ud(idb:ide)^2)
        if debug gt 1 then begin
          print,' a(' + strtrim(iu3,2) + ',' + strtrim(iu,2) + ')=' $
               + strtrim(a(iu3,iu)/a(iu,iu),2) + '*a(' + strtrim(iu,2) $
               + ',' + strtrim(iu,2) + ')'
        endif
        iu3 = iu3 + 1
      endif else begin
        iu3 = nwu					;flag end of loop
      endelse
    endwhile

;debug output
    if debug gt 2 then begin
      id = idb+lindgen(ide-idb)
      plot, id, olap $
          , xtit='Dithered Pixel Index' $
          , ytit='Fraction of Undithered Pixel Overlapping Dithered Pixel' $
          , tit='iu='+strtrim(iu,2) $
          , charsize=1.4, /xsty
      colors
      oplot, id, olap1, li=2, co=c24(4)
      oplot, id, olap2, li=2, co=c24(2)
    endif

;debug pause
    if debug gt 1 then begin
      junk = get_kbrd(1)
      if junk eq 'q' then retall
    endif

;end of b-vector and a-array building for current undithered pixel.
  endfor

;calculate guess for undithered spectrum using only main diagonal of matrix.
  idiag = (nwu + 1) * lindgen(nwu)
  guess = b / total(a, 1)

;solve least squares problem by inverting full matrix.
  svdc, a, svdw, svdu, svdv, /double
  su = svsol(svdu, svdw, svdv, b, /double)

;calculate covariance array.
  cov = 0
  for iu=0L, nwu-1 do begin
    cov = cov + (svdv(*,iu) # transpose(svdv(*,iu))) / svdw(iu)
  endfor
  uu = sqrt(cov(idiag))

;debug plot
  if debug gt 0 then begin
    print, ' min/max pivot: ' + strtrim(min(svdw)/max(svdw), 2)
    xguess = lindgen(nwu)
    plot, xguess, guess, ps=10 $
        , xtit='Undithered Pixel Index' $
        , ytit='Spectrum Estimate from Main Diagonal' $
        , charsize=1.4, /xsty
    colors
    oplot, !x.crange, [1,1], li=2, co=c24(4)
    oplot, !x.crange, [0,0], li=2, co=c24(4)
    oplot, xguess, 1-uu, ps=10, co=c24(6)
    oplot, xguess, 1+uu, ps=10, co=c24(6)
    oplot, xguess, su, ps=10, co=c24(3)
    junk = get_kbrd(1)
    if junk eq 'q' then retall
  endif

;return values to calling routine.
  return

endif

;*************************************************************
;other solution methods.

  m = replicate(1.0,nwu)			;model spectrum at nodes

new_maxdev = 1e30
iloop = 0
repeat begin

;Advance to the first dithered sample that overlaps an undithered pixel.
  idb = -1L
  repeat idb = idb + 1 until wdb(idb) gt wub(0)
  ide = idb

;Loop through undithered pixels, averaging contributions from dithered samples.
  done = 0
  for iu=0L, nwu-1 do begin
    maxdev = new_maxdev
    if done ne 1 then begin
      while wdb(ide) lt wue(iu) and ide lt nwd-1 do ide = ide + 1
      if ide lt nwd-1 then ide = ide - 1
      n = ide - idb + 1
      nu(iu) = n
      if n gt 0 then begin
        case method of
;phil's technique
          0: begin
             wb = wdb(idb:ide) > wub(iu)
             we = wde(idb:ide) < wue(iu)
             frac = (we - wb) / dwu(iu)
             wt = frac / ud(idb:ide)^2
             su(iu) = total(wt * sd(idb:ide)) / total(wt)
             uu(iu) = sqrt(total(1.0 / total(wt)))
             end
          1: begin
             r = (wue(iu)-wub(iu)) / (wde(idb:ide)-wdb(idb:ide))
             su(iu) = total(sd(idb:ide) / r / ud(idb:ide)^2) $
                    / total(1.0 / r^2 / ud(idb:ide)^2)
             uu(iu) = sqrt(1.0 / total(1.0 / r^2 / ud(idb:ide)^2))
             end
          2: begin
             r = fltarr(n)
             for i=0, n-1 do begin
               iub = iu
               while wub(iub) gt wdb(idb+i) and iub gt 0 do iub = iub - 1
               iue = iu
               while wue(iue) lt wde(idb+i) and iue lt nwu-1 do iue = iue + 1
               sum = total(m(iub:iue)) $
                   - m(iub) * (wdb(idb+i) - wub(iub)) / dwu(iub) $
                   - m(iue) * (wue(iue) - wde(idb+i)) / dwu(iue)
               r(i) = m(iu) / sum
             endfor
             su(iu) = total(sd(idb:ide) / r / ud(idb:ide)^2) $
                    / total(1.0 / r^2 / ud(idb:ide)^2)
             uu(iu) = sqrt(1.0 / total(1.0 / r^2 / ud(idb:ide)^2))
             end
        endcase
      endif
      if iu lt nwu-1 then begin
        while wde(idb) le wub(iu+1) and idb lt nwd-1 do idb = idb + 1
        if wde(idb) le wub(iu+1) then done = 1
        ide = idb
      endif
    endif
  endfor

if method gt 1 then print,method,iloop,max(abs(su-m)),max(abs(su-m)/uu)
new_maxdev = max(abs(su-m)/uu)
m = su
iloop = iloop + 1
endrep until method le 1 $
          or new_maxdev gt maxdev $
          or iloop eq 20

end
