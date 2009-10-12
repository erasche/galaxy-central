/* Trackster
    2009, James Taylor, Kanwei Li
*/

var DENSITY = 1000,
    DATA_ERROR = "There was an error in indexing this dataset.",
    DATA_NONE = "No data for this chrom/contig.",
    CACHED_TILES = 200,
    CACHED_DATA = 20;

var View = function( chrom, max_length ) {
    this.chrom = chrom;
    this.tracks = [];
    this.max_low = 0;
    this.max_high = max_length;
    this.low = this.max_low;
    this.high = this.max_high;
    this.length = this.max_high - this.max_low;
};
$.extend( View.prototype, {
    add_track: function ( track ) {
        track.view = this;
        this.tracks.push( track );
        if (track.init) { track.init(); }
    },
    redraw: function () {
        // Overview
        $("#overview-box").css( {
            left: ( this.low / this.length ) * $("#overview-viewport").width(),
            width: Math.max( 4, ( ( this.high - this.low ) / this.length ) * $("#overview-viewport").width() )
        }).show();
        $("#low").text( this.low );
        $("#high").text( this.high );
        for ( var i = 0, len = this.tracks.length; i < len; i++ ) {
            this.tracks[i].draw();
        }
        $("#bottom-spacer").remove();
        $("#viewport").append('<div id="bottom-spacer" style="height: 200px;"></div>');
    },
    move: function ( new_low, new_high ) {
        this.low = Math.max( this.max_low, Math.floor( new_low ) );
        this.high = Math.min( this.length, Math.ceil( new_high ) );
    },
    zoom_in: function ( factor, point ) {
        if (this.max_high === 0) {
            return;
        }
        
        var range = this.high - this.low;
        var diff = range / factor / 2;
        var center;
        
        if (point === undefined) {
            center = ( this.low + this.high ) / 2;
        } else {
            center = this.low + range * point / $(document).width();
        }
        this.low = Math.floor( center - diff );
        this.high = Math.ceil( center + diff );
        if (this.low < this.max_low) {
            this.low = this.max_low;
            this.high = range / factor;
        } else if (this.high > this.max_high) {
            this.high = this.max_high;
            this.low = this.max_high - range / factor;
            // console.log(this.high, this.low);
        } 
        if (this.high - this.low < 1 ) {
            this.high = this.low + 1;
        }
    },
    zoom_out: function ( factor ) {
        if (this.max_high === 0) {
            return;
        }
        var center = ( this.low + this.high ) / 2;
        var range = this.high - this.low;
        var diff = range * factor / 2;
        this.low = Math.floor( Math.max( 0, center - diff ) );
        this.high = Math.ceil( Math.min( this.length, center + diff ) );
    },
    left: function( factor ) {
        var range = this.high - this.low;
        var diff = Math.floor( range / factor );
        if ( this.low - diff < 0 ) {
            this.low = 0;
            this.high = this.low + range;
        } else {
            this.low -= diff;
            this.high -= diff;
        }
    },
    right: function ( factor ) {
        var range = this.high - this.low;
        var diff = Math.floor( range / factor );
        if ( this.high + diff > this.length ) {
            this.high = this.length;
            this.low = this.high - range;
        } else {
            this.low += diff;
            this.high += diff;
        }
    }
});

var Track = function ( name, parent_element ) {
    this.name = name;
    this.parent_element = parent_element;
    this.make_container();
};
$.extend( Track.prototype, {
    make_container: function () {
        this.header_div = $("<div class='track-header'>").text( this.name );
        this.content_div = $("<div class='track-content'>");
        this.container_div = $("<div class='track'></div>").append( this.header_div ).append( this.content_div );
        this.parent_element.append( this.container_div );
    }
});

