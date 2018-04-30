;+
; NAME:
;   PLOTCUBE
;
; AUTHOR:
;   Craig B. Markwardt, NASA/GSFC Code 662, Greenbelt, MD 20770
;   craigm@lheamail.gsfc.nasa.gov
;
; PURPOSE:
;   Plots a three dimensional data that can be printed and made into a cube
;
; CALLING SEQUENCE:
;   PLOTCUBE, x, y, z
;
; DESCRIPTION: 
;
;   PLOTCUBE plots a three dimensional data set so that it can be
;   printed on paper, cut out, and folded together to make a real-life
;   three dimensional cube.  This may be useful in visualization
;   applications.  The six faces of the cube contain a projection of
;   the data onto that face.
;
;   The output consists of a flat matrix of six plots, which are
;   joined together at the proper edges of the cube.  Your task,
;   should you choose to accept it, is to cut out the cube and
;   assemble it.
;
;   Before folding the cube together, it will look like the diagram
;   below.  You need to match together edges labelled with the same
;   letter.
;
;                            A
;                          +----+
;                         B|    |G
;                      B   |    |   G
;                     +----+----+----+
;                     |    |    |    |
;                    C|    |    |    |E
;                     +----+----+----+
;                      D   |    |   F
;                         D|    |F
;                          +----+
;                          |    |
;                         C|    |E
;                          +----+
;                            A
;
;   HINT 1: When printing, be sure that the XSIZE and YSIZE are given
;           in the ratio of 3 to 4.  A size of 6 in by 8 in is
;           suitable.
;
;   HINT 2: As a practical matter for assembling the cube once it has
;           been printed, you should leave some extra paper tabs so
;           that adhesive can be applied.
;
; INPUTS:
;
;   X, Y, Z - Three arrays which specify position in three dimensional
;             space.  All three arrays should be of the same length.
;
; OPTIONAL INPUTS:
;   NONE
;
; INPUT KEYWORD PARAMETERS:
;
;   PANEL, SUBPANEL - An alternate way to more precisely specify the
;                     plot and annotation positions.  See SUBCELL.
;                     Default is full-screen.
;
;   XRANGE, YRANGE, ZRANGE - gives plot range for each dimension, as
;                            for other plot commands.  Default is
;                            range of data.
;
;   XTITLE, YTITLE, ZTITLE - gives title for each axis.  The title
;                            labels each face of the cube where
;                            possible.
;
;   NOERASE - If set, the display is not erased before graphics
;             operations.
;
;   Other options are passed along to the PLOT command directly.
;
; OUTPUTS:
;   NONE
;
; PROCEDURE:
;
; EXAMPLE:
;
;   This example takes some synthetic data and makes a cube out of it.
;   Visualizing the trace of the curve is more convenient when it can
;   be projected on the cube in each dimension.
;
;   t = findgen(200)/20. - 10.
;   x = cos(t)
;   y = sin(t) + 0.05*t
;   z = exp(t) + 0.05*randomn(seed, 200)
;   plotcube, x, y, z, xrange=[-1.5,1.5], yrange=[-1.5,1.5], zrange=[-1.5,1.5]
;
; SEE ALSO:
;
;   DEFSUBCELL, SUBCELLARRAY
;
; EXTERNAL SUBROUTINES:
;
;   SUBCELL, DEFSUBCELL, PLOTPAN
;
; MODIFICATION HISTORY:
;   Written, CM, 1997
;   Modified to include SUBCELL, DEFSUBCELL and PLOTPAN when
;     distributed, CM, late 1999
;
;  $Id: plotcube.pro,v 1.1.1.1 2003/06/12 21:43:40 johnjohn Exp $
;
;-
; Copyright (C) 1997-2000, Craig Markwardt
; This software is provided as is without any warranty whatsoever.
; Permission to use, copy, modify, and distribute modified or
; unmodified copies is granted, provided this copyright and disclaimer
; are included unchanged.
;-
;%insert HERE
function subcell, subpos, position, margin=margin
  if n_elements(subpos) EQ 0 then mysubpos = [-1.,-1,-1,-1] $
  else mysubpos = subpos
  if n_elements(position) EQ 0 then position = [0.,0.,1.,1.]
  if keyword_set(margin) EQ 1 OR n_elements(subpos) EQ 0 then $
    mysubpos = defsubcell(mysubpos)
  x0 = position(0)
  y0 = position(1)
  dx = position(2)-position(0)
  dy = position(3)-position(1)
  newsubpos = reform(mysubpos * 0, 4)
  newsubpos([0,2]) = x0 + dx * mysubpos([0,2])
  newsubpos([1,3]) = y0 + dy * mysubpos([1,3])
  return, newsubpos
