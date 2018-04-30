# The CPS Keck/HIRES Doppler code
Update Oct 2017

Now running on cadence at Caltech the Doppler code can be run on a star-by-star
basis, or at the end of an observing night.

## Dependencies

The doppler code and all sub-routines are present the doppler account home directory
/home/doppler/dopcode/.  There are two sub-directories, pros/ and markwardt. Each holds
specific versions of programs with common names. 

The main programs that drive the code and write files to disk call the IDL path from
environment variables saved in /home/doppler/.cshrc.

## Most commonly used programs:

IDL> dop_driver,starname,tag,vdtag=tag,/keck2,/noprint,/vank
or  IDL> dop_driver,'10700','ad',vdtag='ad',/keck2,/noprint,/vank

Check dop_driver.pro for additional keywords and explanations.
This call calculates a VD file for any star in kbcvel.ascii that 
does not already have a VD. This call can be used at the end of the night
or to re-run all of the RVs for a single star.

IDL> make_dsst,starname,tag,dsst_run_number,vdtag=tag
or IDL> make_dsst,'10700','ad','j21',vdtag='ad'

This call is used to create the deconvolved stellar template for a single star.

### End of night Observing.
cd /home/doppler/reduce/
> xdop

xdop searches for the most recently updated logsheet and runs the VDs, and
DSSTs, if neccsary for all stars observed that night. Multiple calls to xdop
can be simultaneously.


-----------OLD----------------------OLD----------------------OLD-----------
UPDATE 14 June 2016

The dopcode directory now contains the best dopcode that we have.
The previous version is now located in dopcode_old/.


This file is a record of the account 'doppler'.

This entire directory was created first as a direct copy of 
everything in john johnson's account. I then removed many of the files
that were unnecessary. 

The next step was to try to isolate the Doppler code programs into a single
directory, especially removing calls to john Johnson's directory and account.

The files that were copied from /o/johnjohn/dopcode/ were added to with 
programs that are used in the APF doppler code. Any missing programs were
copied to the directory: /o/doppler/dopcode/pros/. 

Next I will try to run the doppler code and get identical results as those
obtained with what is currently the standard version that is saved in 
/o/johnjohn/dopcode. I will eventually have to remove all calls to johnjohn's
directories.


The best way to test the code will begin with a VD, run it on the johnjohn
accont with one tag name, and run it on the doppler account with a different
tag name.

on JJ account:
dop_driver,'166' , 'ha',vdtag='ha',dssttag='ad',run='rj165',/keck2,/noprint ; rj165.25

on Doppler account
dop_driver,'166' , 'hb',vdtag='hb',dssttag='ad',run='rj165',/keck2,/noprint ; rj165.25

;There are many versions of contf.pro. I don't know if I have the correct one.

29 May 2014
On the first try, only one pass was run on the new doppler account. I need
to figure out how to make all three passes work.

Once I have completely consistent doppler codes, I will institute a version
control, using github.

Once I have this completed, I need to remove all of the calls to any program
or file stored in /o/johnjohn/  Do this by grepping all of the programs, then
go through one by one and change the calls. 

Problem. The VDs don't match. Perhaps contf.pro is not the same for both 
sets of programs:

;contf programs compiled in jj's directory.
/o/johnjohn/idl/redux/contf.pro  	
/o/johnjohn/idl/valenti/contf.pro 	; Currently the version used in Dop_account
/o/johnjohn/idl/spectra/hamred/contf.pro

It is important to use the contf.pro version stored in the valenti direcotry
because each of three versions is different and will give different dopper results.

The VDs created are now identical. I double checked this against all parameters
and I even did a sum of all of vd.z and found the same values for each.

Next I will run a VDIOD and make sure that both are working properly.
rj165.525

doppler account
make_vdiod,'rj165.525',tag='ha',/keck2

johnjohn's account
make_vdiod,'rj165.525',tag='hb',/keck2

Both VDIODs  match perfectly. I had to change one directory in make_vdiod.pro.
This is fine, since I plan on changing them all anyway.



Next I will have to run a DSST and make sure that it returns exactly the same
results on each account.

doppler account
make_dsst,'166','ha','j21',vdtag='ha'

johnjohn account
make_dsst,'166','hb','j21',vdtag='hb'

These changes were necessary to allow make_dsst.pro to run properly:

;Changed make_dsst directory name from: 
FROM:
;    if n_elements(jjhip) eq 0 then jjhip, jjhip ;HTI commented out
TO
	if n_elements(jjhip) eq 0 then restore,'~/doppler/dopcode/hip.dat' ; HTI add