var TiledTrack = function() {
    this.tile_cache = new Cache(CACHED_TILES);
};
$.extend( TiledTrack.prototype, Track.prototype, {
    draw: function() {
        var low = this.view.low,
            high = this.view.high,
            range = high - low;

        var resolution = Math.pow( 10, Math.ceil( Math.log( range / DENSITY ) / Math.log( 10 ) ) );
        resolution = Math.max( resolution, 1 );
        resolution = Math.min( resolution, 100000 );

	    var parent_element = $("<div style='position: relative;'></div>");
            this.content_div.children( ":first" ).remove();
            this.content_div.append( parent_element );

        var w = this.content_div.width(),
            h = this.content_div.height(),
	        w_scale = w / range;

        var tile_element;
        // Index of first tile that overlaps visible region
        var tile_index = Math.floor( low / resolution / DENSITY );
        while ( ( tile_index * DENSITY * resolution ) < high ) {
            // Check in cache
            var key = w_scale + "_" + tile_index;
            if ( this.tile_cache[key] ) {
                // console.log("cached tile");
                tile_element = this.tile_cache[key];
                var tile_low = tile_index * DENSITY * resolution;
                tile_element.css( {
                    left: ( tile_low - this.view.low ) * w_scale
                });
                // Our responsibility to move the element to the new parent
                parent_element.append( tile_element );
            } else {
                tile_element = this.draw_tile( resolution, tile_index, parent_element, w_scale, h );
            }
            if ( tile_element ) {
                this.tile_cache[key] = tile_element;
            }
            tile_index += 1;
        }
    }
});

var LabelTrack = function ( parent_element ) {
    Track.call( this, null, parent_element );
    this.container_div.addClass( "label-track" );
};
$.extend( LabelTrack.prototype, Track.prototype, {
    draw: function() {
        var view = this.view,
            range = view.high - view.low,
            tickDistance = Math.floor( Math.pow( 10, Math.floor( Math.log( range ) / Math.log( 10 ) ) ) ),
            position = Math.floor( view.low / tickDistance ) * tickDistance,
            width = this.content_div.width(),
            new_div = $("<div style='position: relative; height: 1.3em;'></div>");
        while ( position < view.high ) {
            var screenPosition = ( position - view.low ) / range * width;
            new_div.append( $("<div class='label'>" + position + "</div>").css( {
                position: "absolute",
                // Reduce by one to account for border
                left: screenPosition - 1
            }));
            position += tickDistance;
        }
        this.content_div.children( ":first" ).remove();
        this.content_div.append( new_div );
    }
});

