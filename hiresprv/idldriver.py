import os
import sys
import logging
import json

import requests
import urllib 
import http.cookiejar


class Idldriver:

    """
    The principle processing of the HIRES PRV pipeline is done by a
    set of IDL scripts developed over several decades.  This processing
    is quite intensive and takes a long time and so is run in the 
    background.

    The HIRES PRV idldriver class provides functionality that allows
    the user to submit radial velocity data reduction scripts that 
    get sent to a sequence of these IDL scripts.
    """

    cookiepath = ''
    script = ''
    scriptfile = ''
   
    workspace = ''

    status = ''
    msg = ''

    debug = 0
    debugfname = '' 

    def __init__ (self, cookiepath, **kwargs):

        """
        The idldriver class intialization checks for cookie indicating 
        a previous login that connects to the user to a PRV pipeline 
        workspace.  This workspace is populated with data from the KOA 
        Archive using Archive class methods.
        
        Args:

            cookiepath: a full cookie file path saved from auth.Login.

        """

        self.cookiepath = cookiepath

        if ('debugfile' in kwargs): 
            self.debugfname = kwargs.get('debugfile')

        if (len(self.debugfname) > 0):
    
            self.debug = 1;
            logging.basicConfig (filename=self.debugfname, level=logging.DEBUG)
         
            with open (self.debugfname, 'w') as fdebug:
                pass
    
        if self.debug:
            logging.debug ('')
            logging.debug ('DEBUG> Enter idldriver.init:')
            logging.debug ('cookiepath= [%s]' % cookiepath)
            logging.debug ('debug= [%d] debugfname= [%s]' 
                % (self.debug, self.debugfname))
      
        if (len(cookiepath) == 0):
            print ('Required input cookie not found.')
            return
        
#
#  load cookie
#
        self.cookiejar = http.cookiejar.MozillaCookieJar (self.cookiepath)
        
        self.cookie = '' 
        try:
            self.cookiejar.load (ignore_discard=True, ignore_expires=True)

            for cookie in self.cookiejar:

                if (cookie.name == 'HIPRV'):
                    self.cookie = cookie
        except:
            pass

            if self.debug:
                logging.debug ('')
                logging.debug ('load cookie exception')

        if (self.cookie != None):

            if self.debug:
                logging.debug ('')
                logging.debug ('cookie= %s' % self.cookie)
                logging.debug ('cookiename= %s' % self.cookie.name)
                logging.debug ('cookievalue= %s' % self.cookie.value)
                logging.debug ('cookiedomain= %s' % self.cookie.domain)

        return


    def run_script (self, script):   

        """
        The HIRES PRV idldriver class run method is given a script of steps to
        run on the data in the user's workspace.  These steps include creating 
        a template spectrum for a sky target, reducing a specific radial 
        velocity measurement using such a template, and creating an RV curve 
        from a set of reduced RV measurements.
        """

        self.script = script 
        
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter idldriver.run_script:')
            logging.debug ('script= %s' % self.script)
    
        self.__submitScript()

        if self.debug:
            logging.debug ('')
            logging.debug ('returned submitScript: status= [%s]' 
                % self.status)
            logging.debug ('returned submitScript: msg= [%s]' % self.msg)
       
        print ('status= %s' % self.status)
        print ('msg= %s' % self.msg)

        return


    def run_scriptfile (self, scriptfile):   

        self.scriptfile = scriptfile 
    
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter idldriver.run_scriptfile:')
            logging.debug ('scriptfile= %s' % self.scriptfile)
    
#
#  read file into a script
#
        with open (scriptfile, 'r') as fp:
            
            self.script = fp.read()
    
        if self.debug:
            logging.debug ('')
            logging.debug ('script read from file')
            logging.debug ('script= %s' % self.script)
    
        self.__submitScript()

        if self.debug:
            logging.debug ('')
            logging.debug ('returned submitScript: status= [%s]' 
                % self.status)
            logging.debug ('returned submitScript: msg= [%s]' % self.msg)
       
        print ('status= %s' % self.status)
        print ('msg= %s' % self.msg)

        return

    
    def __submitScript (self):
   
        debug = 0 

        if debug:
            logging.debug ('')
            logging.debug ('Enter idldriver.__submitScript')
            logging.debug ('script= %s' % self.script)
    
        
        scriptdict = {'script':self.script}
    
        if debug:
            logging.debug ('')
            logging.debug ('format script to dictionary, scriptdict=')
            logging.debug (scriptdict)

#
#   construct URL 
#
        url = "http://hiresprv.ipac.caltech.edu/cgi-bin/idlDriver/nph-idlDriver"

        if debug:
            logging.debug ('')
            logging.debug ('url= %s' % url)

        self.response =  requests.post (url, files=scriptdict, \
            cookies=self.cookiejar) 

        if debug:
            logging.debug ('')
            logging.debug ('response: %s' % self.response.text)
        
        jsonstr = json.loads (self.response.text)

        if debug:
            logging.debug ('')
            logging.debug ('jsonstr: %s' % jsonstr)

        self.status = jsonstr["status"]
        self.msg = jsonstr["msg"]

        if debug:
            logging.debug ('')
            logging.debug ('status: %s' % self.status)
            logging.debug ('msg: %s' % self.msg)

        retval = {}

        retval["status"] = self.status
        retval["msg"] = self.msg

        return retval