end
function defsubcell, default
  if n_elements(default) EQ 0 then default = [-1.,-1,-1,-1]
  mysubcell = default
  defaultsubpos = [ 0.08, 0.08, 0.95, 0.95 ]
  iwh = where(mysubcell LT 0, ict)
  if ict GT 0 then $
    mysubcell(iwh) = defaultsubpos(iwh)
  return, mysubcell
end
pro plotpan, x, y, $
             subpanel=subpanel, panel=panel, $
             _EXTRA=extra
  if n_elements(panel) EQ 0 AND n_elements(subpanel) EQ 0 then begin
      plot, x, y, _EXTRA=extra
  endif else begin
      if n_elements(panel) EQ 0 then panel=[0.0,0.0,1.0,1.0]
      plot, x, y, /normal, position=subcell(subpanel, panel, /marg), $
        _EXTRA=extra
  endelse
  return
end
pro plotcube, x, y, z, $
              xrange=xrange, yrange=yrange, zrange=zrange, $
              xtitle=xtitle, ytitle=ytitle, ztitle=ztitle, $
              panel=panel, subpanel=subpanel, $
              noerase=noerase, $
              _EXTRA=extra

  ;; Default is full-panel
  if n_elements(panel) EQ 0 then panel=[0.0,0.0,1.0,1.0]
  if n_elements(subpanel) EQ 0 then subpanel=[-1.,-1,-1,-1]
  if n_elements(noerase) EQ 0 then noerase=0

  if n_elements(xrange) EQ 0 then xrange = [ min(x), max(x) ]
  if n_elements(yrange) EQ 0 then yrange = [ min(y), max(y) ]
  if n_elements(zrange) EQ 0 then zrange = [ min(z), max(z) ]

  if n_elements(xtitle) EQ 0 then xtitle = 'X'
  if n_elements(ytitle) EQ 0 then ytitle = 'Y'
  if n_elements(ztitle) EQ 0 then ztitle = 'Z'

  subcellarray, [1,1,1], [1,1,1,1], newpan, newsub, $
    panel=panel, subpanel=subpanel

  plotpan, x, z, /xstyle, /ystyle, noerase=noerase, $
    xtickformat='(A1)', ytitle=ztitle, $
    xrange=xrange, yrange=zrange, $
    panel=newpan(1,3,*), subpanel=newsub(1,3,*), _EXTRA=extra

  plotpan, z, y, /xstyle, /ystyle, /noerase, $
    xtitle=ztitle, ytitle=ytitle, $
    xrange=[zrange(1),zrange(0)], yrange=yrange, $
    panel=newpan(0,2,*), subpanel=newsub(0,2,*), _EXTRA=extra

  plotpan, x, y, /xstyle, /ystyle, /noerase, $
    xtickformat='(A1)', ytickformat='(A1)', $
    xrange=xrange, yrange=yrange, $
    panel=newpan(1,2,*), subpanel=newsub(1,2,*), _EXTRA=extra

  plotpan, z, y, /xstyle, /ystyle, /noerase, $
    ytickformat='(A1)', xtitle=ztitle, $
    xrange=zrange, yrange=yrange, $
    panel=newpan(2,2,*), subpanel=newsub(2,2,*), _EXTRA=extra

  plotpan, x, z, /xstyle, /ystyle, /noerase, $
    xtickformat='(A1)', ytitle=ztitle, $
    xrange=xrange, yrange=[zrange(1),zrange(0)], $
    panel=newpan(1,1,*), subpanel=newsub(1,1,*), _EXTRA=extra

  plotpan, x, y, /xstyle, /ystyle, /noerase, $
    xtitle=xtitle, ytitle=ytitle, $
    xrange=xrange, yrange=[yrange(1), yrange(0)], $
    panel=newpan(1,0,*), subpanel=newsub(1,0,*), _EXTRA=extra

  return
end

    
