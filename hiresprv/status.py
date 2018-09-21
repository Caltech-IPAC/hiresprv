import os
import sys
import logging
import json
import ijson

import requests
import urllib
import http.cookiejar

import webbrowser

class Status:

    """
    The HIRES PRV processing involves moving and reducing quite a lot of
    data and can be quite lengthy.  Most of this processing is therefore
    done in background.

    The PRV Status class is used to check the state of the processing,
    either in detail to watch progress or simply to check whether the 
    workspace is 'busy'.  New processing will be rejected until the 
    workspace is ready.
    """

    """
    prvStatus.py class validates user information (via cookie file), then
    contacts PRV Server to get the current processing status.
    """    

    cookiepath = ''
    userid = ''
    workspace = ''
    cookiestr = ''

    url = ''
    response = ''

    type = 'status'
    target = ''
 
    debug = 0
    debugfile = '' 
#    debugfile = './monitor.debug' 

    status = ''
    msg = ''
    
    def __init__ (self, cookiepath, **kwargs):

        """
        The PRV Status class initialization checks for the existence 
        of a login cookie and connects the user to their workspace.  
        Methods of this class return information on the current state.

        Args:
        ----------------
        cookiepath: a full cookie file path saved from auth.Login.
        """

        self.cookiepath = cookiepath
        if (len(self.cookiepath) == 0):
            print ('Failed to find required parameter: cookiepath')
            return
 
        if ('debugfile' in kwargs): 
            self.debugfile = kwargs.get('debugfile')

        if (len(self.debugfile) > 0):
            
            self.debug = 1
            logging.basicConfig (filename=self.debugfile, level=logging.DEBUG)
            
            with open (self.debugfile, 'w') as fdebug:
                pass

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter Status.init:')
            logging.debug ('cookiepath= %s' % self.cookiepath)
   
        self.cookiejar = http.cookiejar.MozillaCookieJar (self.cookiepath)
    
        if (len(self.cookiepath) > 0):
   
            try: 
                self.cookiejar.load (ignore_discard=True, ignore_expires=True)
    
                if self.debug:
                    logging.debug ('cookie loaded from %s' 
                        % self.cookiepath)
        
                for cookie in self.cookiejar:
                    
                    if self.debug:
                        logging.debug ('cookie= %s' % cookie)
                        logging.debug ('cookie.name= %s' % cookie.name)
                        logging.debug ('cookie.value= %s' % cookie.value)
                        logging.debug ('cookie.domain= %s' % cookie.domain)
                    
                    if (cookie.name == 'HIPRV'):
                        self.cookiestr = cookie.value                
                        
            except:
                pass

                if self.debug:
                    logging.debug ('loadCookie exception')
 
        if self.debug:
            logging.debug ('cookiestr= %s' % self.cookiestr)
       
        if (len(self.cookiestr) > 0): 
            arr = self.cookiestr.split ('|') 
            narr = len(arr)
        
        if self.debug:
            logging.debug ('narr= [%d]' % narr)
            for i in range (0, narr):
                logging.debug ('arr[%d]= [%s]' % (i, arr[i]))
        
        if (narr == 3):    
            self.userid = arr[0]
            self.workspace = arr[2]

        if self.debug:
            logging.debug ('userid= %s workspace= %s' 
                % (self.userid, self.workspace))
       
        self.url = 'http://hiresprv.ipac.caltech.edu:8000/cgi-bin/prvMonitor/nph-prvStatus?workspace=' + self.workspace

        return

    
    def processing_status (self):

        """
        The processing_status method returns a summary of the progress of 
        the current processing steps in a browser.  For archive retrieval 
        this includes each file transfer and each raw reduction operation.  
        For data reduction scripts, this includes the various steps in the 
        IDL processing.

        An attempt has been made to update the processing status every few 
        seconds to a minute but a few operations will run longer.
        """
        
        self.url = self.url + '&format=html'

        if self.debug:
            logging.debug ('Enter processing_status')
            logging.debug ('self.url= [%s]' % self.url)

        # webbrowser.open (self.url)
    
        return self.url;


    def is_busy (self):

        """ 
        (TBD) Documentation on Status.is_busy 
        """

        self.url = self.url + '&type=busy'

        if self.debug:
            logging.debug ('Enter is_busy')
            logging.debug ('self.url= [%s]' % self.url)

        self.__send_get ()

        if (self.status == 'error'):
            print (self.msg)
            sys.exit()

        if self.debug:
            logging.debug ('')
            logging.debug ('response.text= [%s]' % self.response.text)
      
        jsondata = json.loads (self.response.text)

        self.status = jsondata['status']
        self.msg = jsondata['msg']

        if self.debug:
            logging.debug ('status= %s msg= %s' % (self.status, self.msg))

        print (self.msg)
        return;

    
    def cancel (self):

        """ 
        (TBD) Documentation on Status.cancel 
        """
        
        self.url = self.url + '&type=cancel'

        if self.debug:
            logging.debug ('Enter cancel')
            logging.debug ('self.url= [%s]' % self.url)

        self.__send_get ()

        if (self.status == 'error'):
            print (self.msg)
            sys.exit()

        if self.debug:
            logging.debug ('')
            logging.debug ('response.text= [%s]' % self.response.text)
      
        jsondata = json.loads (self.response.text)

        self.status = jsondata['status']
        self.msg = jsondata['msg']

        if self.debug:
            logging.debug ('status= %s msg= %s' % (self.status, self.msg))

        print (self.msg)
        return;


    def __send_get (self):

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter send_get:')
   
        if self.debug:
            logging.debug ('url= %s' % self.url)

        try:

#            self.response =  requests.post (self.url, data=self.param, \
#                cookies=self.cookiejar) 
            
            self.response =  requests.get (self.url)

            if self.debug:
                logging.debug ('')
                logging.debug ('request sent')

        except Exception as e:
            
            if self.debug:
                logging.debug ('')
                logging.debug ('exception: e= %s' % e)

            self.status = 'error'
            self.msg = 'Failed to reach PRV server'
            return            
        
        return


