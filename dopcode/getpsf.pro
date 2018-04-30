pro getpsf, psfpix, psfsig, fz $
            , accordion=accordion $
            , b1=b1 $
            , d5=d5 $
            , float0=float0 $
            , idepth=idepth $
			, keck2=keck2 $
            , lowsn=lowsn $
            , medium=medium $
            , narrow=narrow $
            , new=new $
            , prekeck=prekeck $
            , scattered=scattered $
            , simple=simple $
            , test=test $
            , width_simple=wids $
            , widscale=widscale 

case 1 of
    keyword_set(d5): begin
        psfpix = [0.0, 0.2, 0.2]
        psfsig = [0.85, 0.5, 0.5]
;        psfpix = $
;			[0.00,-1.0, 1.0,-1.4,1.4,-2.0,2.0,-3.0,3.0,-4.5,4.5,-5.7,5.7]*0.9
;        psfsig = $
;			[0.95, 0.4, 0.4, 0.6,0.6, 0.7,0.7, 1.0,1.0, 1.2,1.2, 1.8,1.8]*0.9
    end
    keyword_set(simple): begin
;        fz = [0,indgen(8)+2, 14,15,16,17,18,19]
;        psfpix = [0., -2.7, 2.7]
;        psfsig = [1.5, 1.5, 1.5]
        fz = [indgen(10)+1, indgen(6)+14]
        psfpix = [0.]
        if 1-keyword_set(wids) then wids = 1.5
        psfsig = [wids]
    end
    keyword_set(prekeck) : begin
        fz=[0,19]
        psfpix=[0.00,-4.40,-3.80,-3.20,-2.60,-2.00,-1.40,-0.80, 0.80, 1.40, 2.00, 2.60, 3.20, 3.80, 4.40]
        psfsig=[0.85, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50]
    end
    keyword_set(keck2) : begin
        case 1 of
            keyword_set(narrow): begin
                psfpix = [0.00,-0.9, 0.9, -1.2, 1.2, 2.4, -2.4, 3.2, -3.2,4.8 $
                          , -4.8, 5.6, -5.6, 6.5, -6.5]
                psfsig = [0.80, 0.4, 0.4,  0.5, 0.5, 0.7,  0.7, 0.8,  0.8,.35 $
                          ,  .35, 0.9, 0.9,  .35,  .35]
                fz = [0, 14, 19]
            end
            keyword_set(lowsn): begin
                psfpix=[0.00,-6.00,-4.80,-3.70,-2.70,-1.80,-1.20,-0.90,0.90,1.20,1.80,2.70,3.70,4.80,6.00]
                psfsig=[1.00,0.00,1.00,0.80,0.65,0.50,0.40,0.30,0.30,0.40,0.50,0.65, 0.80,1.00, 0.00]
                fz=[0,1,2,3,4,14,15,16,18,19]
            end
            keyword_set(medium): begin
                psfpix=[0.00,-6.00,-4.80,-3.70,-2.70,-1.80,-1.20,-0.90,0.90,1.20,1.80,2.70,3.70,4.80,6.00]*0.8
                psfsig=[1.00,0.00,1.00,0.80,0.65,0.50,0.40,0.30,0.30,0.40,0.50,0.65, 0.80,1.00, 0.00]*0.8
                fz=[0,1,14,18,19]
;                psfpix = [0.00, -1.0, 1.0]
;                psfsig = [0.90,  1.0, 1.0]
            end
            keyword_set(b1) : begin
                psfpix = [0.00,-1.0, 1.0,-1.4,1.4,-2.0,2.0,-3.0,3.0,-4.5,4.5,-5.7,5.7]
                psfsig = [0.95, 0.4, 0.4, 0.6,0.6, 0.7,0.7, 1.0,1.0, 1.2,1.2, 1.8,1.8]
            end
            else : begin  ; This is the B5/C2 decker
                psfpix=[0.00,-6.00,-4.80,-3.70,-2.70,-1.80,-1.20,-0.90,0.90,1.20,1.80,2.70,3.70,4.80,6.00]
                psfsig=[1.00,0.00,1.00,0.80,0.65,0.50,0.40,0.30,0.30,0.40,0.50,0.65, 0.80,1.00, 0.00]
                if keyword_set(scattered) then fz=[0,1,18,19] else fz=[0,1,14,18,19]
            end
        endcase
    end
    else : begin ;;; Default is pre-keck
        fz=[0,14,19]
        psfpix=[0.00,-4.40,-3.80,-3.20,-2.60,-2.00,-1.40,-0.80, 0.80, 1.40, 2.00, 2.60, 3.20, 3.80, 4.40]
        psfsig=[0.85, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50, 0.50]
    end
endcase
if n_elements(fz) eq 0 then begin
    nel = n_elements(psfsig)
    if nel lt 11 then fz=[0,indgen(10-nel+1)+nel,14,15,16,17,18,19] else $
      if nel eq 20 then fz = [0, 14] else fz=[0, 14, indgen(16-nel)+nel+4]
endif
    if keyword_set(idepth) or keyword_set(accordion) then begin
        q = where(fz ne 19)
        fz = fz[q]
    endif
if keyword_set(float0) then fz = fz[1:*]
end
