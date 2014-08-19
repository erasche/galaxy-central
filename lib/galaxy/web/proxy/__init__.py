import logging
import os
import json

from .filelock import FileLock
from galaxy.util import sockets
from galaxy.util.lazy_process import LazyProcess, NoOpLazyProcess

log = logging.getLogger( __name__ )


class ProxyManager(object):

    def __init__( self, config ):
        for option in [ "proxy_session_map", "manage_dynamic_proxy", "dynamic_proxy_bind_port", "dynamic_proxy_bind_ip" ]:
            setattr( self, option, getattr( config, option ) )
        self.launch_by = "node"  # TODO: Support docker
        if self.manage_dynamic_proxy:
            self.lazy_process = self.__setup_lazy_process()
        else:
            self.lazy_process = NoOpLazyProcess()

    def shutdown( self ):
        self.lazy_process.shutdown()

    def setup_proxy( self, trans, host="localhost", port=None ):
        if self.manage_dynamic_proxy:
            log.info("Starting dynaic process")
            self.lazy_process.start_process()

        if port is None:
            port = sockets.unused_port()
            log.info("Obtained unused port %d" % port)

        key = "%s:%s" % (host, port)
        secure_id = trans.get_cookie( name="galaxysession" )
        # TODO: Support other IPC mechanisms than this file hack.
        log.info("Attempting file lock")
        with FileLock( self.proxy_session_map ):
            if not os.path.exists( self.proxy_session_map ):
                open( self.proxy_session_map, "w" ).write( "{}" )
            json_data = open( self.proxy_session_map, "r" ).read()
            session_map = json.loads( json_data )
            to_remove = []
            for k, value in session_map.items():
                if value == secure_id:
                    to_remove.append( k )
            for k in to_remove:
                del session_map[ k ]
            session_map[ key ] = secure_id
            new_json_data = json.dumps( session_map )
            open( self.proxy_session_map, "w" ).write( new_json_data )
        log.info("proxy session map updated")
        host = trans.request.host
        if ':' in host:
            host = host[0:host.index(':')]
        scheme = trans.request.scheme
        proxy_url = '%s://%s:%d' % (scheme, host, self.dynamic_proxy_bind_port)
        return {
            'proxy_url': proxy_url,
            'proxied_port': port,
            'proxied_host': host,
        }

    def __setup_lazy_process( self ):
        args = [
            "--sessions", self.proxy_session_map,
            "--ip", self.dynamic_proxy_bind_ip,
            "--port", str(self.dynamic_proxy_bind_port),
        ]
        if self.launch_by == "node":
            # TODO launch [node, path_to_application, **args]
            parent_directory = os.path.dirname( __file__ )
            path_to_application = os.path.join( parent_directory, "js", "lib", "main.js" )
            command = [ path_to_application ] + args
        elif self.launch_by == "docker":
            raise NotImplementedError()
            # TODO: When managing dynamic proxy, allow option to do so via Docker instead
            # of direct node.
        else:
            raise NotImplementedError()

        return LazyProcess( command )
