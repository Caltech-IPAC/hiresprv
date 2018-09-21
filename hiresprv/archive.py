import os
import sys
import logging
import json
import ijson

import requests
import urllib
import http.cookiejar

class Archive:

    """
    Archive class provides KOA archive access functions for the HIRES PRV 
    pipeline reduction service.  
    
    
    The user's KOA credentials (given at login) are used to search the
    Keck On-line Archive (KOA).  Matching data are copied to the user's
    workspace and raw reduction (conversion to 1D spectra, barycentric
    correction, etc.) is performed.  Results are logged in the workspace
    database table.  All this is done in background; the search functions 
    return almost immediately with an acknowledgement.
    
    Because of pipeline requirements, data is always processed a full 
    night at a time.

    Calling Synopsis:
    ----------------
       
        import hiresprv.archive

        srch = Search (cookiepath) 

        srch.by_dates (multi_date_string), or
        
        srch.by_datefile (datepath)
    """    

    cookiepath = ''
    parampath = ''
  
    debug = 0
    debugfile = ''
    
    status = ''
    msg = ''
    
    def __init__ (self, cookiepath, **kwargs):

        """
        Initialize the class with cookiepath

        Args:
        ----------------
        cookiepath: a full cookie file path saved from auth.Login.

        """

        self.project = 'hiresprv' 
        self.instrument = 'hires' 
        self.param = dict()

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
            logging.debug ('Enter Search.init:')
            logging.debug ('cookiepath= %s' % self.cookiepath)
    
        self.url = 'http://hiresprv.ipac.caltech.edu:8000/cgi-bin/PrvPython/' \
            +  'nph-prvSearch.py?'
    
        if self.debug:
            logging.debug ('')
            logging.debug ('url= [%s]' % self.url)
       

        self.cookiejar = http.cookiejar.MozillaCookieJar (self.cookiepath)
    
        if (len(self.cookiepath) > 0):
   
            try: 
                self.cookiejar.load (ignore_discard=True, ignore_expires=True);
            
                if self.debug:
                    logging.debug (
                        'cookie loaded from %s' % self.cookiepath)
        
                    for cookie in self.cookiejar:
                        logging.debug ('cookie= %s' % cookie)
                        logging.debug ('cookie.name= %s' % cookie.name)
                        logging.debug ('cookie.value= %s' % cookie.value)
                        logging.debug ('cookie.domain= %s' % cookie.domain)
            except:
                pass

                if self.debug:
                    logging.debug (
                        'prvSearch: loadCookie exception')
 
        return 


    def by_dates (self, dates):
        
        """
        'by_dates' method constructs and submits the URL to server for
        processing.  It receives an acknowlegement upon successful submission
        which means it has successfully authenticated the KOA user and
        allow to start data search and download.  

        Args:
        ------

            dates (string): a date string or multiple date strings separated
                            by comman or '\n'; each date should adhere to 
                            'yyyy-mm-dd' format.

            e.g. 
                
                dates = '2013-09-12
            2013-06-29
            2017-10-11
            2014-04-24'
        
        Returns:
        -------
            JSON structure with status ('ok' or 'error') and a message string
            e.g., {'status':'error', 'msg':'Failed to connect to KOA'}
        
            When the submission is successful, it returns:

            {status':'ok', 'msg':'Processing dates in background.'}

        """
        
        self.debug = 0
        if self.debug:
            print ('Enter by_dates: dates= %s' % dates)
            print ('self.debug= %d' % self.debug)

        self.dates = dates

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter by_dates: dates= %s' % dates)

 
        self.param['project'] = self.project
        self.param['instrument'] = self.instrument
        self.param['time'] = self.dates 

        if self.debug:
            logging.debug ('')

            for k,v in self.param.items():
                logging.debug ('k= %s v= %s ' % (k, v))
        
                
        self.__send_post () 

        if self.debug:
            logging.debug ('')
            logging.debug ('returned send_post')
            logging.debug ('status= %s' % self.status)
            logging.debug ('msg= %s' % self.msg)
  

        retval = {}

        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval


    def by_datefile (self, datefile):
        
        """
        This method operates the same as by_dates method except it reads
        the dates string from an inputs a file containing a list of dates

        Args:
        -----    

        datefile: a file containing large number of dates; each date 
            in the 'yyyy-mm-dd' format and separated by new line.

        e.g. 
        2013-09-12
        2013-06-29
        2017-10-11
        2014-04-24
        
        Returns:
        -------
        
        Same status and msg as 'by_dates' method.
        """
        
        self.debug = 1
        
        print ('Enter by_datefile: datefile= %s' % datefile)
        print ('self.debug= %d' % self.debug)

        self.datefile = datefile

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter by_dates: datefile= %s' % datefile)

        with open (datefile, 'r') as fp:
           
            if self.debug:
                logging.debug ('')
            
            dates = fp.read();

        if self.debug:
             logging.debug ('datefile= %s' % datefile)
             logging.debug ('dates= [%s]' % dates)

        len_date = len(dates)

#        if self.debug:
#             logging.debug ('len_date= %d' % len_date)
#             logging.debug ('dates[len_date-1]=')
#             logging.debug (dates[len_date-1])
#             logging.debug (dates[:(len_date-1)])

        self.dates = dates[:(len_date-1)]  

        if self.debug:
             logging.debug ('2: self.dates= [%s]' % self.dates)

        self.param['project'] = self.project
        self.param['instrument'] = self.instrument
        self.param['time'] = self.dates 

        if self.debug:
            logging.debug ('')

            for k,v in self.param.items():
                logging.debug ('k= %s v= %s ' % (k, v))
        
                
        self.__send_post () 

        if self.debug:
            logging.debug ('')
            logging.debug ('returned send_post')
            logging.debug ('status= %s' % self.status)
            logging.debug ('msg= %s' % self.msg)
  
        return


    def __send_post (self):

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter send_post:')
   
        self.url = 'http://hiresprv.ipac.caltech.edu:8000/cgi-bin/PrvPython/nph-prvSearch.py'

        if self.debug:
            logging.debug ('url= %s' % self.url)

        try:

            self.response =  requests.post (self.url, data=self.param, \
                cookies=self.cookiejar) 

            if self.debug:
                logging.debug ('')
                logging.debug ('request sent')

            print (self.response.text)
        
        except Exception as e:
            
            if self.debug:
                logging.debug ('')
                logging.debug ('exception: e= %s' % e)

            print ('post request exception: %s' % e)
        
        return

