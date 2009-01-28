<%inherit file="/base.mako"/>
<%namespace file="common.mako" import="render_dataset" />
<%namespace file="/message.mako" import="render_msg" />

<%def name="title()">Import from Library</%def>
<%def name="stylesheets()">
    <link href="${h.url_for('/static/style/base.css')}" rel="stylesheet" type="text/css" />
    <link href="${h.url_for('/static/style/library.css')}" rel="stylesheet" type="text/css" />
</%def>

<%
def name_sorted( l ):
    return sorted( l, lambda a, b: cmp( a.name.lower(), b.name.lower() ) )
%>

<script type="text/javascript">
    //var q = jQuery.noConflict();
    $( document ).ready( function () {
        // Hide all the folder contents
        $("ul").filter("ul#subFolder").hide();
        // Handle the hide/show triangles
        $("li.libraryOrFolderRow").wrap( "<a href='#' class='expandLink'></a>" ).click( function() {
            var contents = $(this).parent().next("ul");
            if ( this.id == "libraryRow" ) {
                var icon_open = "${h.url_for( '/static/images/silk/book_open.png' )}";
                var icon_closed = "${h.url_for( '/static/images/silk/book.png' )}";
            } else {
                var icon_open = "${h.url_for( '/static/images/silk/folder_page.png' )}";
                var icon_closed = "${h.url_for( '/static/images/silk/folder.png' )}";
            }
            if ( contents.is(":visible") ) {
                contents.slideUp("fast");
                $(this).children().find("img.expanderIcon").each( function() { this.src = "${h.url_for( '/static/images/silk/resultset_next.png' )}"; });
                $(this).children().find("img.rowIcon").each( function() { this.src = icon_closed; });
            } else {
                contents.slideDown("fast");
                $(this).children().find("img.expanderIcon").each( function() { this.src = "${h.url_for( '/static/images/silk/resultset_bottom.png' )}"; });
                $(this).children().find("img.rowIcon").each( function() { this.src = icon_open; });
            }
        });
        // Hide all dataset bodies
        $("div.historyItemBody").hide();
        // Handle the dataset body hide/show link.
        $("div.historyItemWrapper").each( function() {
            var id = this.id;
            var li = $(this).parent();
            var body = $(this).children( "div.historyItemBody" );
            var peek = body.find( "pre.peek" )
            $(this).children( ".historyItemTitleBar" ).find( ".historyItemTitle" ).wrap( "<a href='#'></a>" ).click( function() {
                if ( body.is(":visible") ) {
                    if ( $.browser.mozilla ) { peek.css( "overflow", "hidden" ) }
                    body.slideUp( "fast" );
                    li.removeClass( "datasetHighlighted" );
                } 
                else {
                    body.slideDown( "fast", function() { 
                        if ( $.browser.mozilla ) { peek.css( "overflow", "auto" ); } 
                    });
                    li.addClass( "datasetHighlighted" );
                }
                return false;
            });
        });
    });
    function checkForm() {
        if ( $("select#action_on_datasets_select option:selected").text() == "delete" ) {
            if ( confirm( "Click OK to delete these datasets?" ) ) {
                return true;
            } else {
                return false;
            }
        }
    }
</script>