I had to add an entire directory to the dopcode path. I placed it under
/o/doppler/dopcode/markwardt/.  There are many files there, hopefully they
are all from the markwardt package and do not overwrite any previously named 
programs.

I believe that I have identical versions of the doppler code for all three
pieces of the Doppler code: VDIOD's, VD's and DSST's. I still must try 
jjvank.pro and run the entire thing from end to end.

31 May 2014

Now I am ready for dop_driver command and 

on Doppler account
dop_driver,'166' , 'ha',vdtag='ha',dssttag='ha',/keck2,/noprint ; 

on JJ account:
dop_driver,'166' , 'hb',vdtag='hb',dssttag='hb',/keck2,/noprint ; 



The Doppler account and johnjohn account now produce identical results. Here
are the RVs for HD166

IDL> restore,'/o/doppler/planets/vst166.dat
IDL> print_vels,cf3                        
************************************************************************
      obnm      UT date             jd    mnvel   errvel   mdchi      cts
************************************************************************
  rj19.278   2006/07/09   13926.103218    -3.90     0.99   1.144    93409
  rj19.279   2006/07/09   13926.104259    -8.26     1.01   1.128    92858
  rj19.280   2006/07/09   13926.105336    -8.34     0.95   1.163    92105
  rj23.200   2006/09/03   13981.927604   -19.53     0.98   1.156    94848
  rj23.201   2006/09/03   13981.928507   -15.98     1.09   1.146    91182
  rj23.202   2006/09/03   13981.929514   -15.70     0.99   1.168    94554
  rj26.564   2006/12/15   14084.871238    33.59     1.07   1.122    72032
  rj26.565   2006/12/15   14084.873009    35.77     1.07   1.118    72763
  rj26.566   2006/12/15   14084.874850    33.99     1.05   1.110    72040
 rj43.4203   2007/08/26   14339.083646    10.11     1.13   1.211    56030
  rj84.226   2010/02/24   15251.702770    -1.81     1.19   1.115    47187
 rj111.658   2010/12/28   15558.784104     2.36     1.35   1.178    45039
 rj111.659   2010/12/28   15558.792645     1.05     1.38   1.168    45187
 rj111.660   2010/12/28   15558.796777    -1.16     1.47   1.201    44703
 rj123.327   2011/06/19   15732.106709    -5.54     1.13   1.116    46510
rj156.2013   2012/08/14   16154.149228   -36.65     1.26   1.061    46843
  rj165.25   2013/01/26   16318.702904   -32.14     1.10   1.158    47045
************************************************************************

IDL> restore,'/o/johnjohn/planets/vst166.dat
IDL> print_vels,cf3
************************************************************************
      obnm      UT date             jd    mnvel   errvel   mdchi      cts
************************************************************************
  rj19.278   2006/07/09   13926.103218    -3.90     0.99   1.144    93409
  rj19.279   2006/07/09   13926.104259    -8.26     1.01   1.128    92858
  rj19.280   2006/07/09   13926.105336    -8.34     0.95   1.163    92105
  rj23.200   2006/09/03   13981.927604   -19.53     0.98   1.156    94848
  rj23.201   2006/09/03   13981.928507   -15.98     1.09   1.146    91182
  rj23.202   2006/09/03   13981.929514   -15.70     0.99   1.168    94554
  rj26.564   2006/12/15   14084.871238    33.59     1.07   1.122    72032
  rj26.565   2006/12/15   14084.873009    35.77     1.07   1.118    72763
  rj26.566   2006/12/15   14084.874850    33.99     1.05   1.110    72040
 rj43.4203   2007/08/26   14339.083646    10.11     1.13   1.211    56030
  rj84.226   2010/02/24   15251.702770    -1.81     1.19   1.115    47187
 rj111.658   2010/12/28   15558.784104     2.36     1.35   1.178    45039
 rj111.659   2010/12/28   15558.792645     1.05     1.38   1.168    45187
 rj111.660   2010/12/28   15558.796777    -1.16     1.47   1.201    44703
 rj123.327   2011/06/19   15732.106709    -5.54     1.13   1.116    46510
rj156.2013   2012/08/14   16154.149228   -36.65     1.26   1.061    46843
  rj165.25   2013/01/26   16318.702904   -32.14     1.10   1.158    47045
************************************************************************



2 June 2014
	Now that I have achieved identical results for VDIODs, DSSTs, VDs, and now
	VST structures, I will establish a git backup folder.
	
I have changed the paths in .cshrc to look in the following directories for 
the git programs. If these disappear, then these paths need updated.

