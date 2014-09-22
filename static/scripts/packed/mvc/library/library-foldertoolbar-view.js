define(["galaxy.masthead","utils/utils","libs/toastr","mvc/library/library-model"],function(b,d,e,c){var a=Backbone.View.extend({el:"#center",events:{"click #toolbtn_create_folder":"createFolderFromModal","click #toolbtn_bulk_import":"modalBulkImport","click .toolbtn_add_files":"addFilesToFolderModal","click #include_deleted_datasets_chk":"checkIncludeDeleted","click #toolbtn_bulk_delete":"deleteSelectedDatasets"},defaults:{can_add_library_item:false,contains_file:false,chain_call_control:{total_number:0,failed_number:0}},modal:null,histories:null,initialize:function(f){this.options=_.defaults(f||{},this.defaults);this.render()},render:function(g){this.options=_.extend(this.options,g);var i=false;var f=true;if(Galaxy.currUser){i=Galaxy.currUser.isAdmin();f=Galaxy.currUser.isAnonymous()}var h=this.templateToolBar();this.$el.html(h({id:this.options.id,admin_user:i,anonym:f}))},configureElements:function(f){this.options=_.extend(this.options,f);if(this.options.can_add_library_item===true){$(".add-library-items").show()}else{$(".add-library-items").hide()}if(this.options.contains_file===true){if(Galaxy.currUser){if(!Galaxy.currUser.isAnonymous()){$(".logged-dataset-manipulation").show();$(".dataset-manipulation").show()}else{$(".dataset-manipulation").show();$(".logged-dataset-manipulation").hide()}}else{$(".logged-dataset-manipulation").hide();$(".dataset-manipulation").hide()}}else{$(".logged-dataset-manipulation").hide();$(".dataset-manipulation").hide()}this.$el.find("[data-toggle]").tooltip()},createFolderFromModal:function(){event.preventDefault();event.stopPropagation();var f=this;var g=this.templateNewFolderInModal();this.modal=Galaxy.modal;this.modal.show({closing_events:true,title:"Create New Folder",body:g(),buttons:{Create:function(){f.create_new_folder_event()},Close:function(){Galaxy.modal.hide()}}})},create_new_folder_event:function(){var f=this.serialize_new_folder();if(this.validate_new_folder(f)){var g=new c.FolderAsModel();url_items=Backbone.history.fragment.split("/");current_folder_id=url_items[url_items.length-1];g.url=g.urlRoot+"/"+current_folder_id;g.save(f,{success:function(h){Galaxy.modal.hide();e.success("Folder created");h.set({type:"folder"});Galaxy.libraries.folderListView.collection.add(h)},error:function(i,h){Galaxy.modal.hide();if(typeof h.responseJSON!=="undefined"){e.error(h.responseJSON.err_msg)}else{e.error("An error ocurred :(")}}})}else{e.error("Folder's name is missing")}return false},serialize_new_folder:function(){return{name:$("input[name='Name']").val(),description:$("input[name='Description']").val()}},validate_new_folder:function(f){return f.name!==""},modalBulkImport:function(){var f=$("#folder_table").find(":checked");if(f.length===0){e.info("You have to select some datasets first")}else{this.refreshUserHistoriesList(function(g){var h=g.templateBulkImportInModal();g.modal=Galaxy.modal;g.modal.show({closing_events:true,title:"Import into History",body:h({histories:g.histories.models}),buttons:{Import:function(){g.importAllIntoHistory()},Close:function(){Galaxy.modal.hide()}}})})}},refreshUserHistoriesList:function(g){var f=this;this.histories=new c.GalaxyHistories();this.histories.fetch({success:function(){g(f)},error:function(i,h){if(typeof h.responseJSON!=="undefined"){e.error(h.responseJSON.err_msg)}else{e.error("An error ocurred :(")}}})},importAllIntoHistory:function(){this.modal.disableButton("Import");this.options.chain_call_control.total_number=0;this.options.chain_call_control.failed_number=0;var k=$("select[name=dataset_import_bulk] option:selected").val();this.options.last_used_history_id=k;var n=$("select[name=dataset_import_bulk] option:selected").text();var p=[];$("#folder_table").find(":checked").each(function(){if(this.parentElement.parentElement.id!==""){p.push(this.parentElement.parentElement.id)}});var o=this.templateImportIntoHistoryProgressBar();this.modal.$el.find(".modal-body").html(o({history_name:n}));var l=100/p.length;this.initProgress(l);var f=[];for(var h=p.length-1;h>=0;h--){var j=p[h];var m=new c.HistoryItem();m.url=m.urlRoot+k+"/contents";m.content=j;m.source="library";f.push(m)}this.options.chain_call_control.total_number=f.length;var g="/api/histories/"+k+"/set_as_current";$.ajax({url:g,type:"PUT"});this.chainCall(f,n)},chainCall:function(g,j){var f=this;var h=g.pop();if(typeof h==="undefined"){if(this.options.chain_call_control.failed_number===0){e.success("Selected datasets imported into history. Click this to start analysing it.","",{onclick:function(){window.location="/"}})}else{if(this.options.chain_call_control.failed_number===this.options.chain_call_control.total_number){e.error("There was an error and no datasets were imported into history.")}else{if(this.options.chain_call_control.failed_number<this.options.chain_call_control.total_number){e.warning("Some of the datasets could not be imported into history. Click this to see what was imported.","",{onclick:function(){window.location="/"}})}}}Galaxy.modal.hide();return}var i=$.when(h.save({content:h.content,source:h.source}));i.done(function(){f.updateProgress();f.chainCall(g,j)}).fail(function(){f.options.chain_call_control.failed_number+=1;f.updateProgress();f.chainCall(g,j)})},initProgress:function(f){this.progress=0;this.progressStep=f},updateProgress:function(){this.progress+=this.progressStep;$(".progress-bar-import").width(Math.round(this.progress)+"%");txt_representation=Math.round(this.progress)+"% Complete";$(".completion_span").text(txt_representation)},download:function(f,j){var h=[];$("#folder_table").find(":checked").each(function(){if(this.parentElement.parentElement.id!==""){h.push(this.parentElement.parentElement.id)}});var g="/api/libraries/datasets/download/"+j;var i={ld_ids:h};this.processDownload(g,i,"get")},processDownload:function(g,h,i){if(g&&h){h=typeof h==="string"?h:$.param(h);var f="";$.each(h.split("&"),function(){var j=this.split("=");f+='<input type="hidden" name="'+j[0]+'" value="'+j[1]+'" />'});$('<form action="'+g+'" method="'+(i||"post")+'">'+f+"</form>").appendTo("body").submit().remove();e.info("Your download will begin soon")}},addFilesToFolderModal:function(){this.refreshUserHistoriesList(function(f){f.modal=Galaxy.modal;var g=f.templateAddFilesInModal();f.modal.show({closing_events:true,title:"Add datasets from history to "+f.options.folder_name,body:g({histories:f.histories.models}),buttons:{Add:function(){f.addAllDatasetsFromHistory()},Close:function(){Galaxy.modal.hide()}}});if(f.histories.models.length>0){f.fetchAndDisplayHistoryContents(f.histories.models[0].id);$("#dataset_add_bulk").change(function(h){f.fetchAndDisplayHistoryContents(h.target.value)})}else{e.error("An error ocurred :(")}})},fetchAndDisplayHistoryContents:function(h){var g=new c.HistoryContents({id:h});var f=this;g.fetch({success:function(j){var i=f.templateHistoryContents();f.histories.get(h).set({contents:j});f.modal.$el.find("#selected_history_content").html(i({history_contents:j.models.reverse()}))},error:function(){e.error("An error ocurred :(")}})},addAllDatasetsFromHistory:function(){this.modal.disableButton("Add");this.options.chain_call_control.total_number=0;this.options.chain_call_control.failed_number=0;var f=[];this.modal.$el.find("#selected_history_content").find(":checked").each(function(){var i=$(this.parentElement).data("id");if(i){f.push(i)}});var l=this.options.folder_name;var k=this.templateAddingDatasetsProgressBar();this.modal.$el.find(".modal-body").html(k({folder_name:l}));this.progressStep=100/f.length;this.progress=0;var j=[];for(var h=f.length-1;h>=0;h--){history_dataset_id=f[h];var g=new c.Item();g.url="/api/folders/"+this.options.id+"/contents";g.set({from_hda_id:history_dataset_id});j.push(g)}this.options.chain_call_control.total_number=j.length;this.chainCallAddingHdas(j)},chainCallAddingHdas:function(g){var f=this;this.added_hdas=new c.Folder();var h=g.pop();if(typeof h==="undefined"){if(this.options.chain_call_control.failed_number===0){e.success("Selected datasets from history added to the folder")}else{if(this.options.chain_call_control.failed_number===this.options.chain_call_control.total_number){e.error("There was an error and no datasets were added to the folder.")}else{if(this.options.chain_call_control.failed_number<this.options.chain_call_control.total_number){e.warning("Some of the datasets could not be added to the folder")}}}Galaxy.modal.hide();return this.added_hdas}var i=$.when(h.save({from_hda_id:h.get("from_hda_id")}));i.done(function(j){Galaxy.libraries.folderListView.collection.add(j);f.updateProgress();f.chainCallAddingHdas(g)}).fail(function(){f.options.chain_call_control.failed_number+=1;f.updateProgress();f.chainCallAddingHdas(g)})},checkIncludeDeleted:function(f){if(f.target.checked){Galaxy.libraries.folderListView.fetchFolder({include_deleted:true})}else{Galaxy.libraries.folderListView.fetchFolder({include_deleted:false})}},deleteSelectedDatasets:function(){var f=$("#folder_table").find(":checked");if(f.length===0){e.info("You have to select some datasets first")}else{var j=this.templateDeletingDatasetsProgressBar();this.modal=Galaxy.modal;this.modal.show({closing_events:true,title:"Deleting selected datasets",body:j({}),buttons:{Close:function(){Galaxy.modal.hide()}}});this.options.chain_call_control.total_number=0;this.options.chain_call_control.failed_number=0;var g=[];f.each(function(){if(this.parentElement.parentElement.id!==""){g.push(this.parentElement.parentElement.id)}});this.progressStep=100/g.length;this.progress=0;var l=[];for(var h=g.length-1;h>=0;h--){var k=new c.Item({id:g[h]});l.push(k)}this.options.chain_call_control.total_number=g.length;this.chainCallDeletingHdas(l)}},chainCallDeletingHdas:function(g){var f=this;this.deleted_lddas=new c.Folder();var h=g.pop();if(typeof h==="undefined"){if(this.options.chain_call_control.failed_number===0){e.success("Selected datasets deleted")}else{if(this.options.chain_call_control.failed_number===this.options.chain_call_control.total_number){e.error("There was an error and no datasets were deleted.")}else{if(this.options.chain_call_control.failed_number<this.options.chain_call_control.total_number){e.warning("Some of the datasets could not be deleted")}}}Galaxy.modal.hide();return this.deleted_lddas}var i=$.when(h.destroy());i.done(function(k){Galaxy.libraries.folderListView.collection.remove(h.id);f.updateProgress();if(Galaxy.libraries.folderListView.options.include_deleted){var j=new c.Item(k);Galaxy.libraries.folderListView.collection.add(j)}f.chainCallDeletingHdas(g)}).fail(function(){f.options.chain_call_control.failed_number+=1;f.updateProgress();f.chainCallDeletingHdas(g)})},templateToolBar:function(){tmpl_array=[];tmpl_array.push('<div class="library_style_container">');tmpl_array.push('<div id="library_toolbar">');tmpl_array.push('<span data-toggle="tooltip" data-placement="top" class="logged-dataset-manipulation" title="Include deleted datasets" style="display:none;"><input id="include_deleted_datasets_chk" style="margin: 0;" type="checkbox"> include deleted</input></span>');tmpl_array.push('<div class="btn-group add-library-items" style="display:none;">');tmpl_array.push('   <button data-toggle="tooltip" data-placement="top" title="Create New Folder" id="toolbtn_create_folder" class="btn btn-default primary-button" type="button"><span class="fa fa-plus"></span> <span class="fa fa-folder"></span></button>');tmpl_array.push('   <button data-toggle="tooltip" data-placement="top" title="Add Datasets to Current Folder" id="toolbtn_add_files" class="btn btn-default toolbtn_add_files primary-button" type="button"><span class="fa fa-plus"></span> <span class="fa fa-file"></span></span></button>');tmpl_array.push("</div>");tmpl_array.push('   <button data-toggle="tooltip" data-placement="top" title="Import selected datasets into history" id="toolbtn_bulk_import" class="primary-button dataset-manipulation" style="margin-left: 0.5em; display:none;" type="button"><span class="fa fa-book"></span> to History</button>');tmpl_array.push('   <div id="toolbtn_dl" class="btn-group dataset-manipulation" style="margin-left: 0.5em; display:none; ">');tmpl_array.push('       <button title="Download selected datasets as archive" id="drop_toggle" type="button" class="primary-button dropdown-toggle" data-toggle="dropdown">');tmpl_array.push('       <span class="fa fa-download"></span> Download <span class="caret"></span>');tmpl_array.push("       </button>");tmpl_array.push('       <ul class="dropdown-menu" role="menu">');tmpl_array.push('          <li id="download_archive"><a href="#/folders/<%= id %>/download/tgz">.tar.gz</a></li>');tmpl_array.push('          <li id="download_archive"><a href="#/folders/<%= id %>/download/tbz">.tar.bz</a></li>');tmpl_array.push('          <li id="download_archive"><a href="#/folders/<%= id %>/download/zip">.zip</a></li>');tmpl_array.push("       </ul>");tmpl_array.push("   </div>");tmpl_array.push('   <button data-toggle="tooltip" data-placement="top" title="Mark selected datasets deleted" id="toolbtn_bulk_delete" class="primary-button logged-dataset-manipulation" style="margin-left: 0.5em; display:none; " type="button"><span class="fa fa-times"></span> Delete</button>');tmpl_array.push("   </div>");tmpl_array.push('   <div id="folder_items_element">');tmpl_array.push("   </div>");tmpl_array.push("</div>");return _.template(tmpl_array.join(""))},templateNewFolderInModal:function(){tmpl_array=[];tmpl_array.push('<div id="new_folder_modal">');tmpl_array.push("<form>");tmpl_array.push('<input type="text" name="Name" value="" placeholder="Name">');tmpl_array.push('<input type="text" name="Description" value="" placeholder="Description">');tmpl_array.push("</form>");tmpl_array.push("</div>");return _.template(tmpl_array.join(""))},templateBulkImportInModal:function(){var f=[];f.push('<span id="history_modal_combo_bulk" style="width:90%; margin-left: 1em; margin-right: 1em; ">');f.push("Select history: ");f.push('<select id="dataset_import_bulk" name="dataset_import_bulk" style="width:50%; margin-bottom: 1em; "> ');f.push("   <% _.each(histories, function(history) { %>");f.push('       <option value="<%= _.escape(history.get("id")) %>"><%= _.escape(history.get("name")) %></option>');f.push("   <% }); %>");f.push("</select>");f.push("</span>");return _.template(f.join(""))},templateImportIntoHistoryProgressBar:function(){var f=[];f.push('<div class="import_text">');f.push("Importing selected datasets to history <b><%= _.escape(history_name) %></b>");f.push("</div>");f.push('<div class="progress">');f.push('   <div class="progress-bar progress-bar-import" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 00%;">');f.push('       <span class="completion_span">0% Complete</span>');f.push("   </div>");f.push("</div>");f.push("");return _.template(f.join(""))},templateAddingDatasetsProgressBar:function(){var f=[];f.push('<div class="import_text">');f.push("Adding selected datasets from history to library folder <b><%= _.escape(folder_name) %></b>");f.push("</div>");f.push('<div class="progress">');f.push('   <div class="progress-bar progress-bar-import" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 00%;">');f.push('       <span class="completion_span">0% Complete</span>');f.push("   </div>");f.push("</div>");f.push("");return _.template(f.join(""))},templateDeletingDatasetsProgressBar:function(){var f=[];f.push('<div class="import_text">');f.push("</div>");f.push('<div class="progress">');f.push('   <div class="progress-bar progress-bar-delete" role="progressbar" aria-valuenow="0" aria-valuemin="0" aria-valuemax="100" style="width: 00%;">');f.push('       <span class="completion_span">0% Complete</span>');f.push("   </div>");f.push("</div>");f.push("");return _.template(f.join(""))},templateAddFilesInModal:function(){var f=[];f.push('<div id="add_files_modal">');f.push('<div id="history_modal_combo_bulk">');f.push("Select history:  ");f.push('<select id="dataset_add_bulk" name="dataset_add_bulk" style="width:66%; "> ');f.push("   <% _.each(histories, function(history) { %>");f.push('       <option value="<%= _.escape(history.get("id")) %>"><%= _.escape(history.get("name")) %></option>');f.push("   <% }); %>");f.push("</select>");f.push("</div>");f.push('<div id="selected_history_content">');f.push("</div>");f.push("</div>");return _.template(f.join(""))},templateHistoryContents:function(){var f=[];f.push("Choose the datasets to import:");f.push("<ul>");f.push(" <% _.each(history_contents, function(history_item) { %>");f.push(' <li data-id="<%= _.escape(history_item.get("id")) %>">');f.push('   <input style="margin: 0;" type="checkbox"> <%= _.escape(history_item.get("hid")) %>: <%= _.escape(history_item.get("name")) %>');f.push(" </li>");f.push(" <% }); %>");f.push("</ul>");return _.template(f.join(""))}});return{FolderToolbarView:a}});