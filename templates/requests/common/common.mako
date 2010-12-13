<%namespace file="/requests/common/sample_state.mako" import="render_sample_state" />

<%def name="javascripts()">
   ${self.common_javascripts()}
</%def>

<%def name="common_javascripts()">
    <script type="text/javascript">
        function showContent(vThis)
        {
            // http://www.javascriptjunkie.com
            // alert(vSibling.className + " " + vDef_Key);
            vParent = vThis.parentNode;
            vSibling = vParent.nextSibling;
            while (vSibling.nodeType==3) { 
                // Fix for Mozilla/FireFox Empty Space becomes a TextNode or Something
                vSibling = vSibling.nextSibling;
            };
            if(vSibling.style.display == "none")
            {
                vThis.src="/static/images/fugue/toggle.png";
                vThis.alt = "Hide";
                vSibling.style.display = "block";
            } else {
                vSibling.style.display = "none";
                vThis.src="/static/images/fugue/toggle-expand.png";
                vThis.alt = "Show";
            }
            return;
        }
        $(document).ready(function(){
            //hide the all of the element with class msg_body
            $(".msg_body").hide();
            //toggle the component with class msg_body
            $(".msg_head").click(function(){
                $(this).next(".msg_body").slideToggle(0);
            });
        });

        function checkAllFields()
        {
            var chkAll = document.getElementById('checkAll');
            var checks = document.getElementsByTagName('input');
            var boxLength = checks.length;
            var allChecked = false;
            var totalChecked = 0;
            if ( chkAll.checked == true )
            {
                for ( i=0; i < boxLength; i++ )
                {
                    if ( checks[i].name.indexOf( 'select_sample_' ) != -1)
                    {
                       checks[i].checked = true;
                    }
                }
            }
            else
            {
                for ( i=0; i < boxLength; i++ )
                {
                    if ( checks[i].name.indexOf( 'select_sample_' ) != -1)
                    {
                       checks[i].checked = false
                    }
                }
            }
        }

        // Sample State Updater
        // 
        // Looks for changes in sample states using an async request. Keeps
        // calling itself (via setTimeout) until all samples are in a terminal
        // state.
        var sample_state_updater = function ( sample_states ) {
            // Check if there are any items left to track
            var empty = true;
            for ( i in sample_states ) {
                empty = false;
                break;
            }
            if ( ! empty ) {
                setTimeout( function() { sample_state_updater_callback( sample_states ) }, 1000 );
            }
        };
        var sample_state_updater_callback = function ( sample_states ) {
            // Build request data
            var ids = []
            var states = []
            $.each( sample_states, function ( id, state ) {
                ids.push( id );
                states.push( state );
            });
            // Make ajax call
            $.ajax( {
                type: "POST",
                url: "${h.url_for( controller='requests_common', action='sample_state_updates' )}",
                dataType: "json",
                data: { ids: ids.join( "," ), states: states.join( "," ) },
                success : function ( data ) {
                    $.each( data, function( id, val ) {
                        // Replace HTML
                        var cell1 = $("#sampleState-" + id);
                        cell1.html( val.html_state );
                        sample_states[ parseInt( id ) ] = val.state;
                    });
                    sample_state_updater( sample_states ); 
                },
                error: function() {
                    // Just retry, like the old method, should try to be smarter
                    sample_state_updater( sample_states );
                }
            });
        };
        
        
        // Sample Dataset Transfer Status Updater
        //
        // It is used to update the transfer status on Manage Datasets page for a sample 
        // of a sequencing request
        // Looks for changes in sample dataset transfer status using an async request. Keeps
        // calling itself (via setTimeout) until transfer_status is complete
        var dataset_transfer_status_updater = function ( dataset_transfer_status_list ) {
            // Check if there are any items left to track
            var empty = true;
            for ( i in dataset_transfer_status_list ) {
                empty = false;
                break;
            }
            if ( ! empty ) {
                setTimeout( function() { dataset_transfer_status_updater_callback( dataset_transfer_status_list ) }, 1000 );
            }
        };
        var dataset_transfer_status_updater_callback = function ( dataset_transfer_status_list ) {
            // Build request data
            var ids = []
            var transfer_status_list = []
            $.each( dataset_transfer_status_list, function ( id, dataset_transfer_status ) {
                ids.push( id );
                transfer_status_list.push( dataset_transfer_status );
            });
            // Make ajax call
            $.ajax( {
                type: "POST",
                url: "${h.url_for( controller='requests_common', action='dataset_transfer_status_updates' )}",
                dataType: "json",
                data: { ids: ids.join( "," ), transfer_status_list: transfer_status_list.join( "," ) },
                success : function ( data ) {
                    $.each( data, function( id, val ) {
                        // Replace HTML
                        var cell1 = $("#datasetTransferStatus-" + id);
                        cell1.html( val.html_status );
                        dataset_transfer_status_list[ id ] = val.status;
                    });
                    dataset_transfer_status_updater( dataset_transfer_status_list ); 
                },
                error: function() {
                    // Just retry, like the old method, should try to be smarter
                    dataset_transfer_status_updater( dataset_transfer_status_list ); 
                }
            });
        };
    </script>
