define(["libs/backbone/backbone-relational"],function(){var a=Backbone.View.extend({el_master:"#masthead",initialize:function(c){this.setElement($(this.template()));$(this.el_master).append($(this.el))},events:{mousedown:function(c){c.preventDefault()}},append:function(c){$(this.el).append($(c.el))},prepend:function(c){$(this.el).prepend($(c.el))},template:function(){return'<div class="iconbar"></div>'}});var b=Backbone.View.extend({options:{id:"galaxy-icon",icon:"fa-icon-cog",tooltip:"galaxy-icon",with_number:false,on_click:function(){alert("clicked")},visible:true},initialize:function(d){if(d){this.options=_.defaults(d,this.options)}this.setElement($(this.template(this.options)));var c=this;$(this.el).find(".icon").tooltip({title:this.options.tooltip}).on("click",c.options.on_click);if(!this.options.visible){this.hide()}},show:function(){$(this.el).css({visibility:"visible"})},hide:function(){$(this.el).css({visibility:"hidden"})},icon:function(c){$(this.el).find(".icon").removeClass(this.options.icon).addClass(c);this.options.icon=c},toggle:function(){$(this.el).addClass("toggle")},untoggle:function(){$(this.el).removeClass("toggle")},number:function(c){$(this.el).find(".number").text(c)},template:function(d){var c="<div id="+d.id+' class="symbol"><div class="icon fa-icon-2x '+d.icon+'"></div>';if(d.with_number){c+='<div class="number"></div>'}c+="</div>";return c}});return{GalaxyMaster:a,GalaxyMasterIcon:b}});