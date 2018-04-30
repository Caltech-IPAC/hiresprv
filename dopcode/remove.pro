pro remove,index, vector1, vector2, vector3, vector4, vector5, vector6, vector7
;+
; NAME:
;    REMOVE
; PURPOSE:
;    Contract a vector or up to 7 vectors by removing specified
;    elements.   
; CALLING SEQUENCE:
;    REMOVE, index, vector1,[ vector2, vector3, vector4, vector5,vector6, 
;                            vector7]     
; INPUTS:
;    INDEX - scalar or vector giving the index number of elements to
;           be removed from vectors.  Duplicate entries in index are
;           ignored.    An error will occur if one attempts to remove
;           all the elements of a vector.
;
; INPUT-OUTPUT:
;    VECTOR1 - Vector or array.  Elements specifed by INDEX will be 
;            removed from VECTOR1.  Upon return VECTOR1 will contain
;            N fewer elements, where N is the number of values in
;            INDEX.
;
; OPTIONAL INPUT-OUTPUTS:
;     VECTOR2,VECTOR3,...VECTOR7 - additional vectors containing
;            the same number of elements as VECTOR1.  These will be
;            contracted in the same manner as VECTOR1.
;
; EXAMPLES:
;   (1) If INDEX = [2,4,6,4] and V = [1,3,4,3,2,5,7,3] then after the call
;
;            IDL> remove,index,v      
;
;        V will contain the values [1,3,3,5,3]
;
;   (2) Suppose one has a wavelength vector W, and three associated flux
;       vectors F1, F2, and F3.    Remove all points where a quality vector,
;       EPS is negative
;
;            IDL> bad = where( EPS LT 0, Nbad)
;            IDL> if Nbad GT 0 then remove, bad, w, f1, f2, f3
; METHOD:
;    If only 1 element is to be removed, then the vectors are shortend by
;    simple subscripting.    If more than 1 elements is to be removed,
;    then a "keep" vector of indicies to save is formed, and applied to
;    the input vectors
; REVISION HISTORY:
;    Written W. Landsman        ST Systems Co.       April 28, 1988
;    Cleaned up code          W. Landsman            September, 1992
;-
 On_error,2

 npar = N_params()
 if npar LT 2 then begin
      print,'Syntax - remove, index, v1, [v2, v3, v4, v5, v6, v7]
      return
 endif

 npts = N_elements(vector1)

 max_index = max(index, MIN = min_index)

 if ( min_index LT 0 ) or (max_index GT npts-1) then message, $
             'ERROR - Index vector is out of range'

 if ( max_index Eq min_index ) then begin    ;Remove only 1 element?

         if min_index EQ 0 then vector1 = vector1(1:*) else $
         if min_index EQ npts-1 then vector1 = vector1(0:npts-2) else $
                 vector1 = [vector1(0:min_index-1), vector1(min_index+1:*) ]

     if Npar GE 3 then begin
         if min_index EQ 0 then vector2 = vector2(1:*) else $
         if min_index EQ npts-1 then vector2 = vector2(0:npts-2) else $
                 vector2 = [vector2(0:min_index-1), vector2(min_index+1:*) ]
     endif

     if Npar GE 4 then begin
         if min_index EQ 0 then vector3 = vector3(1:*) else $
         if min_index EQ npts-1 then vector3 = vector3(0:npts-2) else $
                 vector3 = [vector3(0:min_index-1), vector3(min_index+1:*) ]
     endif

     if Npar GE 5 then begin
         if min_index EQ 0 then vector4 = vector4(1:*) else $
         if min_index EQ npts-1 then vector4 = vector4(0:npts-2) else $
                 vector4 = [vector4(0:min_index-1), vector4(min_index+1:*) ]
     endif

     if Npar GE 6 then begin
         if min_index EQ 0 then vector5 = vector5(1:*) else $
         if min_index EQ npts-1 then vector5 = vector5(0:npts-2) else $
                 vector5 = [vector5(0:min_index-1), vector5(min_index+1:*) ]
     endif

     if Npar GE 7 then begin
         if min_index EQ 0 then vector6 = vector6(1:*) else $
         if min_index EQ npts-1 then vector6 = vector6(0:npts-2) else $
                 vector6 = [vector6(0:min_index-1), vector6(min_index+1:*) ]
     endif

     if Npar Eq 8 then begin
         if min_index EQ 0 then vector7 = vector7(1:*) else $
         if min_index EQ npts-1 then vector7 = vector7(0:npts-2) else $
                 vector7 = [vector7(0:min_index-1), vector7(min_index+1:*) ]
     endif

     return
endif

;  Begin case where more than 1 element is to be removed.   Use HISTOGRAM
;  to determine then indicies to keep

 nhist = max_index +1 

 hist = histogram( index, MIN = 0 )      ;Find unique index values to remove
 keep = where( hist EQ 0, Ngood )
 ndelete = nhist-ngood
 if ngood EQ 0 then begin 

    if ( npts LE nhist ) then message, $
          'ERROR - Cannot delete all elements from a vector
    keep = nhist + lindgen(npts-nhist) 
    
 endif else begin 

    if ( Ngood LT (npts - ndelete)) then $
          keep = [ keep, nhist + lindgen(npts-nhist) ] 

 endelse

 vector1 = vector1(keep)                      ; this is the big core robber!!

 case npar of 

   3: vector2 = vector2(keep)

   4: begin
     vector2 = vector2(keep)
     vector3 = vector3(keep)
     end

   5: begin
     vector2 = vector2(keep)
     vector3 = vector3(keep)
     vector4 = vector4(keep)
     end

   6: begin
     vector2 = vector2(keep)
     vector3 = vector3(keep)
     vector4 = vector4(keep)
     vector5 = vector5(keep)
     end

   7: begin
     vector2 = vector2(keep)
     vector3 = vector3(keep)
     vector4 = vector4(keep)
     vector5 = vector5(keep)
     vector6 = vector6(keep)
     end

   8: begin
     vector2 = vector2(keep)
     vector3 = vector3(keep)
     vector4 = vector4(keep)
     vector5 = vector5(keep)
     vector6 = vector6(keep)
     vector7 = vector7(keep)
     end
  else: ;null statement

 endcase

 return
 end
