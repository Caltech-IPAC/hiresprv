function biastrim, spfname

;rdfits,im,spfname,head           		;read spectrum fits file
;hiraw,im,spfname,chip=2
;hiraw,im,spfname,chip=3
hiraw,im,spfname,chip=1
im = double(im)

;
;BIAS SUBTRACTION
biaslev = median(im[*,5:10])  ;bias hires mosaic
    nr = n_elements(im[0,*])  ;# rows
    for j=0,nr-1 do begin     ;Subtract Bias, row by row
;      biaslev = median(im[21+2047+11:21+2047+11+20,j]) ;bias from 2079:2073+25
      im[*,j] = im[*,j] - biaslev
    end
    im=nonlinear(im)
;im = im[21:2047+21,*]
return, im
end
