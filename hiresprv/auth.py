"""
The ``hiresprv.login`` module initializes an account on the PRV pipeline
server for reduction of radial velocity data.
"""

import getpass
import logging
import json

import urllib
import http.cookiejar


def login(cookiepath):
    """
    The login function prompts for an authorized KOA user ID and password, 
    then sets up a workspace (or connects to an existing workspace) on 
    the PRV pipeline server for that user.  

    Args:
        cookiepath (string): a file path provided by the user to save
                             returned cookie which is needed for the 
                             subsequent PRV operations.

    Example:
        >>> import hiresprv.auth
        >>> hiresprv.auth.login(cookiepath)
        # program will prompt for userid and password
    """
    # TODO: Many of these variables are not used
    userid = ''
    password = ''

    url = ''
    response = ''
    jsondata = ''

    status = ''
    msg = ''

    debug = 0 
    debugfile = ''

    if len(debugfile) > 0:
            
        debug = 1
        logging.basicConfig(filename=debugfile, level=logging.DEBUG)

        # TODO: Do we need this?
        with open(debugfile, 'w') as fdebug:
            pass

    if debug:
        logging.debug('')
        logging.debug('Enter Login.init:')
        logging.debug('cookiepath= %s' % cookiepath)
   
#
#    get userid and password via keyboard input
#
    userid = input("KOA userid: ")
    if debug:    
        logging.debug('')
        logging.debug('userid= %s' % userid)

    password = getpass.getpass("KOA Password: ")
    if debug:    
        logging.debug('')
        logging.debug('password= %s' % password)

    password = urllib.parse.quote(password)
    if debug:    
        logging.debug('')
        logging.debug('after urlencode: password= %s' % password)

    cookiejar = http.cookiejar.MozillaCookieJar(cookiepath)
        
#
#  url for login
#
    url = 'http://hiresprv.ipac.caltech.edu/cgi-bin/PrvPython/nph-prvLogin.py?'
    url = url + 'userid=' + userid + '&' 
    url = url + 'password=' + password 

    if debug:    
        logging.debug('')
        logging.debug('url= %s' % url)

#
#    build url_opener
#
    # TODO: unused variable
    data = None

    try:
        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cookiejar))
            
        if debug:
            logging.debug('here1')

        urllib.request.install_opener(opener)
        
        if debug:
            logging.debug('opener installed')

        request = urllib.request.Request(url)
            
        if debug:
            logging.debug('here2')

        cookiejar.add_cookie_header(request)
            
        if debug:
            logging.debug('cookie added')

        response = opener.open(request)

        if debug:
            logging.debug('response= ')
            logging.debug(response)

    except urllib.error.URLError as e:
        
        status = 'error'
        msg = 'URLError= ' + e.reason    

        if debug:
            logging.debug('e.code= ' + e.code + ' e.reason= ' + e.reason)
            logging.debug('URLError: msg= %s' % msg)
        
    except urllib.error.HTTPError as e:
            
        status = 'error'
        msg = 'HTTPError= ' + e.reason
            
        if debug:
            logging.debug('HTTPError: msg= %s' % msg)

    # TODO: Is there a more specific exception we should catch here?
    # I see that this is the last of several possible exceptions so
    # probaby OK to let slide here.
    except Exception:
           
        status = 'error'
        msg = 'URL exception'

        if debug:
            logging.debug('other exceptions')
             
    if status == 'error':
        msg = 'Failed to login: %s' % msg
        print(msg)
        return

    if debug:
        logging.debug('got here: response= ')
        logging.debug(response)

#
#    check content-type in response header: 
#    if it is 'application/json', then it is an error message
#
    if debug:
        logging.debug('response.info=')
        logging.debug(response.info())

    infostr = dict(response.info())

    if debug:
        logging.debug('infostr= %s' % infostr)
      
    contenttype = infostr.get('Content-type')

    if debug:
        logging.debug('contenttype= %s ' % contenttype)
       
    data = response.read()
    sdata = data.decode("utf-8")
   
    jsondata = json.loads(sdata)
   
    if debug:
        logging.debug('here2: data= ')
        logging.debug(data)
        logging.debug('sdata= %s' % sdata)
        logging.debug('jsondata= ')
        logging.debug(jsondata)

    for key, val in jsondata.items():
                
        if debug: 
            logging.debug('key= %s val= %s' % (key, val))
        
        if key == 'status':
            status = val
                
        if key == 'msg':
            msg = val

    if debug:
        logging.debug('status= %s msg= %s' % (status, msg))

    if status == 'ok':
        cookiejar.save(cookiepath, ignore_discard=True)
        if debug:
            logging.debug('cookiejar saved to hirescookietxt')
        
        msg = 'Successful login as %s' % userid
    
    else:       
        msg = 'Failed to login: %s' % msg

    if debug:
        logging.debug('')
        logging.debug('status= %s' % status)
        logging.debug('msg= %s' % msg)
 
    print(msg)

    return
