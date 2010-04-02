<%inherit file="/base.mako"/>
<%namespace file="/message.mako" import="render_msg" />

%if message:
    ${render_msg( message, status )}
%endif

<script type="text/javascript">
$( function() {
    $( "select[refresh_on_change='true']").change( function() {
        var refresh = false;
        var refresh_on_change_values = $( this )[0].attributes.getNamedItem( 'refresh_on_change_values' )
        if ( refresh_on_change_values ) {
            refresh_on_change_values = refresh_on_change_values.value.split( ',' );
            var last_selected_value = $( this )[0].attributes.getNamedItem( 'last_selected_value' );
            for( i= 0; i < refresh_on_change_values.length; i++ ) {
                if ( $( this )[0].value == refresh_on_change_values[i] || ( last_selected_value && last_selected_value.value == refresh_on_change_values[i] ) ){
                    refresh = true;
                    break;
                }
            }
        }
        else {
            refresh = true;
        }
        if ( refresh ){
            $( "#edit_form" ).submit();
        }
    });
});
</script>

<script type="text/javascript">
$(document).ready(function(){
    //hide the all of the element with class msg_body
    $(".msg_body").hide();
    //toggle the componenet with class msg_body
    $(".msg_head").click(function(){
        $(this).next(".msg_body").slideToggle(450);
    });
});
</script>
<style type="text/css">
.msg_head {
    padding: 0px 0px;
    cursor: pointer;
}

}
</style>

<%def name="render_selectbox_options( index, field_attr )">
    %if field_attr[0] == 'Type':
        %if field_attr[1].get_selected()[0] == 'SelectField':
            <% options = field_attr[2] %>
            <div class="repeat-group-item">
                <div class="form-row">
                    <label> Options</label>
                    %for i, option in enumerate(options):
                        <div class="form-row">
                            <b> ${i+1}</b>
                            ${option[1].get_html()}
                            ##<a class="action-button" href="${h.url_for( controller='forms', action='edit', form_id=form.id, select_box_options='remove', field_index=index, option_index=i )}">Remove</a><br>                            
                            <input type="submit" name="removeoption_${index}_${i}" value="Remove"/>
                        </div>
                    %endfor
                    <input type="hidden" name="field_index" value="${index}"/>
                </div>
            </div>
            <div class="form-row">
                <input type="submit" name="addoption_${index}" value="Add"/>
            </div>
        %endif
    %endif
</%def>

<%def name="render_field( index, field, saved )">
    %if saved:        
        <h4 class="msg_head"> 
            <div class="form-row">${index+1}. ${field[0][1].value} (${field[2][1].get_selected()[1]})</div>
        </h4>
        <div class="msg_body">
    %else:
        <div class="msg_body2">
    %endif
    <div class="repeat-group-item">
        %for field_attr in field:
            <div class="form-row">
                <label>${field_attr[0]}</label>
                ${field_attr[1].get_html()}
                ${render_selectbox_options( index, field_attr )}
            </div>
        %endfor
        <div class="form-row">
            <input type="submit" name="remove_button" value="Remove field ${index+1}"/>
        </div>
    </div>
    </div>
</%def>

<%def name="render_layout( index, widget )">
    <div class="repeat-group-item">
        <div class="form-row">
            <b> ${index+1}</b>
            ${widget.get_html()}
            <input type="submit" name="remove_layout_grid_button" value="Remove grid ${index+1}"/>
        </div>
   </div>
</%def>

<div class="toolForm">
    <div class="toolFormTitle">Edit form definition "${form.name}"</div>
    <form id="edit_form" name="edit_form" action="${h.url_for( controller='forms', action='edit', id=trans.security.encode_id(form.current.id)  )}" method="post" >
        %if response_redirect:
            <input type="hidden" name="response_redirect" value="${response_redirect}" size="40" />
        %endif
        %for label, input in form_details:
            <div class="form-row">
                ## TODO: RC, this will keep the form type select list label
                ## from being displayed here.  At this point, the select list is a hidden field.
                ## Make sure this is the best solution to this problem.
                %if label != 'Type':
                    <label>${label}</label>
                %endif
                <div style="float: left; width: 250px; margin-right: 10px;">
                    ${input.get_html()}
                </div>
                <div style="clear: both"></div>
            </div>
        %endfor
        %if current_form_type == trans.app.model.FormDefinition.types.SAMPLE:
            <div class="toolFormTitle">Form Layout</div>
            <div class="form-row">
                <label>Layout grid names</label>
            </div>
            %for index, lg in enumerate(layout_grids):
                ${render_layout( index, lg )}
            %endfor
            <div class="form-row">
                <input type="submit" name="add_layout_grid" value="Add layout grid"/>
            </div>
        %endif
        <div class="toolFormTitle">Fields (${len(form.fields)})</div>
        %for ctr, field in enumerate(field_details):
            %if ctr < len(form.fields):
                ${render_field( ctr, field, True )}
            %else:
                ${render_field( ctr, field, False )}
            %endif
        %endfor
        <div class="form-row">
            <input type="submit" name="add_field_button" value="Add field"/>
        </div>
        <div class="form-row">
            <div style="float: left; width: 250px; margin-right: 10px;">
                <input type="hidden" name="refresh" value="true" size="40"/>
            </div>
          <div style="clear: both"></div>
        </div>
        <div class="form-row">
            <input type="submit" name="save_changes_button" value="Save"/>
        </div>
    </form>
</div>
