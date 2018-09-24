import os
import sys
import logging
import json
import ijson

import requests
import urllib
import http.cookiejar

import webbrowser

class Database:

    """
    Each workspace in HIRES PRV pipeline server contains a database
    of all the HIRES radial velocity data retrieved from KOA for
    the user.

    The HIRES PRV database class provides methods for querying that
    database.  This information is primarily used to plan reduction
    and analysis processing for specific sky targets.
    
    prvState.py class validates user information (via cookie file), then
    contacts PRV Server to get the current metadatas file.
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
   
            cookiepath (string): a full cookie file path saved from auth.Login.
        """


        self.cookiepath = cookiepath

        if (len(self.cookiepath) == 0):
            
            self.status = 'error'
            self.msg = 'Failed to find required parameter: cookiepath.'
            
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
       
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/idlDriver/nph-prvState?workspace=' + self.workspace

        return

    
    def search (self, **kwargs):
        
        """
        The search method is the most general mechanism for querying 
        a workspace database.  The user has the freedom to provide a
        general SQL SELECT statement (specifying both the database columns 
        to be retrieved and constraints on the records returned.  

        When the sql is blank (i.e.: ''), the entire database will be 
        returned.

        The user can also select an output format (html, csv or IPAC ASCII).
        
        The output will be saved to a disk file and/or display in a browser 
        depending on the format:
       
        'cvs' format: save to disk,
        'html' format: save to disk and display in browser,
        'IPAC' ASCII format: save to disk and display in browser.
        
        Args: keyword/value pair arguments are all optional.
        
            sql='fully qualified sql statement' (string):
            if not specified, the whole database table will be returned.

            format='csv/html/ipac' (string): specifies the format of the 
            returned file; the default is html.

            filepath='full path filename' (string): the filepath to save
            the data on the disk; if not provided, the data will be displayed
            in the browser.

        """
        
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter database.search:')
       
        self.sql = ''
        if ((len(kwargs) > 0) and ('sql' in kwargs.keys())):
            self.sql = kwargs['sql']

        self.filepath = ''
        if ((len(kwargs) > 0) and ('filepath' in kwargs.keys())):
            self.filepath = kwargs['filepath']

        self.format = 'html'
        if ((len(kwargs) > 0) and ('format' in kwargs.keys())):
            self.format = kwargs['format']
        
        if (len(self.filepath) > 0):
            self.disp = 0;
        else:
            self.disp = 1;
 
        if self.debug:
            logging.debug ('')
            logging.debug ('sql= %s' % self.sql)
            logging.debug ('format= %s' % self.format)
            logging.debug ('filepath= %s' % self.filepath)
            logging.debug ('disp= %d' % self.disp)
        
        url = self.url 
        if (len(self.filepath) > 0): 
            url = url + '&filepath=' + self.filepath

        if (len(self.format) > 0): 
            url = url + '&format=' + self.format
            
        if (len(self.sql) > 0): 
            url = url + '&sql=' + self.sql

        if self.debug:
            logging.debug ('')
            logging.debug ('url= [%s]' % url)

        if (self.disp == 1): 
            
#            try:
#                webbrowser.open (url)
#            except:
#                pass
 
            return url

                
        self.__submit_request(url)
        
        if self.debug:
            logging.debug ('')
            logging.debug ('returned submit_request:')
            logging.debug ('self.status= [%s]' % self.status)
            logging.debug ('self.msg= [%s]' % self.msg)