var LineTrack = function ( name, dataset_id, height ) {
    Track.call( this, name, $("#viewport") );
    TiledTrack.call( this );
    
    this.track_type = "line";
    this.height_px = (height ? height : 100);
    this.container_div.addClass( "line-track" );
    this.dataset_id = dataset_id;
    this.cache = new Cache(CACHED_DATA); // We need to cache some data because of
                                         // asynchronous calls
};
$.extend( LineTrack.prototype, TiledTrack.prototype, {
    init: function() {
        var track = this;
        $.getJSON( data_url, {  stats: true, track_type: track.track_type,
                                chrom: track.view.chrom, low: null, high: null,
                                dataset_id: track.dataset_id }, function ( data ) {
            if (!data || data == "error") {
                track.content_div.addClass("error").text(DATA_ERROR);
            } else if (data == "no data") {
                track.content_div.addClass("nodata").text(DATA_NONE);
            } else {
                track.content_div.css( "height", track.height_px + "px" );
                track.min_value = data.min;
                track.max_value = data.max;
                track.vertical_range = track.max_value - track.min_value;
                track.view.redraw();
            }
        });
    },
    get_data: function( resolution, position ) {
        var track = this,
            low = position * DENSITY * resolution,
            high = ( position + 1 ) * DENSITY * resolution,
            key = resolution + "_" + position;
            
        $.getJSON( data_url, { track_type: this.track_type, chrom: this.view.chrom, low: low, high: high, dataset_id: this.dataset_id }, function ( data ) {
            track.cache[key] = data;
            $(document).trigger( "redraw" );
        });
    },
    draw_tile: function( resolution, tile_index, parent_element, w_scale, h_scale ) {
        if (!this.vertical_range) { // We don't have the necessary information yet
            return;
        }
        
        var tile_low = tile_index * DENSITY * resolution,
            tile_length = DENSITY * resolution,
            canvas = $("<canvas class='tile'></canvas>"),
            key = resolution + "_" + tile_index;
        
        if (!this.cache[key]) {
            this.get_data( resolution, tile_index );
            return;
        }
        
        var data = this.cache[key];
        canvas.css( {
            position: "absolute",
            top: 0,
            left: ( tile_low - this.view.low ) * w_scale
        });
                
        canvas.get(0).width = Math.ceil( tile_length * w_scale );
        canvas.get(0).height = this.height_px;
        var ctx = canvas.get(0).getContext("2d");
        var in_path = false;
        ctx.beginPath();
        for ( var i = 0; i < data.length - 1; i++ ) {
            var x = data[i][0] - tile_low;
            var y = data[i][1];
            // Missing data causes us to stop drawing
            if ( isNaN( y ) ) {
                in_path = false;
            } else {
                // Translate
                x = x * w_scale;
                y = (y - this.min_value) / this.vertical_range * this.height_px;
                if ( in_path ) {
                    ctx.lineTo( x, y );
                } else {
                    ctx.moveTo( x, y );
                    in_path = true;
                }
            }
        }
        ctx.stroke();
        parent_element.append( canvas );
        return canvas;
    }
});

