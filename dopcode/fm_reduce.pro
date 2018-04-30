function fm_checkout, driver_file, check_in=check_in, lockfile=lockfile
if keyword_set(lockfile) then got_lock=get_lock_file(lockfile)
restore,driver_file
if keyword_set(check_in) then begin
    use = where(driver.name eq check_in.name, nu)
    if nu gt 0 then begin
        driver[use].done = 1
        driver[use].busy = 0
        save, driver, file=driver_file
        return, 1
    endif else return, -1
endif
use = where(1-driver.done and 1-driver.busy, nuse)
if nuse gt 0 then begin
    d = driver[use[0]] 
    driver[use[0]].busy = 1b
    save, driver, file=driver_file
endif else d = -1
if keyword_set(lockfile) then dummy_var=free_lock_file(lockfile)
return, d
end

pro fm_reduce, starin $
				, maxobs=maxobs $
				, tag=tagin $
				, driver_file=driver_file $
               , noprint=noprint $
               , plot_dop=dopplot $
               , plot_morph=plot $
               , overwrite=over $
               , dop=dop $
               , vank=vank $
               , run=run $
               , keck2=keck2 $
               , useobs=use $
               , grep=grep $
               , remorph=remorph $
               , first_obs=first_obs $
               , noplotvank=noplotvank $
               , sun=sun $
               , arc=arc $
               , optional_morph=optional_morph $
               , numuse=numuse $
               , oneper=oneper $
               , minobs=minobs $
               , allkeck=allkeck $
               , vd_infile=vd_infile $
               , force_avpsf=force_avpsf $
               , single_run=single_run $
               , dtag=dtag $
               , maxchi=maxchi $
               , nomorph=nomorph $
               , vdtag=vdtag $
               , cfout=cf $
               , morph=morph $
               , justdop=justdop $
               , mncts=mncts $
               , userun_fordsst=userun_in $
               , kvel=kvel $
               , post=post $
;obsolete      , jan=jans $
               , atlas=atlas $
               , narrow=narrow $
               , movie=movie $
               , lockfile=lockfile $
               , simple_psf=simple_psf

if 1-keyword_set(morph) then nomorph = 1 ; I know, this is confusing, but it's for backwards compatibility
if 1-keyword_set(minobs) then minobs = 3


keck2 = 1 ; keck2 means Keck/HIRES post-upgrade
files = getenv("DOP_FILES_DIR")

if keyword_set(tagin) then tag = tagin else begin
    tag = 'ch' 
    tagin = tag
endelse
if 1-keyword_set(dtag) then dtag = tag
if 1-keyword_set(driver_file) then begin
    if keyword_set(starin) then begin
        nstars = n_elements(starin)
        driver = {name:'', busy:0, done:0}
        driver = replicate(driver, nstars)
        driver.name = starin
    endif else begin
        spawn,'ls -tr ~/dopcode/*.driver',lines
        nlines = n_elements(lines)
        driver_file = lines[nlines-1]
    endelse
