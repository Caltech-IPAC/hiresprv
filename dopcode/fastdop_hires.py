#!/usr/bin/env python

'''
   Adopted from BJ Fulton's fastdop.py for using on APF
   Date: 9 Feb 2018
   
   In Call to genfromtxt on kbarylog, I added an extra column. and usecols keyword
   Changed logs to /home/doppler/logs from logs/
   Removed all /apf calls in dopcde commands.

   Automatic creation of dsst not working. Doing it by hand. 
'''
import numpy as np
import pp
import threading
import time
import os
import socket
import pandas as pd

# Define directories using environment variables.
kbc_file = os.environ['DOP_BARYFILE']
dop_dir  =  os.environ['DOP_DIR']
files_dir = os.environ['DOP_FILES_DIR']
run_tag = 'ae' # for now.
dsst_tag = 'ae'
print(dop_dir)

names1=['obs', 'star', 'bc', 'hjd', 'ha', 'type','junk']
kbc = np.genfromtxt(kbc_file, dtype=None, invalid_raise=False, skip_header=3,
                    names=names1,usecols=(0,1,2,3,4,5))
fullkbc = kbc.copy()
adf = pd.DataFrame(kbc)


def args():
    import argparse

    parser = argparse.ArgumentParser(description='Run doppler analysis.')
    parser.add_argument(metavar='stars',dest='stars',action='store',help='Star or list of stars to analyze.',default=[], nargs='*')
    parser.add_argument('--tag', dest='tag',action='store',help='Doppler code tag. [xx]',default='xx',type=str)
    parser.add_argument('--bstars',dest='bstars',action='store_true',help='Only analyze B star spectra (make vdiods only). [False]',default=False)
    parser.add_argument('--ncpus',dest='ncpus',action='store',help='Number of local CPUs to utilize. [164]',default=164)
    parser.add_argument('--local', dest='local',action='store_true',help='Run on local computer only. [False]',default=False)
    parser.add_argument('--cand', dest='cand',action='store_true',help='Produce planet candidate list. [False]',default=False)
    parser.add_argument('--run', dest='run',action='store',help='Analyze data from a single night code.', default=None)
    parser.add_argument('--ff', dest='ff',action='store_true',help='Force finishup routine.', default=False)
    parser.add_argument('--joint', dest='joint',action='store_true',help='Run joint APF+Keck search.', default=False)
    
    opt = parser.parse_args()
    
    return opt


def findtemprun(star, kbc):
    tempruns = kbc['obs'][np.where((kbc['type'] == 't') & (kbc['star'] == star.upper()))[0]]
    if len(tempruns) > 0: return tempruns[-1][1:4]
    else: return -1


def make_dsst(star, run, dtag=dsst_tag, dopdir=dop_dir):
    import pidly
    import os
    from glob import glob

    os.chdir(dopdir)
    idl = pidly.IDL()
    try:
        prevd = glob(files_dir +"dsst%s%s_*.dat" % (star, dtag))
        if len(prevd) < 1:
            prevd = files_dir+"dsst%s%s_%s.dat" % (star, dtag, run)
        else:
            prevd = prevd[-1]
        if not os.path.isfile(prevd):
            cmd = "make_dsst, '%s', '%s', '%s', vdtag='%s', dtcrit=0.05, maxchi=1.6" % (star, dtag, run, dtag)
            print cmd
            idl(cmd)
    except:
        idl.close()
    idl.close()


def make_vdiod(star, obnum, tag=run_tag, dopdir=dop_dir):
    import pidly

    os.chdir(dopdir)
    
    idl = pidly.IDL()
    try:
        print "2. Launching make_vdiod:", star, tag, obnum
#        idl("journal, '/home/doppler/logs/%s.log'" % obnum)
        print("make_vdiod, '%s', tag='%s', /noprint" % (obnum, tag))
        idl("make_vdiod, '%s', tag='%s',  /noprint" % (obnum, tag))
        print('past make_vdiod call')
        idl.close()
    except:
        print "Error in make_vdiod job!"
        idl.close()


def dop_driver(star, obnum, tag=run_tag, dopdir=dop_dir):
    import pidly

    os.chdir(dopdir)
    
    idl = pidly.IDL()
    try:
        print "Launching dop_driver1:", star, tag, obnum
        idl("journal, '/home/doppler/logs/%s.log'" % obnum)
        idl("dop_driver, '%s', '%s', vdtag='%s', specific='%s'" % (star, tag, tag, obnum))
        idl.close()
    except:
        print "Error in dop job!"
        idl.close()