</%def>

<%def name="transfer_status_updater()">
    <% 
        can_update = False
        if query.count():
            # Get the first sample dataset to get to the parent sample
            sample_dataset = query[0]
            sample = sample_dataset.sample
            is_complete = sample.request.is_complete
            is_submitted = sample.request.is_submitted
            can_update = ( is_complete or is_submitted ) and sample.inprogress_dataset_files
    %>
    %if can_update:
		<script type="text/javascript">
		    // Sample dataset transfer status updater
		    dataset_transfer_status_updater( {${ ",".join( [ '"%s" : "%s"' % ( trans.security.encode_id( sd.id ), sd.status ) for sd in query ] ) }});
		</script>
	%endif
</%def>

<%def name="render_editable_sample_row( cntrller, request, sample, sample_widget_index, sample_widget, encoded_selected_sample_ids )">
    <%
        trans.sa_session.refresh( request )
        is_admin = cntrller == 'requests_admin' and trans.user_is_admin()
        is_rejected = request.is_rejected
        is_complete = request.is_complete
        is_submitted = request.is_submitted
        is_unsubmitted = request.is_unsubmitted
        if sample:
            can_delete_samples = editing_samples and request.samples and ( ( is_admin and not is_complete ) or is_unsubmitted )
            display_checkboxes = editing_samples and ( is_complete or is_rejected or is_submitted )
            display_datasets = request.samples and ( is_complete or is_submitted )
        else:
            can_delete_samples = False
            display_checkboxes = False
            display_datasets = False
        display_bar_code = request.samples and ( is_complete or is_rejected or is_submitted )
    %>
    <%
        if display_checkboxes and trans.security.encode_id( sample.id ) in encoded_selected_sample_ids:
            checked_str = "checked"
        else:
            checked_str = ""
    %>
    %if display_checkboxes:
        <td><input type="checkbox" name=select_sample_${sample.id} id="sample_checkbox" value="true" ${checked_str}/><input type="hidden" name=select_sample_${sample.id} id="sample_checkbox" value="true"/></td>
    %endif
    <td valign="top">
        <input type="text" name="sample_${sample_widget_index}_name" value="${sample_widget['name']}" size="10"/>
        <div class="toolParamHelp" style="clear: both;">
            <i>${' (required)' }</i>
        </div>
    </td>
    %if display_bar_code:
        <td valign="top">
            %if is_admin and is_submitted:
                <input type="text" name="sample_${sample_widget_index}_bar_code" value="${sample_widget['bar_code']}" size="10"/>
            %else:
                ${sample_widget['bar_code']}
                <input type="hidden" name="sample_${sample_widget_index}_bar_code" value="${sample_widget['bar_code']}"/>
            %endif
        </td>
    %endif 
    %if sample:
        %if is_unsubmitted:
            <td>Unsubmitted</td>
        %else:
            <td valign="top"><a href="${h.url_for( controller='requests_common', action='view_sample_history', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ) )}">${sample.state.name}</a></td>
        %endif    
    %else:
        <td></td>
    %endif
    <td valign="top">${sample_widget['library_select_field'].get_html()}</td>
    <td valign="top">${sample_widget['folder_select_field'].get_html()}</td>
    %if display_datasets:
        <td valign="top">
            ## An admin can select the datasets to transfer, while a non-admin can only view what has been selected
            %if is_admin:
                ## This link will direct the admin to a page allowing them to select datasets.
                <a id="sampleDatasets-${sample.id}" href="${h.url_for( controller='requests_admin', action='select_datasets_to_transfer', cntrller=cntrller, request_id=trans.security.encode_id( request.id ), sample_id= trans.security.encode_id( sample.id ) )}">${len( sample.datasets )}</a>
            %elif sample.datasets:
                ## Since this is a regular user, only display a link if there is at least 1
                ## selected dataset for the sample.
                <a id="sampleDatasets-${sample.id}" href="${h.url_for( controller='requests_common', action='view_sample_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ) )}">${len( sample.datasets )}</a>
            %else:
                ## Since this is a regular user, do not display a link if there are no datasets.
                ${len( sample.datasets )}
            %endif
        </td>
        <td valign="top">
            %if is_admin:
                <% 
                    if sample.transferred_dataset_files:
                        transferred_dataset_files = sample.transferred_dataset_files
                    else:
                        transferred_dataset_files = []
                %>
                %if not sample.datasets:
                    ## No datasets have been selected for this sample, so don't include a link
                    ${len( sample.transferred_dataset_files )}
                %elif len( sample.datasets ) > len( transferred_dataset_files ):
                    ## At least 1 selected dataset is not yet transferred, so this link
                    ## will direct the admin to a page allowing them to transfer datasets.
                    <a href="${h.url_for( controller='requests_admin', action='manage_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ) )}">${len( sample.transferred_dataset_files )}</a>
                %elif len( sample.datasets ) == len( transferred_dataset_files ):
                    ## All selected datasets have successfully transferred, so this link
                    ## will direct the admin to a page displaying all transferred datasets.
                    <a href="${h.url_for( controller='requests_common', action='view_sample_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ), transfer_status=trans.model.SampleDataset.transfer_status.COMPLETE )}">${len( sample.transferred_dataset_files )}</a>
                %endif
            %else:
                %if sample.transferred_dataset_files:
                    ## Since this is a regular user, this link will direct them to the target
                    ## data library containing those datasets that were successfully transferred.
                    <a href="${h.url_for( controller='library_common', action='browse_library', cntrller='library', id=trans.security.encode_id( sample.library.id ) )}">${len( sample.transferred_dataset_files )}</a>
                %else:
                    ## Since this is a regular user, do not display a link.
                    ${len( sample.transferred_dataset_files )}
                %endif
            %endif
        </td>
    %endif
    %if can_delete_samples:
        ## Delete button
        <td valign="top"><a class="action-button" confirm="This sample is not recoverable after deletion. Click Ok to delete." href="${h.url_for( controller='requests_common', action='delete_sample', cntrller=cntrller, request_id=trans.security.encode_id( request.id ), sample_id=sample_widget_index )}"><img src="${h.url_for('/static/images/delete_icon.png')}" style="cursor:pointer;"/></a></td>
    %endif