#
#    save to file is specified
#
        if (self.status == 'ok'):

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

    
    def target_list (self, **kwargs):
        
        """
        The target_list method returns a list of targets currently in
        the database.
        
        Args: keyword/value pair arguments are all optional.
        
            format='csv/html/ipac' (string): specifies the format of the 
            returned file; the default is html.

            filepath='full path filename' (string): the filepath to save
            the data on the disk; if not provided, the data will be displayed
            in the browser.

        """
        
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter database.target_list:')
        
        self.filepath = ''
        if ((len(kwargs) > 0) and ('filepath' in kwargs.keys())):
            self.filepath = kwargs['filepath']

        self.format = 'html'
        if ((len(kwargs) > 0) and ('format' in kwargs.keys())):
            self.format = kwargs['format']
            
        if (len(self.filepath) > 0): 
            self.disp = 0 
        else:
            self.disp = 1;
  
        self.sql = 'select distinct target from FILES;'

        url = self.url + '&format=' + self.format + '&sql=' + self.sql

        if self.debug:
            logging.debug ('')
            logging.debug ('sql= %s' % self.sql)
            logging.debug ('filepath= %s' % self.filepath)
            logging.debug ('format= %s' % self.format)
            logging.debug ('disp= %d' % self.disp)
            logging.debug ('url= [%s]' % url)

        if (self.disp == 1): 
            
#            webbrowser.open (url)
            return (url)
          
        self.__submit_request(url)
        
        if self.debug:
            logging.debug ('')
            logging.debug ('returned submit_request:')
            logging.debug ('self.status= [%s]' % self.status)
            logging.debug ('self.msg= [%s]' % self.msg)

#
#    save to file is specified
#
        if (self.status == 'ok'):

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


    def target_info (self, target, **kwargs):
        
        """
        The target_info method retrieves the data pertaining to a specific
        target.
        
        Args: there is on required argument (target), 
        keyword/value pair arguments are all optional.
        
            target: target name, 

            format='csv/html/ipac' (string): specifies the format of the 
            returned file; the default is html.

            filepath='full path filename' (string): the filepath to save
            the data on the disk; if not provided, the data will be displayed
            in the browser.

        """
       
        if self.debug:
            logging.debug ('')
            logging.debug ('Enter database.target_info: target= %s' % target)
       
       
        self.filepath = ''
        if ((len(kwargs) > 0) and ('filepath' in kwargs.keys())):
            self.filepath = kwargs['filepath']

        self.format = 'html'
        if ((len(kwargs) > 0) and ('format' in kwargs.keys())):
            self.format = kwargs['format']
            
        if (len(self.filepath) > 0):
            self.disp = 0 
        else:
            self.disp = 1;
  
        
        self.sql = "select * from FILES where target like '%" + target + "%';"

#        self.sql = "select * from FILES where upper(target) = upper('" + target + "');"


        url = self.url + '&format=' + self.format + '&sql=' + self.sql

        if self.debug:
            logging.debug ('')
            logging.debug ('sql= %s' % self.sql)
            logging.debug ('filepath= %s' % self.filepath)
            logging.debug ('format= %s' % self.format)
            logging.debug ('disp= %d' % self.disp)
            logging.debug ('url= [%s]' % url)


        if (self.disp == 1): 
            
#            webbrowser.open (url)
            return (url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug ('')
            logging.debug ('returned submit_request:')
            logging.debug ('self.status= [%s]' % self.status)
            logging.debug ('self.msg= [%s]' % self.msg)

#
#    save to file is specified
#
        if (self.status == 'ok'):

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


    def sqlite(self, filepath):
        
        """
        The sqlite method downloads the sqlite database file.
        
        Args: 
        
            filepath (string): full path filename to save the database file 
            on the disk.

        """
        
        self.filepath = filepath
        self.cmd = 'sqlite'

        if self.debug:
            logging.debug ('')
            logging.debug ('Enter database.sqlite: filepath = %s' 
                % self.filepath)
       
        if (len (self.filepath) == 0):
            
            self.status = 'error'
            self.msg = 'Input argument filepath is required.'
            
            retval = {}
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval


        url = self.url + '&cmd=' + self.cmd

        if self.debug:
            logging.debug ('')
            logging.debug ('sqlite= %s' % self.sqlite)
            logging.debug ('self.url= [%s]' % self.url)

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
            logging.debug ('sql= %s' % self.sql)
            logging.debug ('sqlite= %s' % self.sqlite)
            logging.debug ('format= %s' % self.format)
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
                       