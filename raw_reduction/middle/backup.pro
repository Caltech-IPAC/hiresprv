pro backup

print
print
print
print
print, '               Keck data backup script'
print, '                 ---JTW 21 Nov 2005'
print
print, 'This script will copy raw images into a '
print, 'scratch directory for convenient DVD backup.'
print 
print, 'It will exclude wideflats from this copying '
print, 'to save time and space.'
print, "In lieu of them, it will include the 10 groups "
print, "of summed flats created by the raw reduction."
print, "This means that the raw reduction needs to have finished"
print, "the reduction of the flats for the data you're "
print, "backing up before running this script."
print
print, 'Hold on... looking for scratch space... this may take a minute...'
spawn,'scratchdisks',scratch
space=strpos(scratch[4],' ', /reverse_search)
scrdir=strmid(scratch[4],space+1)
;scrdir = '/h/scratch40/'
print, "Using the directory "+scrdir+" to store files for DVD backup"
in = ''
print, 'Enter the first raw data directory (e.g. /s/sdata125/hires13/20Nov2005/): '
read, in
datadir = in
while (findfile(datadir))[0] eq '' do begin
  print, 'Invalid path'
  print, 'Re-enter the first raw data directory (e.g. /s/sdata125/hires13/20Nov2005/): '
  read, in
  datadir = in  
endwhile
while in ne '' do begin
  print
  print, 'Enter the next raw data directory'
  read, 'or press <ENTER> when done: ', in  
  if in ne '' then datadir = [datadir, in]
endwhile
datadir = datadir
ndir = n_elements(datadir)

night = ''
run = ''
print
read, 'Enter the run prefix (e.g. j14): ', run
read, 'Enter the first logsheet/night number (e.g. 1): ', night
in = night
while in ne '' do begin
  print
  print, 'Enter the next logsheet/night number'
  read,  'or press <ENTER> when done: ', in
  if in ne '' then night = [night, in]
endwhile
nnight=n_elements(night)

for i = 0, n_elements(night)-1 do begin
  l = (findfile('/home/gmarcy/logsheets/'+run+'.logsheet'+night[i]))[0]
  if l eq '' then begin
    print
    print, "Warning!  Cannot find the logsheet "+'/home/gmarcy/logsheets/'+run+'.logsheet'+night[i]
    print, "quitting..."
    stop
  endif
  if i eq 0 then logsheets = l else logsheets = [logsheets, l]
endfor

print
print, 'Found the following logsheet(s):'
loglist = ''
for i = 0, n_elements(logsheets)-1 do begin
  print, logsheets[i]
  loglist = loglist+' '+logsheets[i]
endfor
print
spawn, 'grep -i -h flat'+loglist, out
flats = 0
for i = 0, n_elements(out)-1 do begin
  print, out[i]
  m = strmatch(out[i], '*[0-9]-[0-9]*flat*')
  if m then begin
    hy = strpos(out[i], '-')
    sp = strpos(out[i], ' ', hy)
    first = strmid(out[i], 0, hy)
    last = strmid(out[i], hy+1, sp-hy-1)
    print, "Excluding files           "+run+'.'+strtrim(string(first, form = '(i4.4)'), 2)+" through "+run+'.'+strtrim(string(last, form = '(i4.4)'), 2)
    print
    inds = fix(first)+indgen(fix(last)-fix(first)+1)
    if flats[0] eq 0 then flats = inds else flats = [flats, inds]
  endif else print, "Don't know what to do with this entry."
endfor

flats = run+strtrim(string(flats, form = '(i4.4)'))+'.fits'
backup = findfile(datadir+'/*')

for i = 0, n_elements(flats)-1 do begin
  m = where(strmatch(backup, '*'+flats[i]), nm)
  if nm eq 0 then begin
    print, "Warning!---"
    print, "Cannot find purported flat spectrum "+flats[i]
    stop
  endif
  if nm gt 1 then begin
    print, "Warning!---"
    print, "Don't know what's wrong with spectrum -- it's appearing multiple times!"+flatse[i]
    stop
  endif
  remove, m, backup
endfor

findcommand = "find /home/gmarcy/reduce/ -name '"+run+".[0-9]*.flat[0-9].fits'"
spawn, findcommand, out, err
n = n_elements(out)
groupflat = out
if n eq 1 and out[0] eq '' then begin
  print, "DANGER!!!"
  print, "Cannot find any summed flats to replace the wideflats."
  print, "This probably means you haven't started the raw reduction"
  print, "Start the raw reduction, wait for the flats to be summed up"
  print, "And then run this script again"
  stop
endif 

for i = 0, n-1 do begin
  print, "Including the following summed flats and logsheets in the backup:"
  print, groupflat
  print, logsheets
endfor


spawn, 'ls -d '+scrdir+'/marcy', f, err
if f[0] eq '' then spawn, 'mkdir '+scrdir+'/marcy', f, err
spawn, 'ls -d '+scrdir+'/marcy/night'+night[0], f, err
if f[0] eq '' then spawn, 'mkdir '+scrdir+'/marcy/night'+night[0], f, err else begin
  f = findfile(scrdir+'/marcy/night'+night[0])
  if f[0] ne '' then begin
    print
    print, 'The backup directory on /scratch already contains some files'
    print, 'Make sure that it only contains files you wish to backup.'
    print, 'Press any key to continue.'
    junk = get_kbrd(1)
  endif
endelse
print
print, 'Does everything look OK so far?  About to copy things into '+scrdir+'/marcy/night'+night[0]+'/'
junk = get_kbrd(1)
print, 'Commencing backup...'
backup = [backup, groupflat, logsheets]
bad = where(backup eq '', nb)
if nb then remove, bad, backup

for i = 0, n_elements(backup)-1 do begin
  print, 'cp '+backup[i]+' '+scrdir+'/marcy/night'+night[0]+'/'
;  spawn, 'cp '+backup[i]+' '+scrdir+'/marcy/night'+night[0]+'/',err
endfor

print
print, "All done!"
print, "Go to a HIRES account and run autobackup.tcl on "+scrdir+'/marcy/night'+night[0]+'/'

end