def finishup(star, tag=run_tag, dopdir=dop_dir):
    import pidly
    import os
    idl = pidly.IDL()

    os.chdir(dopdir)

    #if len(sys.argv) <= 3:
    #    numthreads = 0
    #else:
    numthreads = 1
    
    try:
        idl("jjvank, '%s', '%s', percentile=0.98, /noplot, /detrend" % (star, tag))
        idl.close()

        idl = pidly.IDL()
#        idl("!PATH = !PATH+':/mir4/dop/'") # For HIRES, taken care of in environment variables.
#       idl("cd, '/mir4/template_plot/'")
#       idl("template_plot, '%s', tag='%s', out_dir='/data/user/doppler/public_html/bg/apf/template/'" % (star.lower(), tag))

#       idl("cd, '/mir4/speclines/'")
#       idl("speclines, '%s', filename='/data/user/doppler/public_html/bg/apf/speclines/spec_%s'" % (star, star.lower()))

#       idl("cd, '/mir4/sval/'")
#       idl("sval_plots, '%s', outfilepath='/data/user/doppler/public_html/bg/apf/sval/'" % star)

#       idl("cd, '/mir4/bjsearch/'")
#       idl("spawn, 'rm -rvf %s'" % star)
#       idl("apfsearch, vstname='%s', numthreads=%d, minsearchP=1.15" % (star.lower(), numthreads))

#       if opt.joint and os.path.isfile('/mir3/vel/vst%s.dat' % star.lower()):
#            idl("cd, '/mir4/jointsearch/'")
#            idl("spawn, 'rm -rvf %s'" % star)
#            idl("limsearch, vstname='%s', numthreads=%d, minsearchP=1.15, fapthresh=0.01, /apf, /gls" % (star, numthreads))
    except:
        idl.close()
    idl.close()

def launchdop(server, star, obs, tag=run_tag, ff=False, dopdir=dop_dir):
    os.chdir(dopdir)
    havenew = False
    print "Waiting for DSST to finish.", star
    server.wait(group='dsst.%s' % star)
    print "Launching dop jobs.", star
    for o in obs:
        if os.path.isfile(files_dir+'vd%s%s_%s' % (tag, star.lower(), o)):
            #print "%s: %s %s already done" % (star, tag,o)
            continue
        else:
            print "Launching dop_driver2:", star, tag, o
            havenew = True
            dop_driver(star, o, tag)
            #djob = server.submit(dop_driver, (star, o, tag), group="dop."+star)
            time.sleep(0.3)
    #server.print_stats()
    server.wait("dop."+star)
    time.sleep(2)
    #if len(obs) >= 3:
    if havenew or ff:
        print "Running finishup for %s" % star
        server.submit(finishup, (star,tag), group="dop."+star)
        server.wait("dop."+star)
        # finishup(star, tag=tag)
        

def launchvdiod(server, star, obs, tag=run_tag, dopdir=dop_dir):
    os.chdir(dopdir)
    
    print "Launching vdiod jobs.", star
    for o in obs:
        if os.path.isfile(files_dir+'vdiod%s_%s.%s' % (star.lower().replace('hr',''), o, tag)):
            print "%s: %s %s already done" % (star, tag, o)
            continue
        else:
            print "Launching make_vdiod:", star, tag, o, files_dir+'vdiod%s_%s.%s' % (star.lower().replace('hr',''), o, tag)
            dop_driver(star, o, tag) #hti changed commented out next line for this.
            #djob = server.submit(make_vdiod, (star, o, tag), group="vd."+star)
            #time.sleep(0.3)
    #server.print_stats()
    time.sleep(2)
    server.wait("vd."+star)
    