</%def>

<%def name="render_samples_grid( cntrller, request, displayable_sample_widgets, action, editing_samples=False, encoded_selected_sample_ids=[], render_buttons=False, grid_header='<h3>Samples</h3>' )">
    ## Displays the "Samples" grid
    <%
        trans.sa_session.refresh( request )
        is_admin = cntrller == 'requests_admin' and trans.user_is_admin()
        is_complete = request.is_complete
        is_rejected = request.is_rejected
        is_submitted = request.is_submitted
        is_unsubmitted = request.is_unsubmitted
        can_add_samples = request.is_unsubmitted
        can_delete_samples = editing_samples and request.samples and ( ( is_admin and not is_complete ) or is_unsubmitted )
        can_edit_samples = request.samples and ( is_admin or not is_complete )
        can_select_datasets = is_admin and displayable_sample_widgets and ( is_submitted or is_complete )
        can_transfer_datasets = is_admin and request.samples and not request.is_rejected
        display_checkboxes = editing_samples and ( is_complete or is_rejected or is_submitted )
        display_bar_code = request.samples and ( is_complete or is_rejected or is_submitted )
        display_datasets = request.samples and ( is_complete or is_submitted )
    %>
    ${grid_header}
    %if render_buttons and ( can_add_samples or can_edit_samples ):
        <ul class="manage-table-actions">
            %if can_add_samples:
                <li><a class="action-button" href="${h.url_for( controller='requests_common', action='add_sample', cntrller=cntrller, request_id=trans.security.encode_id( request.id ), add_sample_button='Add sample' )}">Add sample</a></li>
            %endif
            %if can_edit_samples:
                <li><a class="action-button" href="${h.url_for( controller='requests_common', action='edit_samples', cntrller=cntrller, id=trans.security.encode_id( request.id ), editing_samples='True' )}">Edit samples</a></li>
            %endif
        </ul>
    %endif
    <table class="grid">
        <thead>
            <tr>
                %if display_checkboxes:
                    <th><input type="checkbox" id="checkAll" name=select_all_samples_checkbox value="true" onclick='checkAllFields(1);'/><input type="hidden" name=select_all_samples_checkbox value="true"/></th>
                %endif
                <th>Name</th>
                %if display_bar_code:
                    <th>Barcode</th>
                %endif
                <th>State</th>
                <th>Data Library</th>
                <th>Folder</th>
                %if display_datasets:
                    <th>Datasets Selected</th>
                    <th>Datasets Transferred</th>
                %endif
                <th>
                    %if can_delete_samples:
                        Delete
                    %endif
                </th>
            </tr>
        <thead>
        <tbody>
            <% trans.sa_session.refresh( request ) %>
            ## displayable_sample_widgets is a dictionary whose keys are:
            ## id, name, bar_code, library, folder, field_values, library_select_field, folder_select_field
            ## A displayable_sample_widget will have an id == None if the widget's associated sample has not
            ## yet been saved (i.e., the use clicked the "Add sample" button but has not yet clicked the
            ## "Save" button.
            %for sample_widget_index, sample_widget in enumerate( displayable_sample_widgets ):
                <%
                    sample_widget_name = sample_widget[ 'name' ]
                    sample_widget_bar_code = sample_widget[ 'bar_code' ]
                    sample_widget_library = sample_widget[ 'library' ]
                    if sample_widget_library:
                        if cntrller == 'requests':
                            library_cntrller = 'library'
                        elif is_admin:
                            library_cntrller = 'library_admin'
                        else:
                            library_cntrller = None
                    sample_widget_folder = sample_widget[ 'folder' ]
                    try:
                        sample = request.samples[ sample_widget_index ]
                    except:
                        sample = None 
                %>
                %if editing_samples:
                    <tr>${render_editable_sample_row( cntrller, request, sample, sample_widget_index, sample_widget, encoded_selected_sample_ids )}</tr>
                %elif sample:
                    <tr>
                        <td>
                            %if sample.state and ( can_select_datasets or can_transfer_datasets ):
                                ## A sample will have a state only after the request has been submitted.
                                <%
                                    encoded_id = trans.security.encode_id( sample.id )
                                    transferred_dataset_files = sample.transferred_dataset_files
                                    if not transferred_dataset_files:
                                        transferred_dataset_files = []
                                %>
                                <div style="float: left; margin-left: 2px;" class="menubutton split popup" id="sample-${sample.id}-popup">
                                    <a class="view-info" href="${h.url_for( controller='requests_common', action='view_sample', cntrller=cntrller, id=trans.security.encode_id( sample.id ) )}">${sample.name}</a>
                                </div>
                                <div popupmenu="sample-${sample.id}-popup">
                                    %if can_select_datasets:
                                        <li><a class="action-button" href="${h.url_for( controller='requests_admin', action='select_datasets_to_transfer', request_id=trans.security.encode_id( request.id ), sample_id=trans.security.encode_id( sample.id ) )}">Select datasets to transfer</a></li>
                                    %endif
                                    %if sample.datasets and len( sample.datasets ) > len( transferred_dataset_files ) and sample.library and sample.folder:
                                        <li><a class="action-button" href="${h.url_for( controller='requests_admin', action='manage_datasets', sample_id=trans.security.encode_id( sample.id ) )}">Manage selected datasets</a></li>
                                    %elif sample.datasets and len(sample.datasets ) == len( transferred_dataset_files ):
                                        <li><a class="action-button" href="${h.url_for( controller='requests_common', action='view_sample_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ), transfer_status=trans.model.SampleDataset.transfer_status.COMPLETE )}">View transferred datasets</a></li>
                                    %endif
                                </div>
                            %else:
                                ${sample_widget_name}
                            %endif
                        </td>
                        %if display_bar_code:
                            <td>${sample_widget_bar_code}</td>
                        %endif
                        %if is_unsubmitted:
                            <td>Unsubmitted</td>
                        %else:
                            <td><a id="sampleState-${sample.id}" href="${h.url_for( controller='requests_common', action='view_sample_history', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ) )}">${render_sample_state( sample )}</a></td>
                        %endif
                        %if sample_widget_library and library_cntrller is not None:
                            <td><a href="${h.url_for( controller='library_common', action='browse_library', cntrller=library_cntrller, id=trans.security.encode_id( sample_widget_library.id ) )}">${sample_widget_library.name}</a></td>                                  
                        %else:
                            <td></td>
                        %endif
                        %if sample_widget_folder:
                            <td>${sample_widget_folder.name}</td>
                        %else:
                            <td></td>
                        %endif
                        %if is_submitted or is_complete:
                            <td>
                                ## An admin can select the datasets to transfer, while a non-admin can only view what has been selected
                                %if is_admin:
                                    ## This link will direct the admin to a page allowing them to select datasets.
                                    <a id="sampleDatasets-${sample.id}" href="${h.url_for( controller='requests_admin', action='select_datasets_to_transfer', cntrller=cntrller, request_id=trans.security.encode_id( request.id ), sample_id= trans.security.encode_id( sample.id ) )}">${len( sample.datasets )}</a>
                                %elif sample.datasets:
                                    ## Since this is a regular user, only display a link if there is at least 1
                                    ## selected dataset for the sample.
                                    <a id="sampleDatasets-${sample.id}" href="${h.url_for( controller='requests_common', action='view_sample_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ) )}">${len( sample.datasets )}</a>
                                %else:
                                    ## Since this is a regular user, do not display a link if there are no datasets.
                                    ${len( sample.datasets )}
                                %endif
                            </td>
                            <td>
                                %if is_admin:
                                    <% 
                                        transferred_dataset_files = sample.transferred_dataset_files
                                        if not transferred_dataset_files:
                                            transferred_dataset_files = []
                                    %>
                                    %if not sample.datasets:
                                        ## No datasets have been selected for this sample, so don't include a link
                                        ${len( sample.transferred_dataset_files )}
                                    %elif len( sample.datasets ) > len( transferred_dataset_files ):
                                        ## At least 1 selected dataset is not yet transferred, so this link
                                        ## will direct the admin to a page allowing them to transfer datasets.
                                        <a href="${h.url_for( controller='requests_admin', action='manage_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ) )}">${len( sample.transferred_dataset_files )}</a>
                                    %elif len( sample.datasets ) == len( transferred_dataset_files ):
                                        ## All selected datasets have successfully transferred, so this link
                                        ## will direct the admin to a page displaying all transferred datasets.
                                        <a href="${h.url_for( controller='requests_common', action='view_sample_datasets', cntrller=cntrller, sample_id=trans.security.encode_id( sample.id ), transfer_status=trans.model.SampleDataset.transfer_status.COMPLETE )}">${len( sample.transferred_dataset_files )}</a>
                                    %endif
                                %else:
                                    %if sample.transferred_dataset_files:
                                        ## Since this is a regular user, this link will direct them to the target
                                        ## data library containing those datasets that were successfully transferred.
                                        <a href="${h.url_for( controller='library_common', action='browse_library', cntrller='library', id=trans.security.encode_id( sample.library.id ) )}">${len( sample.transferred_dataset_files )}</a>
                                    %else:
                                        ## Since this is a regular user, do not display a link.
                                        ${len( sample.transferred_dataset_files )}
                                    %endif
                                %endif
                            </td>
                        %endif
                    </tr>
                %else:
                    ## The Add sample button was clicked for this sample_widget
                    <tr>${render_editable_sample_row( cntrller, request, None, sample_widget_index, sample_widget, encoded_selected_sample_ids )}</tr>
                %endif
            %endfor
        </tbody>
    </table>
