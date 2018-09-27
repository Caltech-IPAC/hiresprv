"""
Access and query a user's observation database.
"""

import logging
import json

import requests
import http.cookiejar


class Database:
    """
    Each workspace in HIRES PRV pipeline server contains a database
    listing all the data retrieved from KOA for the user.

    The ``hiresprv.status.Database`` class provides methods for querying that
    database.  This information is primarily used to plan reduction
    and analysis processing.

    The initialization of database class loads the cookie file saved
    from HIRES PRV pipelone login, parse the cookie to look up the
    users workspace.

    Args:
        cookiepath (string): full path to a cookie file saved by :func:`hiresprv.auth.login()`

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
    
    def __init__(self, cookiepath, **kwargs):
        self.cookiepath = cookiepath

        if len(self.cookiepath) == 0:
            
            self.status = 'error'
            self.msg = 'Failed to find required parameter: cookiepath.'
            
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            # TODO: Not good practice to put a return statement in an __init__ statement.
            # Probably should raise an exception instead
            return retval

        if len(kwargs) > 0:
       
            if 'debugfile' in kwargs.keys():
                self.debugfile = kwargs['debugfile']
         
        if len(self.debugfile) > 0:
            
            self.debug = 1
            logging.basicConfig(filename=self.debugfile, level=logging.DEBUG)

            # TODO: If we just want to open this file I don't think we need the with statement.
            with open(self.debugfile, 'w') as fdebug:
                pass
         
        if self.debug:
            print('Enter database.init:')
            print('cookiepath= %s' % self.cookiepath)

            logging.debug('')
            logging.debug('Enter database.init:')
            logging.debug('cookiepath= %s' % self.cookiepath)
   
        self.cookiejar = http.cookiejar.MozillaCookieJar(self.cookiepath)

        # TODO: I think we can remove some of these redundant checks for ``len(self.cookiepath) > 0``
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

            # TODO: bare except
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
       
        self.url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/idlDriver/nph-prvState?workspace=' + self.workspace

        return

    def search(self, **kwargs):
        """
        The search method is the most general mechanism for querying 
        a workspace database.  The user has the freedom to provide a
        general SQL SELECT statement (specifying both the database columns 
        to be retrieved and constraints on the records returned).

        When the sql is blank (i.e.: ''), the entire database will be 
        returned.

        The user can also select an output format (html, csv or IPAC ASCII).
        
        The output will be saved to a disk file and/or displayed in a browser
        depending on the format:
       
        'cvs' format: save to disk,
        'html' format: save to disk and display in browser,
        'IPAC' ASCII format: save to disk and display in browser.
        
        Args:
            sql (string):    (optional) fully qualified sql statement
                             if empty string or parameter not set, the whole database table will be returned.
            format (string): (optional) string specifying the output format ('html'|'csv'|'ipac'); the default is html
            filepath (string): (optional) full path where the file will be saved; if not provided,
                               a URL string to an HTML view of the table.

        Returns:
            string: URL to HTML table if filepath is not specified
        """
        
        if self.debug:
            logging.debug('')
            logging.debug('Enter database.search:')
       
        self.sql = ''
        if (len(kwargs) > 0) and ('sql' in kwargs.keys()):
            self.sql = kwargs['sql']

        self.filepath = ''
        if (len(kwargs) > 0) and ('filepath' in kwargs.keys()):
            self.filepath = kwargs['filepath']

        self.format = 'html'
        if (len(kwargs) > 0) and ('format' in kwargs.keys()):
            self.format = kwargs['format']
        
        if len(self.filepath) > 0:
            self.disp = 0
        else:
            self.disp = 1
 
        if self.debug:
            logging.debug('')
            logging.debug('sql= %s' % self.sql)
            logging.debug('format= %s' % self.format)
            logging.debug('filepath= %s' % self.filepath)
            logging.debug('disp= %d' % self.disp)
        
        url = self.url 
        if len(self.filepath) > 0:
            url = url + '&filepath=' + self.filepath

        if len(self.format) > 0:
            url = url + '&format=' + self.format
            
        if len(self.sql) > 0:
            url = url + '&sql=' + self.sql

        if self.debug:
            logging.debug('')
            logging.debug('url= [%s]' % url)

        if self.disp == 1:
            
            # try:
            #     webbrowser.open (url)
            # except:
            #     pass

            return url

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

#
#    save to file is specified
#
        if self.status == 'ok':

            self.__save_to_file(self.filepath)
        
            if self.debug:
                logging.debug('')
                logging.debug('returned save_to_file:')
                logging.debug('self.status= [%s]' % self.status)
                logging.debug('self.msg= [%s]' % self.msg)
       
        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def target_list(self, **kwargs):
        """
        Returns a list of all unique targets currently in
        the database.
        
        Args:
            format (string): (optional) string specifying the output format ('html'|'csv'|'ipac'); the default is html
            filepath (string): (optional) full path where the file will be saved; if not provided,
                               a URL string to an HTML view of the table.

        Returns:
            string: URL to HTML table if filepath is not specified
        """
        
        if self.debug:
            logging.debug('')
            logging.debug('Enter database.target_list:')
        
        self.filepath = ''
        if (len(kwargs) > 0) and ('filepath' in kwargs.keys()):
            self.filepath = kwargs['filepath']

        self.format = 'html'
        if (len(kwargs) > 0) and ('format' in kwargs.keys()):
            self.format = kwargs['format']
            
        if len(self.filepath) > 0:
            self.disp = 0 
        else:
            self.disp = 1
  
        self.sql = 'select distinct target from FILES;'

        url = self.url + '&format=' + self.format + '&sql=' + self.sql

        if self.debug:
            logging.debug('')
            logging.debug('sql= %s' % self.sql)
            logging.debug('filepath= %s' % self.filepath)
            logging.debug('format= %s' % self.format)
            logging.debug('disp= %d' % self.disp)
            logging.debug('url= [%s]' % url)

        if self.disp == 1:
            
            # webbrowser.open (url)
            return url
          
        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

#
#    save to file is specified
#
        if self.status == 'ok':

            self.__save_to_file(self.filepath)
        
            if self.debug:
                logging.debug('')
                logging.debug('returned save_to_file:')
                logging.debug('self.status= [%s]' % self.status)
                logging.debug('self.msg= [%s]' % self.msg)
       
        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def target_info(self, target, **kwargs):
        """
        This method retrieves the database records for all data pertaining to a specific
        target.
        
        Args:
            target (string): target name
            format (string): (optional) string specifying the output format ('html'|'csv'|'ipac'); the default is html
            filepath (string): (optional) full path where the file will be saved; if not provided,
                               a URL string to an HTML view of the table.

        Returns:
            string: URL to HTML table if filepath is not specified
        """
       
        if self.debug:
            logging.debug('')
            logging.debug('Enter database.target_info: target= %s' % target)

        self.filepath = ''
        if (len(kwargs) > 0) and ('filepath' in kwargs.keys()):
            self.filepath = kwargs['filepath']

        self.format = 'html'
        if (len(kwargs) > 0) and ('format' in kwargs.keys()):
            self.format = kwargs['format']
            
        if len(self.filepath) > 0:
            self.disp = 0 
        else:
            self.disp = 1
        
        self.sql = "select * from FILES where target like '%" + target + "%';"

#        self.sql = "select * from FILES where upper(target) = upper('" + target + "');"

        url = self.url + '&format=' + self.format + '&sql=' + self.sql

        if self.debug:
            logging.debug('')
            logging.debug('sql= %s' % self.sql)
            logging.debug('filepath= %s' % self.filepath)
            logging.debug('format= %s' % self.format)
            logging.debug('disp= %d' % self.disp)
            logging.debug('url= [%s]' % url)

        if self.disp == 1:
            
            # webbrowser.open (url)
            return url

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

#
#    save to file is specified
#
        if self.status == 'ok':

            self.__save_to_file(self.filepath)
        
            if self.debug:
                logging.debug('')
                logging.debug('returned save_to_file:')
                logging.debug('self.status= [%s]' % self.status)
                logging.debug('self.msg= [%s]' % self.msg)
       
        retval = dict()
        retval['status'] = self.status
        retval['msg'] = self.msg

        return retval

    def sqlite(self, filepath):
        """
        Downloads the sqlite database file
        
        Args:
            filepath (string): path and filename to save the database file
                               on the disk.

        """
        
        self.filepath = filepath
        self.cmd = 'sqlite'

        if self.debug:
            logging.debug('')
            logging.debug('Enter database.sqlite: filepath = %s' % self.filepath)
       
        if len(self.filepath) == 0:
            
            self.status = 'error'
            self.msg = 'Input argument filepath is required.'
            
            retval = dict()
            retval['status'] = self.status
            retval['msg'] = self.msg

            return retval

        url = self.url + '&cmd=' + self.cmd

        if self.debug:
            logging.debug('')
            logging.debug('sqlite= %s' % self.sqlite)
            logging.debug('self.url= [%s]' % self.url)

        self.__submit_request(url)
        
        if self.debug:
            logging.debug('')
            logging.debug('returned submit_request:')
            logging.debug('self.status= [%s]' % self.status)
            logging.debug('self.msg= [%s]' % self.msg)

        if self.status == 'ok':

            if self.debug:
                logging.debug('')
            
            self.__save_to_file(self.filepath)
        
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
            logging.debug('sql= %s' % self.sql)
            logging.debug('sqlite= %s' % self.sqlite)
            logging.debug('format= %s' % self.format)
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