if __name__ == '__main__':

    opt = args()
    print(opt)
    if opt.run != None:
        kbc = kbc[np.char.find(kbc['obs'], opt.run) > -1]
    
    if opt.stars == []: 
        stars = np.unique(kbc['star'])[::-1]
    else: 
        stars = [s.upper() for s in opt.stars]
        
    if not opt.local:
        if opt.ncpus is None:
            server = pp.Server(ppservers=("*",), secret='gj3470b')
        else:
            server = pp.Server(ppservers=("*",), secret='gj3470b', ncpus=int(opt.ncpus))
        time.sleep(2)
    elif opt.local:
        server = pp.Server(ncpus=int(opt.ncpus))

    nodes = server.get_active_nodes()
    print "Active nodes:\nServer                         NCPUS\n-------------------------------------"
    for n in nodes.keys():
        try:
            host = socket.gethostbyaddr(n.split(":")[0])[0]
        except:
            host = n.split(":")[0]
        print "%s\t%s" % (host.ljust(30), nodes[n])
    print "-------------------------------------\n"
        
    badobs = ['junk','th-ar','specfoc','sky','warm-84.7c', 'warm-89.9c', 'uranus', 'moon',
              'iodine','dark','dark_(-94.5)','bias','kc01c19785','bd+27_4380', '42176',
              '96712', '189733', '195689', '343246b', 'epic203771098',
              '1-secondtest']
    forcerun = ['hr8799']

    # Run all vdiods first
    print "Running vdiods"
    print len(stars),stars
    vdjobs = []
    for star in stars:
        if star.lower() in forcerun or (star.lower() in badobs or star.lower().startswith('twil-')):
            print "Skipping %s" % star
            continue

        obs = kbc['obs'][np.where((kbc['star'] == star) & (kbc['type'] == 'o'))[0]]
        nobs = len(obs)
        print('Number of Bstars running: ',nobs)

        if star.lower().startswith('hr'):
            vdjobs.append(threading.Thread(target=launchvdiod, args=(server,star, obs, opt.tag)))
            vdjobs[-1].start()

    for d in vdjobs:
        d.join()

    if opt.bstars: os._exit(0)
        
    # Now run all other stars
    print "Running dop jobs"
    dsstjobs = []
    dopjobs = []
    runstars = []
    for star in stars:
        if star.lower().startswith('hr') or (star.lower() in badobs or star.lower().startswith('twil-')):
            if star.lower() not in forcerun:
                print "Skipping %s" % star
                continue

        obs = kbc['obs'][np.where((kbc['star'] == star) & (kbc['type'] == 'o'))[0]]
        nobs = len(obs)
        
        if nobs < 3:
            # print "Too few observations for %s" % star, nobs
            NoObs = True
        else:
            NoObs = False
        
        temprun = findtemprun(star, fullkbc)
#        if star == '141004':
#            temprun = 'aa1'
#        if star == '4628':
#            temprun = 'aaq'
#        if star == '185144':
#            temprun = 'acz'
#        if star == '127334':
#            temprun = 'acy'
#        if star == '12846':
#            temprun = 'aar'
#        if star == 'KC11C019701':
#            temprun = 'akz'
#
#        if opt.tag == 'kd' or opt.tag == 'cd':
#            temprun = 'zzz'

        df = adf[adf.obs.str.startswith("r{}".format(temprun))]
        dfg = df.groupby('star')
        have_bstars = False
        for targ in dfg.groups:
            if targ.lower().startswith('hr'):
                if (df.query('star == "{}"'.format(targ)).type == 'o').any():
                    have_bstars = True
                    break
        if not have_bstars and not temprun == 'zzz':
            print("Could not find B stars to make template for {} on run {}".format(star, temprun))
            temprun = -1

        if temprun != -1:
            if not NoObs:
                print "Found template observation for %s on run %s" % (star, temprun)
                #make_dsst(star, temprun)
                job = server.submit(make_dsst, (star, temprun, opt.tag), group='dsst.%s' % star)
                dopjobs.append(threading.Thread(target=launchdop, args=(server, star, obs, opt.tag, opt.ff)))
                dopjobs[-1].start()
                # launchdop(server, star, obs, opt.tag)
                runstars.append(star)
                time.sleep(0.5)
            #else: print "No template observation found for %s" % star

    for d in dopjobs:
        d.join()

#    if opt.cand:
#        os.chdir('/mir4/bjsearch/')
#        os.system('/home/bfulton/idl/rvsearch/sortcandidates.py')
#        
#        os.chdir('/mir4/bjsearch/')
#        os.system('cd /mir4/bjsearch; python /home/bfulton/idl/rvsearch/pltcombine.py')
#        os.system('cp */*-multisearch.png multiplots/; chmod 664 multiplots/*')
#        os.system('cp -v multiplots/* /data/user/bfulton/public_html/apf/multiplots/')
#        os.system('cp -v multiplots/* /data/user/doppler/public_html/bg/apf/multiplots/')
#        # os.system('rsync -e "ssh -i /home/bfulton/.ssh/id_rsa" -a multiplots bfulton@webpages.ifa.hawaii.edu:public_html/apf/')


