pro remove_sky, im, orc, xwd,tot_sky,head

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
;UPDATE:   Increased xwd limit from 12 pixels to 14 pixels, HTI apr2010

if xwd gt 14 then begin ;increased from 12 to 14 HTI apr2010
	print, '%REMOVE_SKY: EXTRACTION WIDTH GREATER THAN 12 PIXELS'
	print, '%REMOVE_SKY: RETURNING WITHOUT REMOVING SKY'
;stop
	print,'HTI TEST: Always remove sky'
    ;NOTE: GETXWD NOW RESTRICTS XWD TO 14 PIXELS FOR C2/B3 OBS.
;return
endif else begin ; xwd gt 14
	print,'% REMOVE_SKY: Removing Sky. (C2 or B3 decker only)'
endelse

;use orc for identification of center of order
;   sky_len is the number of pixels from center of order to edge of useful
;	sky region. Pixels with sky from two overlapping orders are excluded.

sky_len = [12,13,14,15,16,17,18,19,19,19,19,19,19,19,19,19]
nord  = n_elements(orc[0,*])

;Useful quantities:
sz = size(im)                   ;variable info block
ncol = sz[1]                    ;# columns in image
nrow = sz[2]                    ;# columns in image
tot_sky = im*0.					;arravy of sky values for entire spectrum

test_sky0 = fltarr(ncol,nord)	;test array ;HTI 8/2012
test_sky3 = fltarr(ncol,nord)	;test array ;HTI 8/2012
test_sky4 = fltarr(ncol,nord)	;test array ;HTI 8/2012
test_sky5 = fltarr(ncol,nord)	;test array ;HTI 8/2012
starname = sxpar(head,'targname')
!p.multi=[0,1,3]


for col = 0, ncol -1 do begin ;4000 columns
   for i=0, nord-1 do begin ;loop through every order
	
	mid = poly(col, orc[*,i]) ;orig
;	mid = poly(col, orc[*,i]) +2;test
	low = mid - sky_len[i]   ; i for order 
	high = mid + sky_len[i] 
;	if (low lt 25 or high gt 710) and col eq 4020 then stop
	if low lt 25 then low = 25
	if high gt  710 then high = 710  ;; avoid edge of ccd(pix# 711,712)
 	npix = fix (high -low ) +1
 	

;	Define sky regions above and below order
	sec1 = im[col, low: low + ( sky_len[i] -xwd/2.)]
	sec2 = im[col, high-sky_len[i]+xwd/2.  :high ]
	test_val3 = im[col, low: low+5]	 ;HTI 8/2012
	test_val4 =	im[col, high-5: high] ;HTI 8/2012
	test_val5 =	[test_val3,test_val4] ;HTI 8/2012
		
	if n_elements(sec2) lt 5 then sky_val = median(sec1) $; DEFINE SKY VALUE
		else sky_val =  mean( [median(sec1), median(sec2)] );negative values ok.
	if n_elements(sec2) lt 5 or n_elements(sec1) lt 5 then stop	

see_plot = 'n' ;set to 'y' to see plots
if see_plot eq 'y' and col gt 500 then begin
	!p.multi=[0,2,1]
	plot,im[col,fix(low)-20:fix(high)+20], /ysty,ps=10 $;,yr = [-10, 200] $
		,xtit = 'Pixel', ytit ='Dn' $
		,Title = 'Prior to Sky removal for order'+string(i)
	oplot,[20,20],[0,1e5], co = 50 ;lower sky bound
	oplot,[20+sky_len[i]*2, 20+sky_len[i]*2], [-10,1e5],co = 80 ;upper sky bound
	oplot,[20+sky_len[i]+xwd/2.,20+sky_len[i]+xwd/2.], [-10,1e5], co=250
	;lower xwd(above), upper xwd (below)
	oplot,[20+sky_len[i]-xwd/2+1.,20+sky_len[i]-xwd/2+1.], [-10,1e5],co=250 
	oplot,indgen(high-low+40) , intarr(high-low+40) + sky_val, co = 150;sky 
	oplot,intarr(100),linestyle=2
;	wait,0.15
;	if i mod 40 eq 0 then stop
endif; see_plot


; Perform sky Removal  -----------------MOST CRITICAL LINE-----------------
	im[col,low:high] = im[col,low:high]-sky_val
; Perform sky Removal  -----------------MOST CRITICAL LINE-----------------

;	if nord eq 8 and col mod 400 eq 0 then stop
	if col eq 500 and i eq 0 and see_plot eq 'y' then begin
	
		display,im[200:800,100:600],/log,min=0, title='Check sky subtraction'
		stop
	endif
;HTI 8/2012: save value of sky subtracted, as well as 


;plot again to see the change
 if see_plot eq 'y' and col gt 500 then begin

	plot,im[col,fix(low)-20:fix(high)+20], yr = [-10, 200],/ysty,ps=10,$
		xtit = 'Pixel', ytit ='Dn', $
		Title = 'After Sky removal for order'+string(i)

	oplot,[20,20],[0,1e5], co = 50 ;lower sky bound
	oplot,[20+sky_len[i]*2, 20+sky_len[i]*2] , [0,1e5],co = 80  ;upper sky bound
	oplot,[20+sky_len[i]+xwd/2.,20+sky_len[i]+xwd/2.], [-10,1e5], co=250
	;lower xwd(above), upper xwd (below)
	oplot,[20+sky_len[i]-xwd/2+1.,20+sky_len[i]-xwd/2+1.], [-10,1e5],co=250 
	
	oplot,indgen(high-low+40) , intarr(high-low+40) + sky_val, co = 150; sky
	oplot,intarr(100),linestyle=2
;stop
wait,1
;stop;	wait,0.15

	if nord eq 8 and i mod 400 eq 0 then stop

 endif; see_plot

;	Define sky values:
	tot_sky[col,low:high] = sky_val

	test_val5_sorted = test_val5[sort(test_val5)] ;Nominal sky value;HTI 8/2012  
	test_sky0[col,i]  = sky_val				;HTI 8/2012  
	test_sky3[col,i]  = test_val5_sorted[2] ;HTI 8/2012  
	test_sky4[col,i]  = test_val5_sorted[3] ;HTI 8/2012  
	test_sky5[col,i]  = test_val5_sorted[4] ;HTI 8/2012  
		
endfor ; i loop   

;stop ;here to look at each order
endfor ; col loop


;HTI 8/2012   begin
HTI_test = 'n'
if HTI_test eq 'y' then begin 

	zero= where(test_sky0 eq 0,nzero)
	if nzero gt 0 then test_sky0[zero] = 0.001
	diff3 =  (test_sky3 - test_sky0)/test_sky0 
	diff4 =  (test_sky4 - test_sky0 )/test_sky0
	diff5 =  (test_sky5 - test_sky0 )/test_sky0
	n_sky_pix = n_elements(sec1[0,*])+n_elements(sec2[0,*])

	plothist,diff3,bin=.02,xr=[-2,2],title='3rd lowest pixel - nominal: median: '+str(median(diff3))+' Star= '+starname,xtit='Pixels used in sky determination: 	'+ str(n_sky_pix)+ ' : Median sky value of this exp: '+str(median(tot_sky))
	plothist,diff4,bin=.02,xr=[-2,2],title='4th lowest pixel - nominal: median: '+str(median(diff4))
	plothist,diff5,bin=.02,xr=[-2,2],title='5th lowest pixel - nominal: median: '+str(median(diff5))

stop
;wait,10
;HTI 8/2012 END
endif
;save,tot_sky,file='sky1'
;stop
;wait,5;stop
end ; program