var FeatureTrack = function ( name, dataset_id, height ) {
    Track.call( this, name, $("#viewport") );
    TiledTrack.call( this );
    
    this.track_type = "feature";
    this.height_px = (height ? height : 100);
    this.container_div.addClass( "feature-track" );
    this.dataset_id = dataset_id;
    this.zo_slots = {};
    this.show_labels_scale = 0.001;
    this.showing_labels = false;
    this.vertical_gap = 10;
};
$.extend( FeatureTrack.prototype, TiledTrack.prototype, {
    init: function() {
        var track = this;
        $.getJSON( data_url, {  track_type: track.track_type, low: track.view.max_low, 
                                high: track.view.max_high, dataset_id: track.dataset_id,
                                chrom: track.view.chrom }, function ( data ) {
            if (data == "error") {
                track.content_div.addClass("error").text(DATA_ERROR);
            } else if (data.length === 0 || data == "no data") {
                track.content_div.addClass("nodata").text(DATA_NONE);
            } else {
                track.content_div.css( "height", track.height_px + "px" );
                track.values = data;
                track.calc_slots();
                track.slots = track.zo_slots;
                track.draw();
            }
        });
    },
    calc_slots: function( include_labels ) {
        // console.log("num vals: " + this.values.length);
        var end_ary = [],
            scale = this.container_div.width() / (this.view.high - this.view.low),
            labels_scale = this.show_labels_scale,
            max_high = this.view.max_high,
            max_low = this.view.max_low;
        // console.log(scale, this.view.high, this.view.low);
        if (include_labels) {
            this.zi_slots = {};
        }
        var dummy_canvas = $("<canvas></canvas>").get(0).getContext("2d");
        for (var i = 0, len = this.values.length; i < len; i++) {
            var f_start, f_end, feature = this.values[i];
            if (include_labels) {
                f_start = Math.floor( Math.max(max_low, (feature.start - max_low) * labels_scale) );
                f_start -= dummy_canvas.measureText(feature.name).width;
                f_end = Math.ceil( Math.min(max_high, (feature.end - max_low) * labels_scale) );
            } else {
                f_start = Math.floor( Math.max(max_low, (feature.start - max_low) * scale) );
                f_end = Math.ceil( Math.min(max_high, (feature.end - max_low) * scale) );
            }
            // if (include_labels) { console.log(f_start, f_end); }
            var j = 0;
            while (true) {
                if (end_ary[j] === undefined || end_ary[j] < f_start) {
                    end_ary[j] = f_end;
                    if (include_labels) {
                        this.zi_slots[feature.name] = j;
                    } else {
                        this.zo_slots[feature.name] = j;
                    }
                    break;
                }
                j++;
            }
        }
        this.height_px = end_ary.length * this.vertical_gap + 15;
        this.content_div.css( "height", this.height_px + "px" );
    },
    draw_tile: function( resolution, tile_index, parent_element, w_scale, h_scale ) {
        if (!this.values) { // Still loading
            return null;
        }
         // Once we zoom in enough, show name labels
        if (w_scale > this.show_labels_scale && !this.showing_labels) {
            this.showing_labels = true;
            if (!this.zi_slots) {
                this.calc_slots(true); 
            }
            this.slots = this.zi_slots;
        } else if (w_scale <= this.show_labels_scale && this.showing_labels) {
            this.showing_labels = false;
            this.slots = this.zo_slots;
        }
        // console.log(this.slots);
        
        var tile_low = tile_index * DENSITY * resolution,
            tile_high = ( tile_index + 1 ) * DENSITY * resolution,
            tile_length = DENSITY * resolution;
        // console.log(tile_low, tile_high, tile_length, w_scale);
        var width = Math.ceil( tile_length * w_scale ),
            height = this.height_px,
            new_canvas = $("<canvas class='tile'></canvas>");
        
        new_canvas.css({
            position: "absolute",
            top: 0,
            left: ( tile_low - this.view.low ) * w_scale
        });
        new_canvas.get(0).width = width;
        new_canvas.get(0).height = height;
        // console.log(( tile_low - this.view.low ) * w_scale, tile_index, w_scale);
        var ctx = new_canvas.get(0).getContext("2d");
        ctx.fillStyle = "#000";
        ctx.font = "10px monospace";
        ctx.textAlign = "right";
        
        var j = 0;
        for (var i = 0, len = this.values.length; i < len; i++) {
            var feature = this.values[i];
            if (feature.start <= tile_high && feature.end >= tile_low) {
                var f_start = Math.floor( Math.max(0, (feature.start - tile_low) * w_scale) ),
                    f_end   = Math.ceil( Math.min(width, (feature.end - tile_low) * w_scale) ),
                    y_center = this.slots[feature.name] * this.vertical_gap;
                    
                // console.log(feature.start, feature.end, f_start, f_end, j);
                ctx.fillRect(f_start, y_center + 5, f_end - f_start, 1);
                
                if (this.showing_labels && ctx.fillText) {
                    ctx.fillText(feature.name, f_start, y_center + 8);
                }
                
                var exon_start, exon_end;
                if (feature.exon_start && feature.exon_end) {
                    exon_start = Math.floor( Math.max(0, (feature.exon_start - tile_low) * w_scale) );
                    exon_end = Math.ceil( Math.min(width, (feature.exon_end - tile_low) * w_scale) );
                    ctx.fillRect(exon_start, y_center + 4, exon_end - exon_start, 3);
                }
                
                if (feature.blocks) {
                    for (var k = 0, k_len = feature.blocks.length; k < k_len; k++) {
                        var block = feature.blocks[k],
                            block_start = Math.floor( Math.max(0, (block[0] - tile_low) * w_scale) ),
                            block_end = Math.ceil( Math.min(width, (block[1] - tile_low) * w_scale) );
                        var thickness = 3, y_start = 4;
                        if (exon_start && block_start >= exon_start && block_end <= exon_end) {
                            thickness = 5;
                            y_start = 3;
                        }                    
                        ctx.fillRect(block_start, y_center + y_start, block_end - block_start, thickness);
                        // console.log(block_start, block_end);
                    }
                }
                j++;
            }
        }        

        parent_element.append( new_canvas );
        return new_canvas;
    }
});
