(function(){var b=Handlebars.template,a=Handlebars.templates=Handlebars.templates||{};a["template-visualization-scatterplotControlForm"]=b(function(e,k,d,j,i){this.compilerInfo=[2,">= 1.0.0-rc.3"];d=d||e.helpers;i=i||{};var g="",c,f="function",h=this.escapeExpression;g+='\n\n<div class="scatterplot-container chart-container tabbable tabs-left">\n    \n    <ul class="nav nav-tabs">\n        \n        <li class="active"><a href="#data-control" data-toggle="tab" class="tooltip"\n            title="Use this tab to change which data are used">Data Controls</a></li>\n        <li><a href="#chart-control" data-toggle="tab" class="tooltip"\n            title="Use this tab to change how the chart is drawn">Chart Controls</a></li>\n        <li><a href="#stats-display" data-toggle="tab" class="tooltip"\n            title="This tab will display overall statistics for your data">Statistics</a></li>\n        <li><a href="#chart-display" data-toggle="tab" class="tooltip"\n            title="This tab will display the chart">Chart</a>\n            \n            <div id="loading-indicator" style="display: none;">\n                <img class="loading-img" src="';if(c=d.loadingIndicatorImagePath){c=c.call(k,{hash:{},data:i})}else{c=k.loadingIndicatorImagePath;c=typeof c===f?c.apply(k):c}g+=h(c)+'" />\n                <span class="loading-message">';if(c=d.message){c=c.call(k,{hash:{},data:i})}else{c=k.message;c=typeof c===f?c.apply(k):c}g+=h(c)+'</span>\n            </div>\n        </li>\n    </ul>\n\n    \n    <div class="tab-content">\n        \n        <div id="data-control" class="tab-pane active">\n            \n        </div>\n    \n        \n        <div id="chart-control" class="tab-pane">\n            \n        </div>\n\n        \n        <div id="stats-display" class="tab-pane">\n            \n        </div>\n\n        \n        <div id="chart-display" class="tab-pane">\n            \n        </div>\n\n    </div>\n</div>';return g})})();