<%def name="render_folder( parent, parent_pad, deleted, created_ldda_ids )">
    <%
        ##if not trans.app.security_agent.check_folder_contents( trans.user, parent ):
        ##  return ""
        pad = parent_pad + 20
        if parent_pad == 0:
            expander = "/static/images/silk/resultset_bottom.png"
            folder = "/static/images/silk/folder_page.png"
            subfolder = False
        else:
            expander = "/static/images/silk/resultset_next.png"
            folder = "/static/images/silk/folder.png"
            subfolder = True

        if created_ldda_ids and not isinstance ( created_ldda_ids, list ):
            created_ldda_id_list = created_ldda_ids.split( ',' )
            if created_ldda_id_list:
               created_ldda_ids = [ int( ldda_id ) for ldda_id in created_ldda_id_list ]
    %>
    <li class="folderRow libraryOrFolderRow" style="padding-left: ${pad}px;">
        <div class="rowTitle">
            <img src="${h.url_for( expander )}" class="expanderIcon"/><img src="${h.url_for( folder )}" class="rowIcon"/>
            ${parent.name}
            %if parent.description:
                <i>- ${parent.description}</i>
            %endif
            <a id="folder-${parent.id}-popup" class="popup-arrow" style="display: none;">&#9660;</a>
        </div>
        %if not deleted:
            <div popupmenu="folder-${parent.id}-popup">
                <a class="action-button" href="${h.url_for( controller='admin', action='dataset', folder_id=parent.id )}">Add a new dataset to this folder</a>
                <a class="action-button" href="${h.url_for( controller='admin', action='add_dataset_to_folder_from_history', folder_id=parent.id )}">Copy a dataset from your history to this folder</a>
                <a class="action-button" href="${h.url_for( controller='admin', action='folder', new=True, id=parent.id )}">Create a new sub-folder in this folder</a>
                <a class="action-button" href="${h.url_for( controller='admin', action='folder', rename=True, id=parent.id )}">Edit this folder</a>
                %if subfolder:
                    <a class="action-button" confirm="Click OK to delete the folder '${parent.name}'" href="${h.url_for( action='folder', delete=True, id=parent.id )}">Remove this folder and its contents from the library</a>
                %endif
            </div>
        %endif
    </li>
    %if subfolder:
        <ul id="subFolder">
    %else:
        <ul>
    %endif
    %if deleted:
        <%
            parent_folders = parent.folders
            parent_datasets = parent.datasets
        %>
    %else:
        <%
            parent_folders = parent.active_folders
            parent_datasets = parent.active_datasets
        %>
    %endif
    %for folder in name_sorted( parent_folders ):
        ${render_folder( folder, pad, deleted, created_ldda_ids )}
    %endfor
    %for dataset in name_sorted( parent_datasets ):
        <%
            if created_ldda_ids and dataset.id in created_ldda_ids:
                selected = True
            else:
                selected = False
        %>
        <li class="datasetRow" style="padding-left: ${pad + 18}px;">${render_dataset( dataset, selected, deleted )}</li>
    %endfor
    </ul>
</%def>

<h2>
    %if deleted:
        Deleted 
    %endif
    Libraries
</h2>

<ul class="manage-table-actions">
    %if not deleted:
        <li>
            <a class="action-button" href="${h.url_for( action='library', new=True )}"><span>Create a new library</span></a>
        </li>
        <li>
            <a class="action-button" href="${h.url_for( action='deleted_libraries' )}"><span>Manage deleted libraries</span></a>
        </li>
    %endif
</ul>

%if msg:
    ${render_msg( msg, messagetype )}
%endif

%if not libraries:
    %if deleted:
        There are no deleted libraries
    %else:
        There are no libraries.
    %endif
%else:
    <form name="update_multiple_datasets" action="${h.url_for( action='datasets' )}" onSubmit="javascript:return checkForm();" method="post">
        <ul>
            %for library in libraries:
                ##%if trans.app.security_agent.check_folder_contents( trans.user, library ):
                <li class="libraryRow libraryOrFolderRow" id="libraryRow">
                    <div class="rowTitle">
                        <table cellspacing="0" cellpadding="0" border="0" width="100%" class="libraryTitle">
                            <th width="*">
                                <img src="${h.url_for( '/static/images/silk/resultset_bottom.png' )}" class="expanderIcon"/><img src="${h.url_for( '/static/images/silk/book_open.png' )}" class="rowIcon"/>
                                ${library.name}
                                %if library.description:
                                    <i>- ${library.description}</i>
                                %endif
                                <a id="library-${library.id}-popup" class="popup-arrow" style="display: none;">&#9660;</a>
                                %if not deleted:
                                    <div popupmenu="library-${library.id}-popup">
                                        <a class="action-button" href="${h.url_for( action='library', rename=True, id=library.id )}">Edit this library</a>
                                        <a class="action-button" confirm="Current state will not be saved, so undeleting the library will restore all of its contents.  Click OK to delete the library named '${library.name}'?" href="${h.url_for( action='library', delete=True, id=library.id )}">Delete this library and its contents</a>
                                    </div>
                                %else:
                                    <div popupmenu="library-${library.id}-popup">
                                        <a class="action-button" href="${h.url_for( action='undelete_library', id=library.id )}">Undelete this library and its contents</a>
                                        <a class="action-button" href="${h.url_for( action='purge_library', id=library.id )}">Purge this library and its contents</a>
                                    </div>
                                %endif
                            </th>
                            <th width="100">Format</th>
                            <th width="50">Db</th>
                            <th width="200">Info</th>
                        </table>
                    </div>
                </li>
                <ul>
                    ${render_folder( library.root_folder, 0, deleted, created_ldda_ids )}
                </ul>
                <br/>
                ##%endif
            %endfor
        </ul>
        %if not deleted:
            <p>
                <b>Perform action on selected datasets:</b>
                <select name="action" id="action_on_datasets_select">
                    <option value="edit">Edit selected datasets' attributes and permissions</option>
                    <option value="delete">Remove selected datasets from this library</option>
                </select>
                <input type="submit" class="primary-button" name="action_on_datasets_button" id="action_on_datasets_button" value="Go"/>
            </p>
        %endif
    </form>
%endif
