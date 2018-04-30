pro quick_reduce,raw_in

;+
; Purpose: Allow for raw reduction of a single spectrum without reducing an 
;			entire night. Use a saved wideflat, and a saved set of order
;			 defining polynomials.
;
;		Wideflats taken from run:
;		Order finder from: j211.296 
;
; Author: H. Isaacson
;
; Date: September 2015
;-

; start with run j211 and build from there.
; WF file j211-2
restore,'quick_reduce_totwf.dat' ; in /mir3/reduce/
restore,'quick_reduce_orc_in.dat' ; in /mir3/reduce/ ; opens as orc_in
dir = '/mir3/raw/'
;raw = 'j2110296.fits'
ham_id=29 ; for quick reduce.

; Originial purpose: check one file:
if keyword_set(raw_in) then begin
; original quick reduce call
;raw_in='j1310091.fits'
;raw_in='j1940524.fits'
outfname='temp_iod'

; TRY shifting the orders and see what happens
;orc_in[0,*] = orc_in[0,*]-3
hirspec, 'temp',dir+raw_in, outfname, orc_in,totwf,/cosmics,xwd_out=xwd_out
stop


endif



if 1 then begin ; test for koi-165
; re-reduce all of the koi=265 obs and check to see if the xwd correlates with
;	RV or RV error
starname='k00265'
starname='k00041'
starname='k00072'
starname='9407'
starname='10700
restore,'/mir3/vel/vst'+starname+'.dat'
; Filter out B5 obs from 2009 ; keep JD > 15300
keep =where(cf3.jd gt 15300,nkeep)
keep = keep[nkeep-21:nkeep-1]
cf3 = cf3[keep]

nobs = n_elements(cf3)
xwds = fltarr(nobs)
run =  strarr(nobs)
raw_obs = strarr(nobs)
for j=0,nobs-1 do begin
	if fix(strmid(cf3[j].obnm,2,3)) le 99 then $
		 run[j] = strmid(cf3[j].obnm,1,3) $
	else run[j] = strmid(cf3[j].obnm,1,4) ;pos1 = str ; only works for post j100 obs
	pos1 = strpos(cf3[j].obnm ,'.' )
	onum = strmid(cf3[j].obnm,pos1+1,4)
;	for i=0,n_elements(cf3)-1 do $
		if fix(onum) lt 10 then onum = '0'+onum

;	for i=0,n_elements(cf3)-1 do $
		if fix(onum) lt 100 then onum = '0'+onum

;	for i=0,n_elements(cf3)-1 do $
		if fix(onum) lt 1000 then onum= '0'+onum

	raw_obs[j] = run[j]+onum+'.fits'
endfor ; j=0

;forprint,raw_obs, cf3.obnm
;stop




for i = 0, nobs -1 do begin	
	raw = raw_obs[i]

	outfname='temp_iod'
	

	hirspec, 'temp',dir+raw, outfname, orc_in,totwf,/cosmics,xwd_out=xwd_out
;hirspec,prefix,spfname,outfname, orc_in, totwf,thar=thar,nosky=nosky, cosmics = cosmics, quick = quick

	xwds[i] = xwd_out
	
	
	
endfor


; plot rv and errvel correlation with xwd
!p.multi=0
window,0
plot, xwds, cf3.errvel,ps=7 $
	, xra=[4,15] $
	, xtitl= 'Extraction Width', ytitle='RV Error '$
	, Title= 'RV errrors as a function of Exd Width'
;	stop
window,1
plot,xwds,cf3.mnvel,ps=7 $
	, xra=[4,15] $
	, xtitl= 'Extraction Width', ytitle=' RV '$
	, title = 'RVs as a function of Extraction width'
stop
;window,2
;plot,xwds,rv_rms_bin,ps=8
;window,3
;plot,xwds,err_med_bin,ps=8
;stop

nbin = 9 ; 6-14
rv_rms_bin = fltarr(nbin)
err_med_bin = fltarr(nbin)
for j=6,12 do begin
	ind = where(xwds eq j,nind)
	if nind gt 3 then begin
		print,'xwd=',str(j),' RMS of RVs:',stddev(cf3[ind].mnvel)
		print,'xwd=',str(j),' Med of RV_err:',median(cf3[ind].errvel)		
		rv_rms_bin[j-6] = stddev(cf3[ind].mnvel)	
		err_med_bin[j-6] = median(cf3[ind].errvel)
;		wset,0
;		plots,j,median(cf3[ind].errvel),ps=8,color=!blue,symsize=3
;		wset,1
;		plots,j,median(cf3[ind].mnvel),ps=8,color=!red,symsize=3	
;stop
	endif
endfor

;	ind = where(xwds eq 7)
;	print,'xwd=7 ',stddev(cf3[ind].mnvel)	
;	ind = where(xwds eq 8)
;	print,'xwd=8 ',stddev(cf3[ind].mnvel);
;	ind = where(xwds eq 9)
;	print,'xwd=9 ',stddev(cf3[ind].mnvel)

	

endif


stop
stop


;STDDEV of  RVs: for koi-265
;xwd=6        5.5653979
;xwd=7        4.3275171
;xwd=8        3.8642738





end