endif
cool = 0b
i = 0
while not cool do begin;;; loop until FM_REDUCE returns -1, then we're done
    if n_elements(driver_file) eq 0 then begin ;;; Check if driver file supplied
        if i lt nstars then d = driver[i] else d = -1 ;;; If not, then use starlist
    endif else begin
        d = fm_checkout(driver_file, lockfile=lockfile)
    endelse
    tag = tagin
    if size(d,/type) ne 8 then cool = 1b else begin
        ;;;Check for template observation. 
        barylook, d.name $
        		, /temp $
        		, lines=lines $
                , grep=grep $
                , nlines=nlines $
                , /nopr
        if nlines gt 0 then begin
            tags = ['obnm','name','bc','jd']
            types = ['a','a','f','f']
            struct = col_struct(lines,tags,types=types) 
            num = cftape(struct.obnm,/num)
            un = uniq(num, sort(num)) ;;select uniq runs

            struct = struct[un]
            srt = sort(struct.jd)
        ;;; Find the latest template obs
            parts = strsplit(struct[srt[n_elements(srt)-1]].obnm, '.', /ext)
            userun = parts[0]
            dfile = files+'dsst'+strlowcase(d.name)+dtag+'_'+userun+'.dat'
            cond = check_file(dfile) 
            if keyword_set(justdop) then begin
                if cond then goto, justdop else begin
                    print, '*********'
                    print, '/JUSTDOP, but dsst not found ('+dfile+')'
                    print, '*********'
                    goto, done
                endelse
            endif
        endif else cond = 0
        morph:
        cond2 = 1-cond and keyword_set(nomorph) 
        if cond2 then begin ;;; No DSST, but also /NoMorph. Create DSST
            if keyword_set(keck2) then grep = 'r[j,k]'
            barylook, d.name $
            		, /obsonly $
            		, lines=olines $
                    , nlines=o_nlines $
                    , /nopr
            if nlines gt 0 and o_nlines gt 0 then begin
                if keyword_set(userun_in) then userun = userun_in
                if keyword_set(vdtag) then vdt = vdtag else vdt = 'ad'
                make_dsst, d.name $
                		 , dtag   $
                		 , userun $
                		 , jjhip=jjhip $
                         , vdt=vdt $
                         , maxchi=maxchi $
                         , atlas=atlas $
                         , narrow=narrow $
                         , movie=movie

            endif else begin
                if o_nlines eq 0 then begin
                    print,'Iodine observations do not exist for '+d.name
                endif else begin
                    print,'Template observation does not exist for '+d.name
                endelse
                goto, done
            endelse
        endif
        cond = check_file(dfile)
        cond1 = cond and (keyword_set(optional_morph) or keyword_set(nomorph))
        if cond1 then begin  ;;; Gather DSST and BC, start Doppler Analysis
            spawn,'ls '+dfile,dfile
            print,'DSST exists for '+d.name+' : '+dfile
            ndf = n_elements(dfile)
            if ndf gt 1 then dfile = dfile[ndf-1]
            g = (strsplit((strsplit(dfile,'_',/ext))[1],'.',/ext))[0]
            barylook, strupcase(d.name) $
            		, grep=g  $
            		, /temp   $
            		, /nopr   $
            		, line=line
            bc = getwrd(line[0],2)
            dsstname = (strsplit(dfile,'/',/ext))[2]
            if 1-keyword_set(tag) then tag = 'j'
            morph = 0
            goto, justdop
        endif
        morph = 1
        dsstnm = 'dsst'+d.name+'_'+dtag+'.dat'
        barylook,d.name $
        		 , /obs $
                 , grep=grep $
                 , lines=lines $
                 , nlines=nlines $
                 , /nopr $
                 , keck2=keck2
        if nlines lt 1 then goto, done else nobs = nlines
        ;;; Does Morph DSST exist? If yes, create a new one anyway (/remorph)?
        cond = 1-check_file(files+dsstnm) or keyword_set(remorph)
        justdop:
        ;;; This barylook call is only to print out number of observations
        barylook,d.name $
                 , /nopr $
                 , grep=grep $
                 , lines=lines
        if lines[0] eq '' then goto, done  else begin
            runnum = str(strmid(str(lines),0,4))
            if 1-keyword_set(run) then begin
                runtest = ['rj01','rj99']
            endif else begin
                if n_elements(run) eq 2 then runtest = run else $
                  runtest = [run[0],run[0]]
            endelse
            if str(runtest[0]) ne '0' then $
              dummy = where(runnum ge runtest[0] and $
                            runnum le runtest[1], nobs) else nobs = nlines
        endelse
        print,'Number of Observations: '+str(nobs)
        ;;; Now do Dop Analysis
        print,'ENTERING DOP_DRIVER WITH STAR, DSST',D.NAME, '  ',DSSTName
        if keyword_set(dop) and nobs ge minobs and d.name ne 'junk' then begin
            dop_driver, d.name, dtag $
            			, noprint=noprint $
                        , keck2=keck2 $
                        , dopplot=dopplot $
                        , vank=vank $
                        , over=over $
                        , run=run $
                        , dsstn=dsstname $
                        , bc=bc $
                        , allkeck=allkeck $
                        , force_av=force_avpsf $
                        , single_run=single_run $
                        , noplotvank=noplotvank $
                        , vdtag=tag $
                        , frzw0=frzw0 $
                        , maxchi=maxchi $
                        , cf=cf $
                        , mncts=mncts $
                        , kvel=kvel $
                        , atlas=atlas $
                        , simple=simple_psf
        endif
        done:
        if 1-keyword_set(starin) then dum = fm_checkout(driver_file, check_in=d, lockfile=lockfile)
    endelse
    i++
endwhile 

end