set path= ($path /Volumes/owen/petigura/homebrew/bin/git )
set path= ($path /Volumes/owen/petigura/homebrew/bin )

I have initiated git on the doppler account with the following commands:

Dop_account:>git config --global user.name "Howard Isaacson"
Dop_account:>git config --global user.email hisaacson@berkeley.edu
Dop_account:>git config --global core.editor emacs
Dop_account:>git config --global merge.tool vimdiff

I have not established a diff tool yet.
This is one option:
 git config --global merge.tool vimdiff

;;I have initated the git directory:

Dop_account:>cd dopcode
Dop_account:>git init
Initialized empty Git repository in /o/doppler/dopcode/.git/

Dop_account:>git add *
Dop_account:>git commit -m 'Initiation of Git Version Control on Doppler Code: (2 June 2014)'
[master (root-commit) 2dd3352] Initiation of Git Version Control on Doppler Code: (2 June 2014)
 882 files changed, 118215 insertions(+), 0 deletions(-)

I created a .gitignore file, and inserted *~, so that ~ files are not tracked.
*~

I also removed many files that I though were extraneous. These files now live
in /o/doppler/dopcode_notused/. I removed them from the git repository also.



Next, I will search for all instances of calls to the johnjohn direcotry, 
and replace them with calls to the Doppler directory.

 All of the following program need modified from call

*************************************************************************

DONE:
check_ipguess.pro:restore,'/home/johnjohn/dopcode/ipguess_k2.dat'
crank.pro:        restore,'~johnjohn/dopcode/ipguess.dat'
crank.pro:            keyword_set(longformat): restore,'~johnjohn/dopcode/ipguess_long_k2.dat' 
crank.pro:            keyword_set(quadwav): restore,'~johnjohn/dopcode/ipguess_quad_k2.dat' 
crank.pro:            else: restore,'~johnjohn/dopcode/ipguess_k2.dat'
crank.pro:                restore,'~johnjohn/dopcode/ipguess_k2.dat'
crank.pro:                restore,'~johnjohn/dopcode/ipguess_sub.dat'
crank.pro:                restore,'~johnjohn/dopcode/ipguess_lick.dat'
crank.pro:        restore,'~johnjohn/dopcode/ipguess_mag.dat'
crank.pro:        restore,'~johnjohn/morph/ipcf_mag.dat'
crank.pro:        restore,'~johnjohn/dopcode/ipguess_sub.dat'
crank.pro:        restore,'~johnjohn/dopcode/ipguess_lick.dat'
crank.pro:            restore,'~johnjohn/dopcode/ipguess_k2.dat'
crank.pro:            restore,'~johnjohn/dopcode/ipguess.dat'
derive_psf.pro:        restore, '/home/johnjohn/dopcode/vdtest_keck.dat'
derive_psf.pro:        baryfile = '/home/johnjohn/emu/ebcvel.ascii'          
fm_makedriver.pro:if 1-keyword_set(outfile) then outfile='/o/johnjohn/morph/fm_driver.dat'
fm_results.pro:if 1-keyword_set(dfile) then dfile = '~johnjohn/morph/fm_driver.dat'
fm_results.pro:            file = '~johnjohn/planets/vst'+name+'.dat'
fm_results.pro:                cffile = '~johnjohn/planets/cf'+name+'_'+tag+'.dat'
fm_results.pro:                    file = '~johnjohn/planets/vst'+name+'.dat'
fm_results.pro:                line += ' ~johnjohn/morph/stars_need_temp.txt '
getcf.pro:    keyword_set(lvel): file = '~johnjohn/lickvel/vst'+str(star)+'.dat'
getcf.pro:    else: file = '~johnjohn/planets/vst'+str(star)+'.dat'
jjvank.pro:;cfdsk = '~johnjohn/planets/cf' 
jjvank.pro:    keyword_set(lvel): vstdsk = '~johnjohn/lickvel/'
jjvank.pro:    else: vstdsk = '~johnjohn/planets/'
jjvank.pro:;vstdsk1 = '~johnjohn/planets/'
make_dsst.pro:        baryfile = '~johnjohn/emu/ebcvel.ascii'
make_vdiod.pro:    baryfile = '~johnjohn/emu/ebcvel.ascii'
make_vdiod.pro:            ipg = '~johnjohn/dopcode/ipguess_k2.dat' 
make_vdiod.pro:            ipg = '~johnjohn/dopcode/ipguess_sub.dat'
make_vdiod.pro:;          ipg = '~johnjohn/dopcode/ipguess_k2.dat'  ;HTI updated to dop account
make_vdiod.pro:;                ipg = '~johnjohn/dopcode/ipguess_k2.dat' ;HTI 5/2014 changed to doppler directory:
make_vdiod.pro:                if keyword_set(tell) then rdsk,tellist,'~johnjohn/dopcode/tellist_k2.dsk',1
make_vdiod.pro:                    ipg = '~johnjohn/dopcode/ipguess_long_k2.dat' 
make_vdiod.pro:                    ipg = '~johnjohn/dopcode/ipguess_quad_k2.dat' 
make_vdiod.pro:                ipg = '~johnjohn/dopcode/ipguess.dat'
make_vdiod.pro:            ipg = '~johnjohn/dopcode/ipguess_mag.dat' 
make_vdiod.pro:            ipg = '~johnjohn/dopcode/ipguess_sub.dat'
make_vdiod.pro:            ipg = '~johnjohn/chiron/ipguess_chiron.dat'
make_vdiod.pro:            vdexample = '~johnjohn/chiron/vdexample_chiron.dat'
make_vdiod.pro:                ipg = '~johnjohn/dopcode/ipguess_long_lick.dat' 
make_vdiod.pro:                ipg = '~johnjohn/dopcode/ipguess_lick.dat' 
make_vdiod.pro:            ipg = '~johnjohn/dopcode/ipguess_lick.dat' 
move_em.pro:pre = '/o/johnjohn/planets/vst'
vdiod_keck.pro:ipg = '/home/johnjohn/dopcode/ipguess_k2.dat'
vdiod_subaru.pro:ipg = '/home/johnjohn/dopcode/ipguess_sub.dat'


