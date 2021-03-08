"""
Download data from the remote workspace
"""

import logging
import json
import os

from urllib import parse

import requests
import http.cookiejar


class Download(object):
    """
    The Download class provides methods for users to download
    individual files from their workspace in HIRES PRV pipeline server.

    It validates user information (via cookie file), then contacts PRV 
    Server to retrieve the requested file.

    The initialization of database class loads the cookie file saved
    from HIRES PRV pipeline login, parse the cookie to look up the
    users workspace.

    Args:
        cookiepath (string): a full cookie file path saved from auth.Login.
        localdir (string): local output directory

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
    localfile = ''
    disp = 1 
    
    content_type = ''

    debug = 0
    debugfile = '' 

    status = ''
    msg = ''
    
    def __init__(self, cookiepath, localdir, **kwargs):
        self.cookiepath = cookiepath
        self.localdir = localdir

        if len(self.cookiepath) == 0:

            self.status = 'error'
            self.msg = 'Failed to find required parameter: cookiepath'
            
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            # TODO: return in ``__init__``
            return retval

        if not os.path.exists(self.localdir):
            self.status = 'error'
            self.msg = "Could not find local directory: {}".format(localdir)
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        if len(kwargs) > 0:
       
            if 'debugfile' in kwargs.keys():
                self.debugfile = kwargs['debugfile']
         
        if len(self.debugfile) > 0:
            
            self.debug = 1
            logging.basicConfig(filename=self.debugfile, level=logging.DEBUG)

            # TODO: fdebug variable unused
            with open(self.debugfile, 'w') as fdebug:
                pass
         
        if self.debug:
            print('Enter database.init:')
            print('cookiepath= %s' % self.cookiepath)

            logging.debug('')
            logging.debug('Enter database.init:')
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

            # TODO: bare except statement
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
       
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/idlDriver/nph-prvDownload?workspace=' + self.workspace

        return

    def directory_listing(self):
        """
        This method returns a listing of all the downloadable files in the
        workspace.
        
        Returns:
            JSON structure: Dictionary with one entry for each workspace data
            directory.  The value of each item is an array of full file paths within each directory.
        """
        
        if self.debug:
            logging.debug('')
            logging.debug('Enter Download.directory_listing')

        url = self.url + '&cmd=listing'

        if self.debug:
            logging.debug('')
            logging.debug('url= [%s]' % url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

        if self.status == 'ok':

            retval = json.loads(self.response.text)

            # hide undocumented files directory containing IDL save files
            del retval['files']

        else:
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg


        return retval
       
    def download(self, filename):
        """
        This method downloads any file from the user's workspace.
        
        Args:
            filename (string): workspace file name 

        Returns:
            JSON structure: structure indicating the status of the submission
        """
        
        if self.debug:
            logging.debug('')
            logging.debug('Enter Download.download: filename = %s, localfile = %s' % objname, localfile)
       
        if len(filename) == 0:
            
            self.status = 'error'
            self.msg = 'Input argument filename is required.'
            
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        self.filepath = filename

        url = self.url + '&cmd=download&fileid=' + filename + '&debug=1'

        if self.debug:
            logging.debug('')
            logging.debug('url= [%s]' % url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

        if self.status == 'ok':

            if self.debug:
                logging.debug('')
            
            self.__save_to_file(os.path.join(self.localdir, os.path.basename(self.filepath)))
        
            if self.debug:
                logging.debug('')
                logging.debug('returned save_to_file:')
                logging.debug('self.status= [%s]' % self.status)
                logging.debug('self.msg= [%s]' % self.msg)

        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def rvcurve(self, objname):
        """
        This method downloads a rvcurve csv file from the user's
        workspace.
        
        Args:
            objname (string): object name; must match an entry in the 'TARGET' column of the workspace database

        Returns:
            JSON structure: structure indicating the status of the submission
        """
        objname = objname.lower()

        if self.debug:
            logging.debug('')
            logging.debug('Enter Download.rvcurve: objname = %s' % objname)

        if len(objname) == 0:
            
            self.status = 'error'
            self.msg = 'Input argument objname is required.'
            
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        self.filepath = './vst' + objname + '.csv'

        url = self.url + '&cmd=rvcurve&objname=' + parse.quote(objname) + '&debug=1'

        if self.debug:
            logging.debug('')
            logging.debug('url= [%s]' % url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

        if self.status == 'ok':

            if self.debug:
                logging.debug('')
            
            self.__save_to_file(os.path.join(self.localdir, self.filepath))
        
            if self.debug:
                logging.debug('')
                logging.debug('returned save_to_file:')
                logging.debug('self.status= [%s]' % self.status)
                logging.debug('self.msg= [%s]' % self.msg)

        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def spectrum(self, fileid):
        """
        This method downloads one or more extracted spectrum FITS files
        from the user's workspace. The downloaded file will be a single FITS file
        if ``fileids`` is a single observation code.
        
        Args:
            fileid (string): one or more spectrum file names separated by
                             comma or new line; must match entries in the 'FILENAME' column in the workspace database

        Returns:
            JSON structure: structure indicating the status of the submission
        """

        if self.debug:
            logging.debug('')
            logging.debug('Enter Download.spectrum: fileid = %s' % fileid)
       
        if len(fileid) == 0:

            self.status = 'error'
            self.msg = 'Input argument fileid is required.'
            
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        self.filepath = './r' + fileid + '.fits'
        
        url = self.url + '&cmd=spectrum&fileid=' + fileid + '&debug=1' 

        if self.debug:
            logging.debug('')
            logging.debug('url= [%s]' % url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

        if self.status == 'ok':

            if self.debug:
                logging.debug('')
            
            self.__save_to_file(os.path.join(self.localdir, self.filepath))
        
            if self.debug:
                logging.debug('')
                logging.debug('returned save_to_file:')
                logging.debug('self.status= [%s]' % self.status)
                logging.debug('self.msg= [%s]' % self.msg)
        
        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def __submit_request(self, url):

        if self.debug:
            logging.debug('')
            logging.debug('Enter database.__submit_request:')
            logging.debug('url= [%s]' % url)

        try:
            self.response = requests.get(url, stream=True)

            if self.debug:
                logging.debug('')
                logging.debug('request sent')
        
        except Exception as e:
            
            if self.debug:
                logging.debug('')
                logging.debug('exception: e= %s' % str(e))

            self.status = 'error'
            self.msg = 'Failed to submit the request: ' + str(e)
            return
        
        if self.debug:
            logging.debug('')
            logging.debug('status_code:')
            logging.debug(self.response.status_code)
      
        if self.response.status_code == 200:
            self.status = 'ok'
            self.msg = ''
        else:
            self.status = 'error'
            self.msg = 'Failed to submit the request'
            
        if self.debug:
            logging.debug('')
            logging.debug('headers: ')
            logging.debug(self.response.headers)
      
        self.content_type = self.response.headers['Content-type']
       
        if self.content_type == 'json':
            
            if self.debug:
                logging.debug('')
                logging.debug('return is a json structure: error message')
            
            jsondata = json.loads(self.response.text)
            
            self.status = jsondata['status']
            self.msg = jsondata['msg']

        return

    def __save_to_file(self, filepath):

        if self.debug:
            logging.debug('')
            logging.debug('Enter database.__save_to_file:')
            logging.debug('filepath= %s' % filepath)
       
        try:
            with open(filepath, 'wb') as fd:

                for chunk in self.response.iter_content(chunk_size=512):
                    fd.write(chunk)
            
        except Exception as e:

            if self.debug:
                logging.debug('')
                logging.debug('exception: e= %s' % e)

            self.status = 'error'
            self.msg = 'Failed to save returned data to file: %s' % filepath
            
            return

        self.status = 'ok'
        self.msg = ''
        return
