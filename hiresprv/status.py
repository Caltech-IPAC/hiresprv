"""
Monitor the progress of active processing jobs.
"""

import sys
import logging
import json

import requests
import http.cookiejar


class Status:
    """
    The HIRES PRV processing involves transferring and reducing a large amount of
    data and can be quite lengthy.  Therefore, most of this processing is
    done in background.

    The ``hiresprv.status.Status`` class is used to check the state of the processing,
    to watch progress, or simply to check whether the
    workspace is busy.  New processing will be rejected until the 
    workspace is ready.
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
    # debugfile = './monitor.debug'

    status = ''
    msg = ''
    
    def __init__(self, cookiepath, **kwargs):
        """
        The PRV Status class initialization checks for the existence 
        of a login cookie and connects the user to their workspace.  
        Methods of this class return information on the current state.

        Args:
            cookiepath (string): full path to cookie file saved from :func:`hiresprv.auth.login()`

        """

        self.cookiepath = cookiepath
        if len(self.cookiepath) == 0:
            print('Failed to find required parameter: cookiepath')
            return
 
        if 'debugfile' in kwargs:
            self.debugfile = kwargs.get('debugfile')

        if len(self.debugfile) > 0:
            
            self.debug = 1
            logging.basicConfig(filename=self.debugfile, level=logging.DEBUG)
            
            with open(self.debugfile, 'w') as fdebug:
                pass

        if self.debug:
            logging.debug('')
            logging.debug('Enter Status.init:')
            logging.debug('cookiepath= %s' % self.cookiepath)
   
        self.cookiejar = http.cookiejar.MozillaCookieJar(self.cookiepath)
    
        if len(self.cookiepath) > 0:
   
            try: 
                self.cookiejar.load(ignore_discard=True, ignore_expires=True)
    
                if self.debug:
                    logging.debug('cookie loaded from %s' % self.cookiepath)
        
                for cookie in self.cookiejar:
                    
                    if self.debug:
                        logging.debug('cookie= %s' % cookie)
                        logging.debug('cookie.name= %s' % cookie.name)
                        logging.debug('cookie.value= %s' % cookie.value)
                        logging.debug('cookie.domain= %s' % cookie.domain)
                    
                    if cookie.name == 'HIPRV':
                        self.cookiestr = cookie.value                

            # TODO: bare except clause
            except:
                pass

                if self.debug:
                    logging.debug('loadCookie exception')
 
        if self.debug:
            logging.debug('cookiestr= %s' % self.cookiestr)
       
        if len(self.cookiestr) > 0:
            arr = self.cookiestr.split('|')
            narr = len(arr)
        
        if self.debug:
            logging.debug('narr= [%d]' % narr)
            for i in range(0, narr):
                logging.debug('arr[%d]= [%s]' % (i, arr[i]))
        
        if narr == 3:
            self.userid = arr[0]
            self.workspace = arr[2]

        if self.debug:
            logging.debug('userid= %s workspace= %s' % (self.userid, self.workspace))
       
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/prvMonitor/nph-prvStatus?workspace=' + self.workspace

        return
    
    def generate_link(self):
        """
        This method returns an HTML string that contains a link to start 
        the real-time monitor in a separate window/tab.  It is generally
        used in applications like Jupyter notebook where you don't want
        the monitor embedded in the page.

        Returns:
            string: HTML fragment to be embedding in page to provide access
            to real-time monitor page.
        """
        
        linkStr = 'Launch <a href="http://hiresprv.ipac.caltech.edu/applications/prvMonitor/monitor.html?workspace=' + self.workspace + '" target="_blank">real-time monitor</a>.'

        return linkStr


    def processing_status(self):
        """
        This method returns a URL to a page displaying the progress of
        the current processing step.  For archive retrieval
        this includes each file transfer and each raw reduction operation.  
        For data reduction scripts, this includes the various steps in the 
        IDL processing.

        An attempt has been made to update the processing status every few 
        seconds to a minute but a few operations will run longer.

        Returns:
            string: URL to a web page summarizing the progress of the current processing steps
        """
        
        self.url = self.url + '&format=html'

        if self.debug:
            logging.debug('Enter processing_status')
            logging.debug('self.url= [%s]' % self.url)

        # webbrowser.open (self.url)
    
        return self.url

    def is_busy(self):
        """ 
        Check if the workspace is currently busy processing.

        Returns:
            JSON structure
        """

        self.url = self.url + '&type=busy'

        if self.debug:
            logging.debug('Enter is_busy')
            logging.debug('self.url= [%s]' % self.url)

        self.__send_get()

        if self.status == 'error':
            print(self.msg)
            sys.exit()

        if self.debug:
            logging.debug('')
            logging.debug('response.text= [%s]' % self.response.text)
      
        jsondata = json.loads(self.response.text)

        self.status = jsondata['status']
        self.msg = jsondata['msg']

        if self.debug:
            logging.debug('status= %s msg= %s' % (self.status, self.msg))

        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def cancel(self):
        """ 
        Cancel the active job.

        Returns:
            JSON structure
        """
        
        self.url = self.url + '&type=cancel'

        if self.debug:
            logging.debug('Enter cancel')
            logging.debug('self.url= [%s]' % self.url)

        self.__send_get()

        if self.status == 'error':
            print(self.msg)
            sys.exit()

        if self.debug:
            logging.debug('')
            logging.debug('response.text= [%s]' % self.response.text)
      
        jsondata = json.loads(self.response.text)

        self.status = jsondata['status']
        self.msg = jsondata['msg']

        if self.debug:
            logging.debug('status= %s msg= %s' % (self.status, self.msg))

        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def __send_get(self):

        if self.debug:
            logging.debug('')
            logging.debug('Enter send_get:')
   
        if self.debug:
            logging.debug('url= %s' % self.url)

        try:
            # self.response =  requests.post (self.url, data=self.param, \
            #     cookies=self.cookiejar)
            
            self.response = requests.get(self.url)

            if self.debug:
                logging.debug('')
                logging.debug('request sent')

        except Exception as e:
            
            if self.debug:
                logging.debug('')
                logging.debug('exception: e= %s' % e)

            self.status = 'error'
            self.msg = 'Error: failed to reach PRV server'
            return            
        
        return
