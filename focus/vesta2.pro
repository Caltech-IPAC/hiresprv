pro vesta
;plot position of Vesta

t = [-10.,0.,10.,20.]
ra = [50.17,58.95,5.79+60.,10.38+60] - 60.
dec = [0.2,15.2,16.3,3.1]

title='!6 VESTA:  RA vs Time'
xt='!6 Time - Aug 1 at 0h UT'
yt = '!6 (RA - 1hr) in minutes (2000)'

plot,t,ra,ps=-8,title=title,xtit=xt,ytit=yt,symsize=2,xr=[-12,20],/xsty
cof=poly_fit(t,ra,2)
predra = poly([5.5,6.5],cof)  ;noon at Greenwich both nights at 2am
xyouts,-6,11,'!6 RA at 2am:'
xyouts,-6,9,'2hr '+string(predra(0))+' min'
xyouts,-6,7,'2hr '+string(predra(1))+' min'

;title='!6 VESTA:  DEC vs Time'
;xt='!6 Time - Aug 1 at 0h UT'
;yt = '!6 (DEC - +03 deg) in arc minutes (2000)'

;plot,t,dec,ps=-8,title=title,xtit=xt,ytit=yt,symsize=2,xr=[-12,20],/xsty
;cof=poly_fit(t,dec,2)
;preddec = poly([5.5,6.5],cof)  ;noon at Greenwich both nights at 2am
;xyouts,-1,11,'!6 DEC at 2am:'
;xyouts,-1,9,'+03 deg '+string(preddec(0))+' min'
;xyouts,-1,7,'+03 deg '+string(preddec(1))+' min'

end