Does not need changed.
clean_up.pro:spawn, 'mv /mir3/files/dsst*aa_rj5[4-5]*.dat /mir3/johnjohn/trash/j55b/'
clean_up.pro:spawn, 'ls /mir3/johnjohn/trash/j55b/dsst*', lines
clean_up.pro:    com = 'mv /mir3/files/vdaa'+star+'*rj5[4-5]* /mir3/johnjohn/trash/j55b/'
dc_test.pro:cfname   = '/home/johnjohn/planets/cf10700_'+tag+'.dat'
dop_driver.pro:;        if keyword_set(tell) then rdsk,tellist,'~johnjohn/dopcode/tellist_k2.dsk',1
dop_driver.pro:            rdsk,tellist,'~johnjohn/dopcode/tellist_valenti.dsk',1
dop_driver.pro:    baryfile = '~johnjohn/emu/ebcvel.ascii'
dsst_narrow.pro:;readcol,'/home/johnjohn/morph/library.txt',hd,form='a'
dsst_narrow.pro:restore,'/home/johnjohn/morph/library.dat'
make_ipguess.pro:        restore,'/home/johnjohn/sg/dop/ipcf.dat'
make_ipguess.pro:        restore,'/home/johnjohn/morph/ipcf_k2.dat'
make_ipguess.pro:save, ipguess, file='/home/johnjohn/new_dopcode/ipguess_'+suff+'.dat'
modify_ipguess.pro:        file = '/home/johnjohn/new_dopcode/ipguess_lick.dat'
modify_ipguess.pro:        file = '/home/johnjohn/dopcode/ipguess_k2.dat'
rdnso.pro:                restore, '/mir3/johnjohn/jay_9407_nodes.dat'
rdnso.pro:    restore,'/home/johnjohn/morph/arcturus.dat'
rdsi.pro:    fdsk='~johnjohn/chiron/'
rdsi.pro:    obdsk = '~johnjohn/chiron/'


*************************************************************************

All of the changes have been made, so I will now run the DSST, VDIODS, VD 
and VST again, to make sure that everything still works.

doppler account, tag 'hc' will be the experimental tag for now

make_dsst,'166','hc','j21',vdtag='hc'
dop_driver,'166' ,'hc',vdtag='hc',dssttag='hc',/keck2,/noprint ; 



I will not run the johnjohn account DSST again.
johnjohn account
make_dsst,'166','hb','j21',vdtag='hb'  ; running




Here is another star that I will run to make sure everything is identical:
Dop Directory
make_dsst,'9218','hc','j181',vdtag='hc' ; running
dop_driver,'9218' ,'hc',vdtag='hc',dssttag='hc',/keck2,/noprint ; 

This must also be run on the johnjohn directory
make_dsst,'9218','hb','j181',vdtag='hb' ; running
dop_driver,'9218' ,'hb',vdtag='hb',dssttag='hb',/keck2,/noprint ; 

Running three DSSTs right now, one on johnjohn and two on doppler.


3 June 2014

