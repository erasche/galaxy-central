import galaxy.model
from galaxy.model.orm import *
from base.twilltestcase import *

not_logged_in_as_admin_security_msg = 'You must be logged in as an administrator to access this feature.'
logged_in_as_admin_security_msg = 'You must be an administrator to access this feature.'
not_logged_in_security_msg = 'You must be logged in to create/submit sequencing requests'
form_one_name = "Request Form"
form_two_name = "Sample Form"
request_type_name = 'Test Requestype'
sample_states = [  ( 'New', 'Sample entered into the system' ), 
                   ( 'Received', 'Sample tube received' ), 
                   ( 'Done', 'Sequence run complete' ) ]
address1 = dict(  short_desc="Office",
                  name="James Bond",
                  institution="MI6" ,
                  address1="MI6 Headquaters",
                  address2="",
                  city="London",
                  state="London",
                  postal_code="007",
                  country="United Kingdom",
                  phone="007-007-0007" )


def get_latest_form(form_name):
    fdc_list = galaxy.model.FormDefinitionCurrent.filter( galaxy.model.FormDefinitionCurrent.table.c.deleted==False )\
                                        .order_by( galaxy.model.FormDefinitionCurrent.table.c.create_time.desc() )
    for fdc in fdc_list:
        if form_name == fdc.latest_form.name:
            return fdc.latest_form
    return None


class TestFormsAndRequests( TwillTestCase ):
    def test_000_create_form( self ):
        """Testing creating a new form and editing it"""
        self.logout()
        self.login( email='test@bx.psu.edu' )
        # create a form
        global form_one_name
        name = form_one_name
        desc = "This is Form One's description"
        self.create_form( name=name, desc=desc )
        self.home()
        self.visit_page( 'forms/manage' )
        self.check_page_for_string( name )
        self.check_page_for_string( desc )
        # Get the form_definition object for later tests
        form_one = galaxy.model.FormDefinition.filter( and_( galaxy.model.FormDefinition.table.c.name==name,
                                                             galaxy.model.FormDefinition.table.c.desc==desc ) ).all()[-1]
        assert form_one is not None, 'Problem retrieving form named "%s" from the database' % name
        # edit form & add few more fields
        new_name = "Request Form (Renamed)"
        new_desc = "This is Form One's Re-described"
        self.edit_form( form_one.id, form_one.name, new_form_name=new_name, new_form_desc=new_desc )
        self.home()
        self.visit_page( 'forms/manage' )
        self.check_page_for_string( new_name )
        self.check_page_for_string( new_desc )
        form_one_name = new_name
    def test_005_add_form_fields( self ):
        """Testing adding fields to a form definition"""
        fields = [dict(name='Test field name one',
                       desc='Test field description one',
                       type='TextField',
                       required='required'),
                  dict(name='Test field name two',
                       desc='Test field description two',
                       type='AddressField',
                       required='optional')]
        form_one = get_latest_form(form_one_name)
        self.form_add_field(form_one.id, form_one.name, field_index=len(form_one.fields), fields=fields)
        form_one_latest = get_latest_form(form_one_name)        
        assert len(form_one_latest.fields) == len(form_one.fields)+len(fields)
