// dependencies
define(['utils/utils'], function(Utils) {

// plugin
var View = Backbone.View.extend({
    // options
    optionsDefault: {
        value   : '',
        min     : null,
        max     : null,
        step    : null,
        precise : false,
        split   : 10000
    },
    
    // initialize
    initialize : function(options) {
        // link this
        var self = this;
        
        // configure options
        this.options = Utils.merge(options, this.optionsDefault);
        
        // create new element
        this.setElement(this._template(this.options));
        
        // determine wether to use the slider
        this.useslider = this.options.max !== null && this.options.min !== null && this.options.max > this.options.min;
        
        // set default step size
        if (this.options.step === null) {
            this.options.step = 1;
            if (this.options.precise && this.useslider) {
                this.options.step = (this.options.max - this.options.min) / this.options.split;
            }
        }
        
        // create slider if min and max are defined properly
        if (this.useslider) {
            this.$slider = this.$el.find('#slider');
            this.$slider.slider(this.options);
            this.$slider.on('slide', function (event, ui) {
                self.value(ui.value);
            });
        } else {
            this.$el.find('.ui-form-slider-text').css('width', '100%');
        }
        
        // backup integer field
        this.$text = this.$el.find('#text');
        
        // add text field event
        this.$text.on('change', function () {
           self.value($(this).val());
        });
        
        // add text field event
        this.$text.on('keydown', function (event) {
            var v = event.which;
            if (!(v == 8 || v == 9 || v == 13 || v == 37 || v == 39 || v == 189 || (v >= 48 && v <= 57)
                || (self.options.precise && $(this).val().indexOf('.') == -1) && v == 190)) {
                event.preventDefault();
            }
        });
    },
    
    // value
    value : function (new_val) {
        if (new_val !== undefined) {
            // apply limit
            if (this.options.max !== null) {
                new_val = Math.min(new_val, this.options.max);
            }
            if (this.options.min !== null) {
                new_val = Math.max(new_val, this.options.min);
            }
            
            // trigger on change event
            if (this.options.onchange) {
                this.options.onchange(new_val);
            }
        
            // set values
            this.$slider && this.$slider.slider('value', new_val);
            this.$text.val(new_val);
        }
        
        // return current value
        return this.$text.val();
    },
    
    // element
    _template: function(options) {
        return  '<div id="' + options.id + '" class="ui-form-slider">' +
                    '<input id="text" type="text" class="ui-form-slider-text"/>' +
                    '<div id="slider" class="ui-form-slider-element"/>' +
                '</div>';
    }
});

return {
    View : View
};

});
