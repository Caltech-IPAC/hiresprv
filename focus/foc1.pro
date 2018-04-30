pro foc1

  !p.multi=0
  minim = median(im)
  xs=indgen(n_elements(im(*,0)))
  ys=indgen(n_elements(im(0,*)))
!p.charsize=1.8
  titl = '!6HIRES Thorium Lines and Locations of Focus Lines'
  yt='ROW #'
  xt='COL #'
 ; display,im(*,400:999),xs,ys,min=minim,max=500,titl=titl,ytit=yt,xtit=xt
  ;!p.color=300
  ;display,im,xs,ys,min=880,max=970,titl=titl,ytit=yt,xtit=xt
  ;loadct,0
  ;display,im,xs,ys,min=950,max=1500,titl=titl,ytit=yt,xtit=xt
  !p.charsize=1.3
  display,im,xs,ys,min=950,max=1500,titl=titl,ytit=yt,xtit=xt,/psfine
  oplot,x,y+2,ps=6,symsize=2,thick=1 ;boxes at LINE LOC's (+1 is kludge)
;  oplot,x,y+2,ps=6,symsize=1.8,thick=2 ; at LINE LOC's (+1 is kludge)
;  oplot,x,y+2,ps=6,symsize=1.8,thick=2 ;at LINE LOC's (+1 is kludge)
;loadct,13
;  oplot,x,y+2,ps=6,symsize=1.8,thick=2,co=20
; SPECIAL SECTION TO FIND LINE LOCATIONS OF NEW CCD

  IF keyword_set(findloc) then begin
;  Find Line Locations on a new CCD chip
    print, 'New Line Locations will be stored in lines.found '
    openw, 2, 'lines.found'
    nl = n_elements(x)          ;Final No. of Th lines
    sz = 7
    boxsz = sz*2+1              ;11 x 11 pixels around each Th line.
;nl =  25
;print,'Choose 25 lines:'
    FOR j = 0, nl-1 do begin
      print, j
      oplot, [x(j)], [y(j)], ps = 6, symsize = 2
      cursor, a, b 
      c1 = a-sz  & c2 = a+sz
      r1 = b-sz  & r2 = b+sz
      box = float(im(c1:c2, r1:r2)) ;box within image containing Th line
      bckg = median([box(0, 0:boxsz-1), box(boxsz-1, 0:boxsz-1)]) ;lft, rt edges
      box = box - bckg          ;sub backgr
      mashcol = total(box, 1)   ;mashed cols w/i box
      mashrow = total(box, 2)   ;mashed rows
;     dum = max(mashcol,rowloc) & rowloc=fix(rowloc(0))+r1+.5
      dum = max(mashcol, rowloc) & rowloc = b ;kludge in cursor position
      dum = max(mashrow, colloc) & colloc = fix(colloc(0))+c1+.5
      printf, 2, colloc, rowloc
      print, colloc, rowloc
      wait, 1
    END
    close, 2
  END                           ;END FIND LINE LOCATIONS
  read, 'Hit <RETURN> to proceed on: ', ans
;END


;  numcol = dimen(im,0)               ;No. of col's
;  numrow = dimen(im,1)               ;No. of rows
  xmid = numcol/2.                   ; middle col of chip
  ymid = numrow/2.                   ; middle row of chip
  nfound = 0
  a = fltarr(3)              ;gauss params: a(1)=cen, a(2)=sigma
print, 'numcol=', numcol
print, 'numrow=', numrow
;
IF keyword_set(plt) then begin
  !p.charsize=1.
  !p.multi = [0,2,2]
END
;
;Reject Th lines that lie too close to edges (within sz of edge)
  i = where(x gt sz and x lt numcol-boxsz and $
            y gt sz and y lt numrow-boxsz)     ;indices well within edges
  x = x(i) & y = y(i)      ;Use only Th lines well inside edge of CCD
  nl = n_elements(x)        ;Final No. of Th lines
;
;Initialize Some More Variables (that depend on the # of lines, nl)
  fwhmx = fltarr(nl)   ;FWHM in the COLUMN direction (= 1.18 sigma) 
  fwhmy = fltarr(nl)   ;FWHM in the ROW    direction
  fw10x = fltarr(nl)   ;FW at 10% of peak of each line
  asym  = fltarr(nl)   ;asymmetry index of each line 
  dx    =fltarr(nl)    ;found - expected column position
  dy    =fltarr(nl)    ;found - expected row position
  allprofs= fltarr(finelen,nl)       ;all Thorium profiles
  r     = sqrt((x-xmid)^2 + (y-ymid)^2)   ;radial distance from image center 
;
if keyword_set(pr) then begin
  print,' '
  print,' _____________________________________________________________ '
  print,'|  Column     Row   Peak Cts      FWHM    FW@10%    ASYM      |'  
  print,'|_____________________________________________________________|'
end
 form='(A1,I8,I8,I8,A3,F10.2,F10.2,F10.2,A5)'
;
print, 'Nunber of lines:', nl

end













































































