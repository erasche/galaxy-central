"""
Support for integration with the Biostar application
"""

import hmac
import urlparse
import re
from unicodedata import normalize
from galaxy.web.base.controller import url_for
from galaxy.tools.errors import ErrorReporter

_punct_re = re.compile(r'[\t !"#$%&\'()*\-/<=>?@\[\\\]^_`{|},.]+')

DEFAULT_GALAXY_TAG = 'galaxy'

BIOSTAR_ACTIONS = {
    None: { 'url': lambda x: '', 'uses_payload': False },
    'new_post': { 'url': lambda x: 'p/new/post/', 'uses_payload': True },
    'show_tags': { 'url': lambda x: 't/%s/' % ( "+".join( ( x.get( 'tag_val' ) or DEFAULT_GALAXY_TAG ).split( ',' ) ) ), 'uses_payload':False },
    'log_out': { 'url': lambda x: 'site/logout/', 'uses_payload': False }
}

DEFAULT_BIOSTAR_COOKIE_AGE = 1

def biostar_enabled( app ):
    return bool( app.config.biostar_url )

# Slugifying from Armin Ronacher (http://flask.pocoo.org/snippets/5/)
def slugify(text, delim=u'-'):
    """Generates an slightly worse ASCII-only slug."""
    if not isinstance( text, unicode ):
        text = unicode( text )
    result = []
    for word in _punct_re.split(text.lower()):
        word = normalize('NFKD', word).encode('ascii', 'ignore')
        if word:
            result.append(word)
    return unicode(delim.join(result))

# Default values for new posts to Biostar
DEFAULT_PAYLOAD = {
    'title': '',
    'tag_val': DEFAULT_GALAXY_TAG,
    'content': '',
}

def get_biostar_url( app, payload=None, biostar_action=None ):
    # Ensure biostar integration is enabled
    if not biostar_enabled( app ):
        raise Exception( "Biostar integration is not enabled" )
    if biostar_action not in BIOSTAR_ACTIONS:
        raise Exception( "Invalid action specified (%s)." % ( biostar_action ) )
    biostar_action = BIOSTAR_ACTIONS[ biostar_action ]
    # Start building up the payload
    payload = payload or {}
    payload = dict( DEFAULT_PAYLOAD, **payload )
    #generate url, can parse payload info
    url = str( urlparse.urljoin( app.config.biostar_url, biostar_action.get( 'url' )( payload ) ) )
    if not biostar_action.get( 'uses_payload' ):
        payload = {}
    url = url_for( url, **payload )
    return url

def tag_for_tool( tool ):
    """
    Generate a reasonable biostar tag for a tool.
    """
    #Biostar can now handle tags with spaces, do we want to generate tags differently now?
    return slugify( tool.name, delim='-' )

def populate_tag_payload( payload=None, tool=None ):
    if payload is None:
        payload = {}
    tag_val = [ DEFAULT_GALAXY_TAG ]
    if tool:
        tag_val.append( tag_for_tool( tool ) )
    payload[ 'tag_val' ] =  ','.join( tag_val )
    return payload

def populate_tool_payload( payload=None, tool=None ):
    payload = populate_tag_payload( payload=payload, tool=tool )
    payload[ 'title' ] = 'Need help with "%s" tool' % ( tool.name )
    payload[ 'content' ] = '<br /><hr /><p>Tool name: %s</br>Tool version: %s</br>Tool ID: %s</p>' % ( tool.name, tool.version, tool.id )
    return payload

def determine_cookie_domain( galaxy_hostname, biostar_hostname ):
    if galaxy_hostname == biostar_hostname:
        return galaxy_hostname
    
    sub_biostar_hostname = biostar_hostname.split( '.', 1 )[-1]
    if sub_biostar_hostname == galaxy_hostname:
        return galaxy_hostname
    
    sub_galaxy_hostname = galaxy_hostname.split( '.', 1 )[-1]
    if sub_biostar_hostname == sub_galaxy_hostname:
        return sub_galaxy_hostname
    
    return galaxy_hostname

def create_cookie( trans, key_name, key, email, age=DEFAULT_BIOSTAR_COOKIE_AGE ):
    digest = hmac.new( key, email ).hexdigest()
    value = "%s:%s" % (email, digest)
    trans.set_cookie( value, name=key_name, path='/', age=age, version='1' )
    #We need to explicitly set the domain here, in order to allow for biostar in a subdomain to work
    galaxy_hostname = urlparse.urlsplit( url_for( '/', qualified=True ) ).hostname
    biostar_hostname = urlparse.urlsplit( trans.app.config.biostar_url ).hostname
    trans.response.cookies[ key_name ][ 'domain' ] = determine_cookie_domain( galaxy_hostname, biostar_hostname )

def delete_cookie( trans, key_name ):
    #Set expiration of Cookie to time in past, to cause browser to delete
    if key_name in trans.request.cookies:
        create_cookie( trans, trans.app.config.biostar_key_name, '', '', age=-90 )

def biostar_logged_in( trans ):
    if biostar_enabled( trans.app ):
        if trans.app.config.biostar_key_name in trans.request.cookies:
            return True
    return False

def biostar_logout( trans ):
    if biostar_enabled( trans.app ):
        delete_cookie( trans, trans.app.config.biostar_key_name )
        return get_biostar_url( trans.app, biostar_action='log_out' )
    return None

class BiostarErrorReporter( ErrorReporter ):
    def _send_report( self, user, email=None, message=None, **kwd ):
        assert biostar_enabled( self.app ), ValueError( "Biostar is not configured for this galaxy instance" )
        assert self._can_access_dataset( user ), Exception( "You are not allowed to access this dataset." )
        tool_version_select_field, tools, tool = \
            self.app.toolbox.get_tool_components( self.tool_id, tool_version=None, get_loaded_tools_by_lineage=False, set_selected=True )
        payload = { 'title': 'Bug report on "%s" tool' % ( tool.name ), 'content': self.report.replace( '\n', '<br />' ), 'tag_val':slugify( 'bug report' ) }
        #Get footer for email from here
        payload2 = populate_tool_payload( tool=tool )
        if 'content' in payload2:
            payload[ 'content' ] = "%s<br />%s" % ( payload['content'], payload2['content'] )
        if 'tag_val' in payload2:
            payload[ 'tag_val' ] = ','.join( [ payload2[ 'tag_val' ], payload[ 'tag_val' ] ] )
        return payload