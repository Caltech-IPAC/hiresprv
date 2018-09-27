"""
The ``hiresprv.archive`` module handles data transfers from the Keck Observatory Archive (KOA) archive into the
user workspace on the server and the reduction from 2D CCD images to 1D spectra.
"""
import logging
import requests
import http.cookiejar


class Archive:
    """
    The Archive class provides KOA archive access functions for the HIRES PRV
    pipeline reduction service.  
    
    
    The user's KOA credentials (given at login) are used to search KOA for nights
    containing HIRES-PRV compatible data. Matching data are copied to the user's
    workspace and raw reduction (conversion to 1D spectra, barycentric
    correction, file organization, etc.) is performed.  Results are logged in the workspace
    database table.  All this is done in background; the search functions 
    return almost immediately with an acknowledgement.
    
    Because of pipeline requirements, data is always processed a full 
    night at a time.

    Args:
        cookiepath: full path to a cookie file saved by :func:`hiresprv.auth.login()`

    """

    cookiepath = ''
    parampath = ''
  
    debug = 0
    debugfile = ''
    
    status = ''
    msg = ''
    
    def __init__(self, cookiepath, **kwargs):
        self.project = 'hiresprv' 
        self.instrument = 'hires' 
        self.param = dict()

        self.cookiepath = cookiepath
        if len(self.cookiepath) == 0:
            print('Failed to find required parameter: cookiepath')
            return
 
        if 'debugfile' in kwargs:
            self.debugfile = kwargs.get('debugfile')

        if len(self.debugfile) > 0:
            
            self.debug = 1
           
            logging.basicConfig(filename=self.debugfile, level=logging.DEBUG)

            # TODO: do we need this? It doesn't look like fdebug is being used for anything
            with open(self.debugfile, 'w') as fdebug:
                pass

        if self.debug:
            logging.debug('')
            logging.debug('Enter Search.init:')
            logging.debug('cookiepath= %s' % self.cookiepath)
    
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/PrvPython/nph-prvSearch.py?'
    
        if self.debug:
            logging.debug('')
            logging.debug('url= [%s]' % self.url)

        self.cookiejar = http.cookiejar.MozillaCookieJar(self.cookiepath)
    
        if len(self.cookiepath) > 0:
            try: 
                self.cookiejar.load(ignore_discard=True, ignore_expires=True)
            
                if self.debug:
                    logging.debug('cookie loaded from %s' % self.cookiepath)
        
                    for cookie in self.cookiejar:
                        logging.debug('cookie= %s' % cookie)
                        logging.debug('cookie.name= %s' % cookie.name)
                        logging.debug('cookie.value= %s' % cookie.value)
                        logging.debug('cookie.domain= %s' % cookie.domain)
        # TODO: need to define a particular exception we are looking for blank except statements are not PEP8 compliant
            except:
                pass

                if self.debug:
                    logging.debug('prvSearch: loadCookie exception')
 
        return 

    def by_dates(self, dates):
        """
        Constructs and submits a URL to the server for processing

        This method receives an acknowledgement upon successful submission
        which means it has successfully authenticated the KOA user and
        can start the data search, download, and reduction.

        Args:
            dates (string): a date string or multiple date strings separated by comma or newline.
                            Each date should be in to 'yyyy-mm-dd' format.

        Returns:
            JSON structure:  Status ('ok' or 'error') and a message string \n
            "{status':'ok', 'msg':'Processing dates in background.'}" if successful \n
            "{'status':'error', 'msg':'Failed to connect to KOA'}" if submission failed

        Example:
            >>> import hiresprv.archive
            >>> srch = hiresprv.archive.Archive(cookiepath)
            >>> multi_date_string = "2013-09-23,2013-09-25,2013-10-01"
            >>> srch.by_dates(multi_date_string)
        """

        if self.debug:
            logging.debug('')
            logging.debug('Enter by_dates: dates= %s' % dates)

        self.param['project'] = self.project
        self.param['instrument'] = self.instrument
        self.param['time'] = dates

        if self.debug:
            logging.debug('')

            for k, v in self.param.items():
                logging.debug('k= %s v= %s ' % (k, v))

        self.__send_post()

        if self.debug:
            logging.debug('')
            logging.debug('returned send_post')
            logging.debug('status= %s' % self.status)
            logging.debug('msg= %s' % self.msg)

        retval = dict()

        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def by_datefile(self, datefile):
        """
        This method operates the same as by_dates method except it reads
        the dates string from a file containing a list of dates.

        Args:
            datefile (string): Path to a file containing more than one date. Each date
                      sould be in the 'yyyy-mm-dd' format and separated by new line.

        Returns:
            JSON structure: Same status and msg as :meth:`hiresprv.archive.Archive.by_dates()` method
        """
        
        self.debug = 1
        
        print('Enter by_datefile: datefile= %s' % datefile)
        print('self.debug= %d' % self.debug)

        if self.debug:
            logging.debug('')
            logging.debug('Enter by_dates: datefile= %s' % datefile)

        with open(datefile, 'r') as fp:
           
            if self.debug:
                logging.debug('')
            
            dates = fp.read()

        if self.debug:
            logging.debug('datefile= %s' % datefile)
            logging.debug('dates= [%s]' % dates)

        len_date = len(dates)

        dates = dates[:(len_date-1)]

        if self.debug:
            logging.debug('2: self.dates= [%s]' % dates)

        self.param['project'] = self.project
        self.param['instrument'] = self.instrument
        self.param['time'] = dates

        if self.debug:
            logging.debug('')

            for k, v in self.param.items():
                logging.debug('k= %s v= %s ' % (k, v))

        self.__send_post()

        if self.debug:
            logging.debug('')
            logging.debug('returned send_post')
            logging.debug('status= %s' % self.status)
            logging.debug('msg= %s' % self.msg)
  
        retval = dict()

        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def __send_post(self):

        if self.debug:
            logging.debug('')
            logging.debug('Enter send_post:')
   
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/PrvPython/nph-prvSearch.py'

        if self.debug:
            logging.debug('url= %s' % self.url)

        try:

            self.response = requests.post(self.url, data=self.param, cookies=self.cookiejar)

            if self.debug:
                logging.debug('')
                logging.debug('request sent')

            print(self.response.text)
        
        except Exception as e:
            
            if self.debug:
                logging.debug('')
                logging.debug('exception: e= %s' % e)

            print('post request exception: %s' % e)
        
        return
