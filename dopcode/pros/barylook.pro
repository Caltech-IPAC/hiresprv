pro barylook, numin $
			  , tel=tel $
			  , template=template $
			  , noprint=noprint $
              , lines=lines $
              , grep=grep $
              , nlines=nlines $
              , obsonly=obsonly $
              , other=other $
              , keck2=keck2 

if keyword_set(other) then num = "'"+numin+" '" else num = "' "+numin+" '"
num = strupcase(num)
if 1-keyword_set(tel) then tel = 'keck'
if keyword_set(keck2) and 1-keyword_set(grep) then grep = 'rj'

baryfile = getenv("DOP_BARYFILE")

case 1 of
    keyword_set(template): begin
        if keyword_set(grep) then begin
            spawn,'grep -i '+str(num)+' '+baryfile+ " | grep '[0-9]* t' | grep '"+str(grep)+"'",lines
        endif else begin
            spawn,'grep -i '+str(num)+' '+baryfile+ ' | grep "[0-9] t"',lines 
        endelse
    end
    keyword_set(obsonly): begin
        if keyword_set(grep) then begin
            spawn,'grep -i '+str(num)+' '+baryfile+ " | grep '[0-9] o' | grep '"+str(grep)+"'",lines 
        endif else begin
            spawn,'grep -i '+str(num)+' '+baryfile+ ' | grep "[0-9] o"', lines 
        endelse
    end
    else: begin
        if keyword_set(grep) then begin
            spawn,'grep -i '+string(num)+' '+baryfile+" | grep '"+str(grep)+"'", lines 
        endif else begin
            spawn,'grep -i '+string(num)+' '+baryfile, lines 
        endelse
    end
end

if 1-keyword_set(noprint) then forp,lines
u = where(lines ne '', nlines)
end
