pro modify_add, ipguess
files = strmid(ipguess[0].name, 0, 11)
print, 'Enter tape name '
tape = ''
read, tape
spawn,'ls -l '+files+'/vdiod*'+tape+'*', lines
spawn,'ls '+files+'/vdiod*'+tape+'*', lines2
nel = n_elements(lines)
if nel gt 0 then begin
    done = 0
    while 1-done do begin
        forp, indgen(nel), lines, form='(i-3, 2x, a-100)'
        print, 'Enter line number, -1 to quit'
        read, num
        if num lt nel and num ge 0 then begin
            use = lines2[num]
            parts = strsplit(use, '/', /ext)
            new = ipguess[0]
            new.name = files+'/'+parts[2]
            parts = strsplit(use, '_', /ext)
            obnm = parts[1]
            if strmid(obnm, 1, 1, /rev) eq '.' then $
              obnm1 = strmid(obnm, 0, strlen(obnm)-2)
            barylook, obnm1, /other, line=baryline, /nopr
            jd = double(getwrd(baryline, 3)) + 2.44d6
            new.jd = jd
            w = where(ipguess.jd eq jd, nw)
            if nw eq 0 then begin
                ipguess = [ipguess, new]
                srt = sort(ipguess.jd)
                ipguess = ipguess[srt]
            endif else print, 'Entry already exists in IPGUESS'
        endif else done = 1
    endwhile
endif
end

pro modify_ipguess, lick=lick

print,'THIS PROGRAM NEEDS UPDATED IN ORDER TO WORK IN DOPPLER ACCOUNT'
RETURN ; HTI 6/2014. This progam seems outdated, so it was never updated 
;					when the doppler astro account was created.

case 1 of
    keyword_set(magellan):
    keyword_set(lick): begin
        file = '/home/johnjohn/new_dopcode/ipguess_lick.dat'
        restore, file
    end
    keyword_set(keck1):
    keyword_set(aat):
    else: begin
        file = '/home/johnjohn/dopcode/ipguess_k2.dat'
        restore, file
    end
end
done = 0
form = '(i-3, 2x, f8.1, 2x, a-21, 2x, f15.1)'
while 1-done do begin
    vdiod = str(strmid(ipguess.name, 12, 21))
    nel = n_elements(vdiod)
    forp, indgen(nel), ipguess.jd-min(ipguess.jd), vdiod, ipguess.jd, form=form
    print, '(A)dd  (R)emove  (U)ndo last  (Q)uit'
    ans = ''
    read, ans
    case strlowcase(strmid(ans, 0, 1)) of
        'a': begin
            old = ipguess
            modify_add, ipguess
        end
        'r': begin
            old = ipguess
            print, 'Enter number to remove'
            read, num
            if num lt nel and num ge 0 then begin
                remove, num, ipguess
            endif
        end
        'u': ipguess = old
        'q': done = 1
        else: print, 'Option "'+ans+'" not found.'
    end
endwhile
spawn, 'date +%m%d%y', date
backup = file+date
print, 'Back up '+file+' as '+backup+' ? Y/n'
ans = ''
read, ans
if strlowcase(strmid(ans,0,1)) eq 'n' then begin
    print,'Enter extension for backup file. Currently "'+date+'"'
    extension = ''
    read, extension
    backup = file+extension
endif
spawn,'mv '+file+' '+backup
save, ipguess, file=file
end
