"""
Drive the underlying IDL code
"""

import logging
import json

import requests
import http.cookiejar


class Idldriver:
    """
    The principle processing of the HIRES PRV pipeline is done by a
    set of IDL scripts developed over several decades.  This processing
    is quite intensive, takes a long time, and is run in the
    background.

    The ``hiresprv.idldriver.Idldriver`` class provides functionality that allows
    the user to submit reduction scripts that
    are parsed and sent to the appropriate IDL functions on the server.

    The idldriver class intialization checks for cookie indicating
    a previous login that connects to the user to a PRV pipeline
    workspace.  This workspace is populated with data from the KOA
    Archive using the :class:`hiresprv.archive.Archive` class methods.

    Args:
        cookiepath: a full path to cookie file saved from :func:`hiresprv.auth.login()`

    """

    cookiepath = ''
    script = ''
    scriptfile = ''
   
    workspace = ''

    status = ''
    msg = ''

    debug = 0
    debugfname = '' 

    def __init__(self, cookiepath, **kwargs):
        self.cookiepath = cookiepath

        if 'debugfile' in kwargs:
            self.debugfname = kwargs.get('debugfile')

        if len(self.debugfname) > 0:
    
            self.debug = 1
            logging.basicConfig(filename=self.debugfname, level=logging.DEBUG)

            # TODO: fdebug unused
            with open(self.debugfname, 'w') as fdebug:
                pass
    
        if self.debug:
            logging.debug('')
            logging.debug('DEBUG> Enter idldriver.init:')
            logging.debug('cookiepath= [%s]' % cookiepath)
            logging.debug('debug= [%d] debugfname= [%s]' % (self.debug, self.debugfname))
      
        if len(cookiepath) == 0:
            print('Required input cookie not found.')
            return
        
#
#  load cookie
#
        self.cookiejar = http.cookiejar.MozillaCookieJar(self.cookiepath)
        
        self.cookie = '' 
        try:
            self.cookiejar.load(ignore_discard=True, ignore_expires=True)

            for cookie in self.cookiejar:

                if cookie.name == 'HIPRV':
                    self.cookie = cookie
        # TODO: bare except clause
        except:
            pass

            if self.debug:
                logging.debug('')
                logging.debug('load cookie exception')

        if self.cookie is not None:

            if self.debug:
                logging.debug('')
                logging.debug('cookie= %s' % self.cookie)
                logging.debug('cookiename= %s' % self.cookie.name)
                logging.debug('cookievalue= %s' % self.cookie.value)
                logging.debug('cookiedomain= %s' % self.cookie.domain)

        return

    def run_script(self, script):
        """
        This method is given a script of steps to
        run on the data in the user's workspace.  These steps include creating 
        a template spectrum for a sky target, reducing specific radial
        velocity measurement(s) using such a template, and creating an RV curve
        from a set of reduced RV measurements.

        Args:
            script (string): script containing processing steps separated by newlines

        Example:
            >>> from hiresprv.idldriver import Idldriver
            >>> idl = Idldriver('prv.cookies')
            >>> rtn = idl.run_script(\"\"\"
            template 185144 20091231
            rv 185144 r20091231.72
            rv 185144 r20091231.73
            rv 185144 r20091231.74
            rv 185144 r20150606.145
            rv 185144 r20150606.146
            rv 185144 r20150606.147
            rvcurve 185144\"\"\")
        """

        self.script = script 
        
        if self.debug:
            logging.debug('')
            logging.debug('Enter idldriver.run_script:')
            logging.debug('script= %s' % self.script)
    
        self.__submitScript()

        if self.debug:
            logging.debug('')
            logging.debug('returned submitScript: status= [%s]' % self.status)
            logging.debug('returned submitScript: msg= [%s]' % self.msg)
       
        print('status= %s' % self.status)
        print('msg= %s' % self.msg)

        return

    def run_scriptfile(self, scriptfile):
        """
        Same as :meth:`hiresprv.idldriver.Idldriver.run_script()` except takes a path to a file
        containing the script lines.

        Args:
            scriptfile (string): path to plain text file that will be read as a continuous string
                                 and used as input to the :meth:`hiresprv.idldriver.Idldriver.run_script()` method.
        """

        self.scriptfile = scriptfile 
    
        if self.debug:
            logging.debug('')
            logging.debug('Enter idldriver.run_scriptfile:')
            logging.debug('scriptfile= %s' % self.scriptfile)
    
#
#  read file into a script
#
        with open(scriptfile, 'r') as fp:
            
            self.script = fp.read()
    
        if self.debug:
            logging.debug('')
            logging.debug('script read from file')
            logging.debug('script= %s' % self.script)
    
        self.__submitScript()

        if self.debug:
            logging.debug('')
            logging.debug('returned submitScript: status= [%s]' % self.status)
            logging.debug('returned submitScript: msg= [%s]' % self.msg)
       
        print('status= %s' % self.status)
        print('msg= %s' % self.msg)

        return

    # TODO: Technically shouldn't use camel case in a function or method name
    def __submitScript(self):
   
        debug = 0 

        if debug:
            logging.debug('')
            logging.debug('Enter idldriver.__submitScript')
            logging.debug('script= %s' % self.script)

        scriptdict = {'script': self.script}
    
        if debug:
            logging.debug('')
            logging.debug('format script to dictionary, scriptdict=')
            logging.debug(scriptdict)

#
#   construct URL 
#
        url = "http://hiresprv.ipac.caltech.edu/cgi-bin/idlDriver/nph-idlDriver"

        if debug:
            logging.debug('')
            logging.debug('url= %s' % url)

        self.response = requests.post(url, files=scriptdict, cookies=self.cookiejar)

        if debug:
            logging.debug('')
            logging.debug('response: %s' % self.response.text)
        
        jsonstr = json.loads(self.response.text)

        if debug:
            logging.debug('')
            logging.debug('jsonstr: %s' % jsonstr)

        self.status = jsonstr["status"]
        self.msg = jsonstr["msg"]

        if debug:
            logging.debug('')
            logging.debug('status: %s' % self.status)
            logging.debug('msg: %s' % self.msg)

        retval = dict()

        retval["status"] = self.status
        retval["msg"] = self.msg

        return retval
