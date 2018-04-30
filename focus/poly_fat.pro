function poly_fat,x_cord,coeffs
;poly_inter seems fucked! coeffs are polynomial coefficients from
;poly_fit. xcord are the input x-coordinates. y_cord are the
;output y-coordinates.  P. Butler 7/89
n_e=n_elements(x_cord)
order=n_elements(coeffs)-1
y_cord=dblarr(n_e)
y_cord=y_cord+coeffs(0)
for n=1,order do y_cord=y_cord+((double(x_cord))^n)*coeffs(n)
return,y_cord
end;of program