#This following test has been commented out as it is causing:
#TwillException: multiple matches to "remove_button"     
#    def test_010_remove_form_fields( self ):
#        """Testing removing fields from a form definition"""
#        form_one = get_latest_form(form_one_name)
#        self.form_remove_field( form_one.id, form_one.name, 'Test field name one' )
#        form_one_latest = get_latest_form(form_one_name)
#        assert len(form_one_latest.fields) == len(form_one.fields)-1
    def test_015_create_sample_form( self ):
        """Testing creating another form (for samples)"""
        global form_two_name
        name = form_two_name
        desc = "This is Form One's description"
        self.create_form( name=name, desc=desc )
        self.home()
        self.visit_page( 'forms/manage' )
        self.check_page_for_string( name )
        self.check_page_for_string( desc )
    def test_020_create_request_type( self ):
        """Testing creating a new requestype"""
        request_form = get_latest_form(form_one_name)
        sample_form = get_latest_form(form_two_name)
        self.create_request_type(request_type_name, "test request type", 
                                 str(request_form.id), str(sample_form.id), sample_states )
        global request_type
        request_type = galaxy.model.RequestType.filter( and_( galaxy.model.RequestType.table.c.name==request_type_name ) ).all()[-1]
        assert request_type is not None, 'Problem retrieving request type named "%s" from the database' % request_type_name
    def test_025_create_address( self ):
        """Testing address creation"""
        #self.create_address( user_address1 )
        #self.check_page_for_string( 'Address <b>%s</b> has been added' % user_address1[ 'short_desc' ] )
        ## TODO: FIX HACK
        ## the user address creation should be done as a test. 
        global user_address
        user_address = galaxy.model.UserAddress()
        user_address.user = galaxy.model.User.filter( galaxy.model.User.table.c.email=='test@bx.psu.edu' ).first()
        user_address.desc = address1[ 'short_desc' ]
        user_address.name = address1[ 'name' ]
        user_address.institution = address1[ 'institution' ]
        user_address.address = address1[ 'address1' ]+' '+address1[ 'address2' ]
        user_address.city = address1[ 'city' ]
        user_address.state = address1[ 'state' ]
        user_address.postal_code = address1[ 'postal_code' ]
        user_address.country = address1[ 'country' ]
        user_address.phone = address1[ 'phone' ]
        user_address.flush()
        user_address.user.refresh()
    def test_030_create_request( self ):
        """Testing creating and submitting a request"""
        # first create a library for the request so that it can be submitted later
        lib_name = 'TestLib001'
        self.create_library( lib_name, '' )
        self.visit_page( 'admin/browse_libraries' )
        self.check_page_for_string( lib_name )
        # Get the library object for later tests
        global library_one
        library_one = galaxy.model.Library.filter( and_( galaxy.model.Library.table.c.name==lib_name,
                                                         galaxy.model.Library.table.c.deleted==False ) ).first()
        assert library_one is not None, 'Problem retrieving library named "%s" from the database' % lib_name
        global admin_user
        admin_user = galaxy.model.User.filter( galaxy.model.User.table.c.email=='test@bx.psu.edu' ).first()
        assert admin_user is not None, 'Problem retrieving user with email "test@bx.psu.edu" from the database'
        # Get the admin user's private role for later use
        global admin_user_private_role
        admin_user_private_role = None
        for role in admin_user.all_roles():
            if role.name == admin_user.email and role.description == 'Private Role for %s' % admin_user.email:
                admin_user_private_role = role
                break
        if not admin_user_private_role:
            raise AssertionError( "Private role not found for user '%s'" % admin_user.email )
        # Set permissions on the library, sort for later testing
        permissions_in = [ k for k, v in galaxy.model.Library.permitted_actions.items() ]
        permissions_out = []
        # Role one members are: admin_user, regular_user1, regular_user3.  Each of these users will be permitted to
        # LIBRARY_ADD, LIBRARY_MODIFY, LIBRARY_MANAGE for library items.
        self.set_library_permissions( str( library_one.id ), library_one.name, str( admin_user_private_role.id ), permissions_in, permissions_out )
        # set field values
        fields = ['field one value', 'field two value', str(user_address.id)] 
        # create the request
        request_name, request_desc = 'Request One', 'Request One Description'
        self.create_request(request_type.id, request_name, request_desc, library_one.id, fields)
        self.check_page_for_string( request_name )
        self.check_page_for_string( request_desc )
        global request_one
        request_one = galaxy.model.Request.filter( and_( galaxy.model.Request.table.c.name==request_name,
                                                         galaxy.model.Request.table.c.deleted==False ) ).first()        
        # check if the request's state is now set to 'unsubmitted'
        assert request_one.state is not request_one.states.UNSUBMITTED, "The state of the request '%s' should be set to '%s'" % ( request_one.name, request_one.states.UNSUBMITTED )

        # sample fields
        samples = [ ( 'Sample One', [ 'S1 Field 0 Value' ] ),
                    ( 'Sample Two', [ 'S2 Field 0 Value' ] ) ]
        # add samples to this request
        self.add_samples( request_one.id, request_one.name, samples )
        for sample_name, fields in samples:
            self.check_page_for_string( sample_name )
            self.check_page_for_string( 'Unsubmitted' )
            for field_value in fields:
                self.check_page_for_string( field_value )
        # submit the request
        self.submit_request( request_one.id, request_one.name )
        request_one.refresh()
        # check if the request's state is now set to 'submitted'
        assert request_one.state is not request_one.states.SUBMITTED, "The state of the request '%s' should be set to '%s'" % ( request_one.name, request_one.states.SUBMITTED )
    def test_035_request_lifecycle( self ):
        """Testing request lifecycle as it goes through all the states"""
        # goto admin manage requests page
        self.home()
        self.visit_page( 'requests_admin/list' )
        self.check_page_for_string( request_one.name )
        self.visit_url( "%s/requests_admin/list?sort=-create_time&operation=show_request&id=%s" \
                        % ( self.url, self.security.encode_id( request_one.id ) ))
        self.check_page_for_string( 'Sequencing Request "%s"' % request_one.name )
        # set bar codes for the samples
        bar_codes = [ '1234567890', '0987654321' ]
        self.add_bar_codes( request_one.id, request_one.name, bar_codes )
        self.check_page_for_string( 'Bar codes has been saved for this request' )
        # change the states of all the samples of this request
        for sample in request_one.samples:
            self.change_sample_state( sample.name, sample.id, request_type.states[1].id )
            self.check_page_for_string( request_type.states[1].name )
            self.check_page_for_string( request_type.states[1].desc )
            self.change_sample_state( sample.name, sample.id, request_type.states[2].id )
            self.check_page_for_string( request_type.states[2].name )
            self.check_page_for_string( request_type.states[2].desc )
        self.home()
        request_one.refresh()
        # check if the request's state is now set to 'complete'
        assert request_one.state is not request_one.states.COMPLETE, "The state of the request '%s' should be set to '%s'" % ( request_one.name, request_one.states.COMPLETE )

        
        
        
        
        
        