<%def name="common_javascripts(repository)">
    <script type="text/javascript">
        $(function(){
            $("#tree").ajaxComplete(function(event, XMLHttpRequest, ajaxOptions) {
                _log("debug", "ajaxComplete: %o", this); // dom element listening
            });
            // --- Initialize sample trees
            $("#tree").dynatree({
                title: "${repository.name}",
                rootVisible: true,
                minExpandLevel: 0, // 1: root node is not collapsible
                persist: false,
                checkbox: true,
                selectMode: 3,
                onPostInit: function(isReloading, isError) {
                    //alert("reloading: "+isReloading+", error:"+isError);
                    logMsg("onPostInit(%o, %o) - %o", isReloading, isError, this);
                    // Re-fire onActivate, so the text is updated
                    this.reactivate();
                }, 
                fx: { height: "toggle", duration: 200 },
                // initAjax is hard to fake, so we pass the children as object array:
                initAjax: {url: "${h.url_for( controller='repository', action='open_folder' )}",
                           dataType: "json", 
                           data: { repository_id: "${trans.security.encode_id( repository.id )}", key: "${repository.repo_path}" },
                },
                onLazyRead: function(dtnode){
                    dtnode.appendAjax({
                        url: "${h.url_for( controller='repository', action='open_folder' )}", 
                        dataType: "json",
                        data: { repository_id: "${trans.security.encode_id( repository.id )}", key: dtnode.data.key },
                    });
                },
                onSelect: function(select, dtnode) {
                    // Display list of selected nodes
                    var selNodes = dtnode.tree.getSelectedNodes();
                    // convert to title/key array
                    var selKeys = $.map(selNodes, function(node) {
                        return node.data.key;
                    });
                    if (document.forms["select_files_to_delete"]) {
                        // The following is used only ~/templates/webapps/community/repository/browse_repository.mako.
                        document.select_files_to_delete.selected_files_to_delete.value = selKeys.join(",");
                    }
                    // The following is used only in ~/templates/webapps/community/repository/upload.mako.
                    if (document.forms["upload_form"]) {
                        document.upload_form.upload_point.value = selKeys.slice(-1);
                    }
                },
                onActivate: function(dtnode) {
                    var cell = $("#file_contents");
                    var selected_value;
 