I found that there is one VD in the 9218 group that was not identical.
IDL> restore,'/mir3/files/vdhc9218_rj178.149
IDL> vdhc=vd
IDL> restore,'/mir3/files/vdhb9218_rj178.149

doppler account
dop_driver,'9218' , 'hc',vdtag='hc',dssttag='hc',run='rj178',/keck2;,/noprint ; rj178.149

dop_driver,'9218' , 'hb',vdtag='hb',dssttag='hb',run='rj178',/keck2,/noprint ; rj178.149

I found that the initial guesses were different for the two accounts, that was
the only difference. Now I need to run all of the VDs for the 'hc' and 'hb'
tags again. Only on doppler account because I copied the starting guess file
from johnjohn to doppler

dop_driver,'9218' ,'hc',vdtag='hc',dssttag='hc',/keck2,/noprint ,/overwrite



As another test, I will run ck00351, which Lauren is interested in. There is a
trend with barycentric correction, so perhaps a re-run will help this problem.

make_dsst,'ck00351','ha','j161',vdtag='ha' ;
dop_driver,'ck00351' ,'ha',vdtag='ha',dssttag='ha',/keck2,/noprint ; 




4 June 2014

The 9218 RVs now match exactly between the johnjohn and doppler accounts.


I will no institude the changes that I laid out to Geoff in late April 2014.

Here are the notes, copied from an email, that outline the changes that I will
now make.

--------------------------------------------------------------------------
Upcoming fixes:

1)  I have debugged some code in dop_driver.pro that finds the barycentric correction
of a given star. Previously, stars with a "_" in their name were given the wrong BC for
the template.  I have added an if-statement near line 240 to correct this problem.


2) There is a problem in the build_vd.pro that can remove some chunks
from the VD for a given observation such that 704 chunks remain, instead of 718.
I ran the stars 124292 and 100180, and found large improvement in 124292 and 
marginal improvement in 100180.

Moving forward this line will be removed (around line 323), resulting in ALL VDs
having 718 chunks. Include statement that stops code if not 718 chunks are found.
This fix is NOT yet installed.

The process will be to identify a list of VDs with 704 chunks, move all such VDs to 
/mir3/files/old/ and re-run the VD. All stars with modified VDs must also be vanked
again.  Run about 10 stars, with obvious bad RVs and make sure the proposed
change will work.  This does not require re-computing the DSSTs. I have been running
the dop_driver command with dssttag='ad' and a different vd tag such as 'ha'


3) In vank, insert code in vdcube.pro, near line 190, to remove 'BAD' chunks from
vanking procedure. Use VDIODs to identify chunks that consistently have high Chi^2 
values. This is expected to be about 5% of chunks. Since the DSST, VDIOD, and VD
should all have 718 chunks, there should be indexing errors, write some smart code
to identify VDs that someone have fewer than 718 chunks.

This is the biggest change of the four listed here, and will require testing such that
the RV-RMS and RV-errors are analyzed. There must be a noticeable improvement in 
RMS and Errors in order to implement this change.  This change has NOT been done yet.

4) When the file ipguess_k2.dat is opened, be sure that only 'ad' tag VDIODs are used
when calculating the starting guess. Currently, any VDIOD can be used as a starting
guess. We know that AD VDIODs are good quality, so we should always use these.
This change is NOT yet installed.
--------------------------------------------------------------------------


Beginning with point 4:
These are all the instances of ipguess_k2: in /o/doppler/dopcode/
[done] check_ipguess.pro:restore,'/o/doppler/dopcode/ipguess_k2.dat' 
[done] crank.pro: 
[done] make_vdiod.pro:            ipg = '~doppler/dopcode/ipguess_k2.dat' 
[done] make_vdiod.pro:            ipg = '~doppler/dopcode/ipguess_k2.dat'  
[done] make_vdiod.pro:                ipg = '~doppler/dopcode/ipguess_k2.dat' 
[obsolete program] vdiod_keck.pro:ipg = '/o/doppler/dopcode/ipguess_k2.dat'; 6/2014, NOT tested


This problem is now resolved. All starting VD guesses will now have the 'ad'
tag. I think this is a good idea, in the case that an experimental tag was
run, a new VD that uses the experimental VD as a starting guess may be 
corrupted.


I will fix problem 2 tomorrow. I also need to work out a way to update the 
cf structures that are up to date in /o/johnjohn/planets, and the 
/o/doppler/planets directory is NOT up to date.

I also need to fix a way such that I can write to the vst files in /mir3/vel.
Currently the doppler account cannot overwrite those files created by the
johnjohn account.  Make sure that you have a program ready to confirm that
any changes made have not ruined anything.


TEST
--