</%def>

<%def name="render_sample_form( index, sample_name, sample_values, fields_dict, display_only )">
    <tr>
        <td>${sample_name}</td>
        %for field_index, field in fields_dict.items():
            <% 
                field_type = field[ 'type' ]
                field_name = field[ 'name' ]
                field_value = sample_values[ field_name ]
            %>
            <td>
                %if display_only:
                    %if field_value:
                        %if field_type == 'WorkflowField':
                            %if str( field_value ) != 'none':
                                <% workflow = trans.sa_session.query( trans.app.model.StoredWorkflow ).get( int( field_value ) ) %>
                                <a href="${h.url_for( controller='workflow', action='run', id=trans.security.encode_id( workflow.id ) )}">${workflow.name}</a>
                            %endif
                        %else:
                            ${field_value}
                        %endif
                    %else:
                        <i>None</i>
                    %endif
                %else:
                    %if field_type == 'TextField':
                        <input type="text" name="sample_${index}_field_${field_index}" value="${field_value}" size="7"/>
                    %elif field_type == 'SelectField':
                        <select name="sample_${index}_field_${field_index}" last_selected_value="2">
                            %for option_index, option in enumerate(field[ 'selectlist' ]):
                                %if option == field_value:
                                    <option value="${option}" selected>${option}</option>
                                %else:
                                    <option value="${option}">${option}</option>
                                %endif
                            %endfor
                        </select>
                    %elif field_type == 'WorkflowField':
                        <select name="sample_${index}_field_${field_index}">
                            %if str( field_value ) == 'none':
                                <option value="none" selected>Select one</option>
                            %else:
                                <option value="none">Select one</option>
                            %endif
                            %for option_index, option in enumerate(request.user.stored_workflows):
                                %if not option.deleted:
                                    %if str( option.id ) == str( field_value ):
                                        <option value="${option.id}" selected>${option.name}</option>
                                    %else:
                                        <option value="${option.id}">${option.name}</option>
                                    %endif
                                %endif
                            %endfor
                        </select>
                    %elif field_type == 'HistoryField':
                        <select name="sample_${index}_field_${field_index}">
                            %if str( field_value ) == 'none':
                                <option value="none" selected>Select one</option>
                            %else:
                                <option value="none">Select one</option>
                            %endif
                            %for option_index, option in enumerate(request.user.histories):
                                %if not option.deleted:
                                    %if str( option.id ) == str( field_value ):
                                        <option value="${option.id}" selected>${option.name}</option>
                                    %else:
                                        <option value="${option.id}">${option.name}</option>
                                    %endif
                                %endif
                            %endfor
                        </select>
                    %elif field_type == 'CheckboxField':
                        <input type="checkbox" name="sample_${index}_field_${field_index}" value="Yes"/>
                    %endif
                    <div class="toolParamHelp" style="clear: both;">
                        <i>${'('+field['required']+')' }</i>
                    </div>
                %endif
            </td>
        %endfor
    </tr> 
