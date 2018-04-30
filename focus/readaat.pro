pro readaat,starname,s,rhk

     openr,1,'aat_hk.txt'                  ;open file for reading
     starname = strarr(226)
     s = fltarr(226)
     rhk = fltarr(226)
     st = ' '
     for j=0,225 do begin

       readf,1,st               ; read line in file.
       starname(j) = getwrd(st,0)
       s(j) = float(getwrd(st,1))
       rhk(j) = float(getwrd(st,2))
     End                             ;end while

     close,1
return
end
