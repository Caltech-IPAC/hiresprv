import os
import sys
import logging
import json
import ijson

import requests
import urllib
import http.cookiejar


class Download:

    """
    The Download class provides methods for users to download the 
    individual file from their workspace in HIRES PRV pipeline server.

    It validates user information (via cookie file), then contacts PRV 
    Server to get the requested file.
    """    

    cookiepath = ''
    userid = ''
    workspace = ''
    cookiestr = ''

    target = ''
    cmd = ''
   
    sql = ''
    format = 'html'
    filepath = ''
    disp = 1 
    
    content_type = ''


    debug = 0
    debugfile = '' 

    status = ''
    msg = ''
    
    def __init__ (self, cookiepath, **kwargs):

        """
        The initialization of database class loads the cookie file saved
        from HIRES PRV pipelone login, parse the cookie to look up the 
        users workspace. 
        
        Args:
        ----------------
        cookiepath (string): a full cookie file path saved from auth.Login.
        """

        self.cookiepath = cookiepath

        if (len(self.cookiepath) == 0):

            self.status = 'error'
            self.msg = 'Failed to find required parameter: cookiepath'
            
            retval = {}
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval


        if (len(kwargs) > 0):
       
            if ('debugfile' in kwargs.keys()):
                self.debugfile = kwargs['debugfile']
         
        if (len(self.debugfile) > 0):
            
            self.debug = 1
            logging.basicConfig (filename=self.debugfile, level=logging.DEBUG)
            
            with open (self.debugfile, 'w') as fdebug:
                pass
         
        if self.debug:
            print ('Enter database.init:')
            print ('cookiepath= %s' % self.cookiepath)

            logging.debug ('')
            logging.debug ('Enter database.init:')
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
       
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/idlDriver/nph-prvDownload?workspace=' + self.workspace

        return


    def rvcurve (self, objname):
    
        """
        The rvcurve method downloads a rvcurve csv file from the user's 
        workspace. 
        
        Args: 
        ---- 
        objname (string): the object name of the rvcurve.
        """
        
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter Download.rvcurve: objname = %s' % objname)
       
        if (len (objname) == 0):
            
            self.status = 'error'
            self.msg = 'Input argument objname is required.'
            
            retval = {}
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        self.filepath = './vst' + objname + '.csv'

        url = self.url + '&cmd=rvcurve&objname=' + objname + '&debug=1'

        if self.debug:
            logging.debug ('')
            logging.debug ('url= [%s]' % url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug ('')
            logging.debug ('returned submit_request:')
            logging.debug ('self.status= [%s]' % self.status)
            logging.debug ('self.msg= [%s]' % self.msg)
       

        if (self.status == 'ok'):

            if self.debug:
                logging.debug ('')
            
            self.__save_to_file (self.filepath) 
        
            if self.debug:
                logging.debug ('')
                logging.debug ('returned save_to_file:')
                logging.debug ('self.status= [%s]' % self.status)
                logging.debug ('self.msg= [%s]' % self.msg)
       

        retval = {}
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    
    def spectrum(self, fileid):
    
        """
        The spectrum method downloads one or more spectrum FITS files 
        from the user's workspace. The downloaded file will be a FITS file 
        if 'fileids' is a single file name and a GZIP file if multiple 
        files are requested.
        
        Args: 
        ---- 
        spec_fileid (string): one or more spectrum file names separated by
        comma or new line.
        """
        
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter Download.spectrum: fileid = %s' % fileid)
       
        if (len (fileid) == 0):

            self.status = 'error'
            self.msg = 'Input argument fileid is required.'
            
            retval = {}
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        """
        fileidstr = fileid
        filelist = None
        
        delimiter = ''
        ind = -1
        ind = fileidstr.find (',')
        if self.debug:
            logging.debug ('comma: ind= %d' % ind)

        if (ind != -1):
            delimiter = ','
        else:
            ind = fileidstr.find ('\r')
                  
            if debug:
                logging.debug ('carriage return: ind= %d' % ind)
                
            if (ind != -1):
                delimiter = '\r'
            else:
                ind = fileidstr.find ('\n')

            if (ind != -1):
                delimiter = '\n'
                    
            if debug:
                logging.debug ('')
                logging.debug ('delimiter= [%s]' % delimiter)
       
            mylist = None
            if (len(delimiter) > 0): 
                mylist = fileidstr.split(delimiter)
            else:
                list = [fileidstr]
                
            ncnt = len(mylist)  
             
            if debug:
                logging.debug ('')
                logging.debug ('ncnt= %d' % ncnt)
           

            nfileid = 0
            for i in range (0, len(mylist)):
                    
                if debug:
                    logging.debug ('mylist[%d]= %s' % (i,mylist[i]))

                if (len(mylist[i]) > 0):
                    nfileid = nfileid + 1

            fileidlist = ['']*n

            nfileid = 0
            for i in range (0, len(mylist)):
                    
                if (len(mylist[i]) > 0):
                    filelist[nfileid] = mylist[i]
                    nfileid = nfileid + 1

        if debug:
            logging.debug ('')
            logging.debug ('End of parsing fileid: nfileid= %d' % nfileid)
            for i in range (0, len(fileidlist)):
                logging.debug ('fileidlist[%d]= %s' % (i,fileidlist[i]))


        if (nfileid == 0): 
            return

        if (nfileid == 1): 
            self.filepath = './' + fileidlist[0] + '.fits'
        else:
            ind = fileidlist[0].find('.')
            substr = fileidlist[0][0:ind]
            self.filepath = './' + substr + '.gz'

        if self.debug:
            logging.debug ('filepath= %s' % self.filepath)
        """

        self.filepath = './r' + fileid + '.fits'
        
        url = self.url + '&cmd=spectrum&fileid=' + fileid + '&debug=1' 

        if self.debug:
            logging.debug ('')
            logging.debug ('url= [%s]' % url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug ('')
            logging.debug ('returned submit_request:')
            logging.debug ('self.status= [%s]' % self.status)
            logging.debug ('self.msg= [%s]' % self.msg)
       

        if (self.status == 'ok'):

            if self.debug:
                logging.debug ('')
            
            self.__save_to_file (self.filepath) 
        
            if self.debug:
                logging.debug ('')
                logging.debug ('returned save_to_file:')
                logging.debug ('self.status= [%s]' % self.status)
                logging.debug ('self.msg= [%s]' % self.msg)
        
        retval = {}
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval



    def __submit_request(self, url):

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter database.__submit_request:')
            logging.debug ('url= [%s]' % url)

        
        try:
            self.response =  requests.get (url, stream=True)

            if self.debug:
                logging.debug ('')
                logging.debug ('request sent')
        
        except Exception as e:
            
            if self.debug:
                logging.debug ('')
                logging.debug ('exception: e= %s' % str(e))

            self.status = 'error'
            self.msg = 'Failed to submit the request: ' + str(e)
            return
                       
        
        if self.debug:
            logging.debug ('')
            logging.debug ('status_code:')
            logging.debug (self.response.status_code)
      
      
        if (self.response.status_code == 200):
            self.status = 'ok'
            self.msg = ''
        else:
            self.status = 'error'
            self.msg = 'Failed to submit the request'
            
        if self.debug:
            logging.debug ('')
            logging.debug ('headers: ')
            logging.debug (self.response.headers)
      
      
        self.content_type = self.response.headers['Content-type']
       
        if (self.content_type == 'json'):
            
            if self.debug:
                logging.debug ('')
                logging.debug ('return is a json structure: error message')
            
            jsondata = json.loads (self.response.text)
            
            self.status = jsondata['status']
            self.msg = jsondata['msg']

        return


    def __save_to_file (self, filepath):

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter database.__save_to_file:')
            logging.debug ('filepath= %s' % filepath)
       
        try:
            with open (filepath, 'wb') as fd:

                for chunk in self.response.iter_content (chunk_size=512):
                    fd.write (chunk)
            
        except Exception as e:

            if self.debug:
                logging.debug ('')
                logging.debug ('exception: e= %s' % e)

            self.status = 'error'
            self.msg = 'Failed to save returned data to file: %s' % filepath
            
            return

        self.status = 'ok'
        self.msg = ''
        return
                       