</%def>

<%def name="render_request_type_sample_form_grids( grid_index, grid_name, fields_dict, displayable_sample_widgets, editing_samples )">
    <%
        if not grid_name:
            grid_name = "Sample form layout " + grid_index
    %>
    <h4><img src="/static/images/fugue/toggle-expand.png" alt="Hide" onclick="showContent(this);" style="cursor:pointer;"/> ${grid_name}</h4>
    <div style="display:none;">
        <table class="grid">
            <thead>
                <tr>
                    <th>Name</th>
                    %for index, field in fields_dict.items():
                        <th>
                            <a class="display tooltip" title="${field['helptext']}" >${field['label']}</a>
                        </th>
                    %endfor
                    <th></th>
                </tr>
            <thead>
            <tbody>
                <% trans.sa_session.refresh( request ) %>
                %for sample_index, sample in enumerate( displayable_sample_widgets ):
                    <%
                        if editing_samples or sample_index >= len( request.samples ):
                            display_only = False
                        else:
                            display_only = True
                    %>
                    ${render_sample_form( sample_index, sample['name'], sample['field_values'], fields_dict, display_only )}    
                %endfor
            </tbody>
        </table>
    </div>
</%def>

<%def name="render_sample_datasets( cntrller, sample, sample_datasets, title )">
    ## The list of sample_datasets may not be the same as sample.datasets because it may be
    ## filtered by a transfer_status value.  The value of title changes based on this filter.
    %if sample_datasets:
        <%
            trans.sa_session.refresh( sample )
            is_admin = cntrller == 'requests_admin' and trans.user_is_admin()
            is_complete = sample.request.is_complete
            is_submitted = sample.request.is_submitted
            can_select_datasets = is_admin and ( is_complete or is_submitted )
            can_transfer_datasets = is_admin and sample.untransferred_dataset_files
        %>
        ## The transfer status should update only when the request has been submitted or complete
        ## and when the sample has in-progress datasets.
        %if ( is_complete or is_submitted ) and sample.inprogress_dataset_files: 
		    <script type="text/javascript">
		        // Sample dataset transfer status updater
		        dataset_transfer_status_updater( {${ ",".join( [ '"%s" : "%s"' % ( trans.security.encode_id( sd.id ), sd.status ) for sd in sample_datasets ] ) }});
		    </script>
	    %endif
        <h3>${title}</h3>
        <table class="grid">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Size</th>
                    <th>Status</th>
                </tr>
            <thead>
            <tbody>
                %for dataset in sample_datasets:
                    <% encoded_id = trans.security.encode_id( dataset.id ) %>
                    <tr>
                        <td>
                            %if is_admin:
                                <span class="expandLink dataset-${dataset}-click"><span class="rowIcon"></span>
                                    <div style="float: left; margin-left: 2px;" class="menubutton split popup" id="dataset-${dataset.id}-popup">
                                        <a class="dataset-${encoded_id}-click" href="${h.url_for( controller='requests_admin', action='manage_datasets', operation='view', id=trans.security.encode_id( dataset.id ) )}">${dataset.name}</a>
                                    </div>
                                </span>
                                <div popupmenu="dataset-${dataset.id}-popup">
                                    %if can_transfer_datasets and dataset in sample.untransferred_dataset_files:
                                        <li><a class="action-button" href="${h.url_for( controller='requests_admin', action='initiate_data_transfer', sample_id=trans.security.encode_id( sample.id ), sample_dataset_id=trans.security.encode_id( dataset.id ) )}">Transfer</a></li>
                                    %endif
                                </div>
                            %else:
                                ${dataset.name}
                            %endif
                        </td>
                        <td>${dataset.size}</td>
                        <td id="datasetTransferStatus-${encoded_id}">${dataset.status}</td>
                    </tr>
                %endfor
            </tbody>
        </table>
    %else:
        No datasets for this sample.
    %endif
</%def>
