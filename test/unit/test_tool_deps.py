import tempfile
import os.path
from os import makedirs, symlink
import galaxy.tools.deps


def touch( fname, data=None ):
    f = open( fname, 'w' )
    if data:
        f.write( data )
    f.close()


def test_tool_dependencies():

    # Setup directories
    base_path = tempfile.mkdtemp()
    # mkdir( base_path )
    for name, version, sub in [ ( "dep1", "1.0", "env.sh" ), ( "dep1", "2.0", "bin" ), ( "dep2", "1.0", None ) ]:
        if sub == "bin":
            p = os.path.join( base_path, name, version, "bin" )
        else:
            p = os.path.join( base_path, name, version )
        try:
            makedirs( p )
        except:
            pass
        if sub == "env.sh":
            touch( os.path.join( p, "env.sh" ) )

    dm = galaxy.tools.deps.DependencyManager( [ base_path ] )

    d1_script, d1_path, d1_version = dm.find_dep( "dep1", "1.0" )
    assert d1_script == os.path.join( base_path, 'dep1', '1.0', 'env.sh' )
    assert d1_path == os.path.join( base_path, 'dep1', '1.0' )
    assert d1_version == "1.0"
    d2_script, d2_path, d2_version = dm.find_dep( "dep1", "2.0" )
    assert d2_script == None
    assert d2_path == os.path.join( base_path, 'dep1', '2.0' )
    assert d2_version == "2.0"

    ## Test default versions
    symlink( os.path.join( base_path, 'dep1', '2.0'), os.path.join( base_path, 'dep1', 'default' ) )
    default_script, default_path, default_version = dm.find_dep( "dep1", None )
    assert default_version == "2.0"

    ## Test default will not be fallen back upon by default
    default_script, default_path, default_version = dm.find_dep( "dep1", "2.1" )
    assert default_script == None
    assert default_version == None

    ## Test default will be fallen back upon if allow_default is flagged
    default_script, default_path, default_version = dm.find_dep( "dep1", "2.1", allow_default=True )
    assert default_version == "2.0"
