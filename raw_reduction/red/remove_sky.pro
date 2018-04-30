pro remove_sky, im, orc, xwd

;PURPOSE:  When C2 or B3 (14" tall) deckers are used, then perform
;			sky subtraction to remove sky/moon contamination.
;			This program is tailored to the middle chip.
;
;INPUTS: 	raw image from single chip (im)
;			order locations: (orc)
;			extraction width: (xwd)
;
;OUTPUTS: 	im with sky removed.
;
;CREATED:   1 Dec 2009 HTI, especially need for V > 11 (Kepler stars)

; If extraction width is greater than 12 pixels, then return without
;  doing sky subtraction

;if xwd gt 12 then begin ; middle chip
if xwd gt 20 then begin
	print, '% REMOVE_SKY: EXTRACTION WIDTH GREATER THAN 12 PIXELS'
	print, '% REMOVE_SKY: RETURNING WITHOUT REMOVING SKY'
return
endif else begin ; xwd gt 12
	print,'% REMOVE_SKY: Removing Sky. (C2 or B3 decker only)'
endelse

;Useful quantities:
sz = size(im)                   ;variable info block
ncol = sz[1]                    ;# columns in image
nrow = sz[2]                    ;# columns in image
tot_sky = im*0.					;map of the sky values

;use orc for identification of center of order
;   sky_len is the number of pixels from center of order to edge of useful
;	sky region. Pixels with sky from two overlapping orders are excluded.

;sky_len = [12,13,14,15,16,17,18,19,19,19,19,19,19,19,19,19] ; middle chip
sky_len = intarr(10)+19 ; red chip
nord  = n_elements(orc[0,*])

for col = 0, ncol -1 do begin ;4000 columns
   for i=0, nord-1 do begin ;loop through every order

	mid = poly(col, orc[*,i])
	low = mid - sky_len[i]   ; i for order 
	high = mid + sky_len[i] 
	if high gt  710 then high = 710 ; exclude 711, and 712
 	npix = fix (high -low ) +1 

;	Define sky regions above and below order
	sec1 = im[col, low: low + ( sky_len[i] -xwd/2.)]
	sec2 = im[col, high-sky_len[i]+xwd/2.  :high ]
	sky_val =  mean( [median(sec1), median(sec2)] ); sky value to be subtracted 
													;negative values ok.
skip_plot = 'n' ;set to 'n' to see plots
if skip_plot eq 'y' then begin
	!p.multi=[0,2,1]
	plot,im[col,fix(low)-20:fix(high)+20], yr = [-10, 200],/ysty,ps=10,$
		xtit = 'Pixel', ytit ='Dn', $
		Title = 'Prior to Sky removal for order'+string(i)
	oplot,[20,20],[0,1e5], co = 50 ;lower sky bound
	oplot,[20+sky_len[i]*2, 20+sky_len[i]*2], [-10,1e5],co = 80 ;upper sky bound
	oplot,[20+sky_len[i]+xwd/2.,20+sky_len[i]+xwd/2.], [-10,1e5], co=250
	;lower xwd(above), upper xwd (below)
	oplot,[20+sky_len[i]-xwd/2+1.,20+sky_len[i]-xwd/2+1.], [-10,1e5],co=250 
	oplot,indgen(high-low+40) , intarr(high-low+40) + sky_val, co = 150;sky 
	stop
endif; skip_plot


; Perform sky Removal
	im[col,low:high] = im[col,low:high]-sky_val

;plot again to see the change
 if skip_plot eq 'y' then begin

	plot,im[col,fix(low)-20:fix(high)+20], yr = [-10, 200],/ysty,ps=10,$
		xtit = 'Pixel', ytit ='Dn', $
		Title = 'After Sky removal for order'+string(i)

	oplot,[20,20],[0,1e5], co = 50 ;lower sky bound
	oplot,[20+sky_len[i]*2, 20+sky_len[i]*2] , [0,1e5],co = 80  ;upper sky bound
	oplot,[20+sky_len[i]+xwd/2.,20+sky_len[i]+xwd/2.], [-10,1e5], co=250
	;lower xwd(above), upper xwd (below)
	oplot,[20+sky_len[i]-xwd/2+1.,20+sky_len[i]-xwd/2+1.], [-10,1e5],co=250 
	
	oplot,indgen(high-low+40) , intarr(high-low+40) + sky_val, co = 150; sky
    wait,0.15;stop
 stop
 endif; skip_plot

;	Define sky values:
	tot_sky[col,low:high] = sky_val


;	endif ; excludes nord=9 for pix gt 3500 (edge of chip problems)
endfor ; i loop   

;stop ;here to look at each order
endfor ; col loop


end ; program