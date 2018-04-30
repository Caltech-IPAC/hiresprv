function stitch_cont, dsst, stitch, meanx=meanx, meancont=meancont, xcont=xcont,osamp=osamp
if 1-keyword_set(osamp) then osamp = 4.
xcont = findgen(n_elements(dsst[0].dst))/osamp+stitch[0].x0
cont = poly(xcont, stitch[0].coef)
meanx = mean(xcont)
meancont = poly(meanx, stitch[0].coef)
return, cont
end
