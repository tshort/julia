jlmd = function() {

var color_schemes = [
    ["Dark", {
        background_color: "#000000",
        text_color: "#dddddd",
        message_color: "#0000aa",
        error_color: "#ff0000",
        prompt_color: "#00bb00",
        plot_grid_color: "#333333",
        plot_axis_color: "#666666",
        plot_text_color: "#dddddd",
        plot_line_color: "#4d87c7",
        plot_rect_color: "#4d87c7",
        plot_rect_stroke_width: "0",
        plot_rect_stroke_color: "#FFFFFF",
    }],
    ["Light", {
        background_color: "#f8f8f8",
        text_color: "#444444",
        message_color: "#0000aa",
        error_color: "#ff0000",
        prompt_color: "#00aa00",
        plot_grid_color: "#dadada",
        plot_axis_color: "#aaaaaa",
        plot_text_color: "#444444",
        plot_line_color: "#4d87b7",
        plot_rect_color: "#4d87c7",
        plot_rect_stroke_width: "0",
        plot_rect_stroke_color: "#FFFFFF",
    }],
];

// the current color scheme
var current_color_scheme = 0;

// Fetch items out of local storage if they exist
if (Modernizr.localstorage) {
    if (localStorage.getItem("current_color_scheme")) {
        current_color_scheme = localStorage.getItem("current_color_scheme");
    }
}

// apply a particular color scheme -- call this every time the terminal content changes
function apply_color_scheme() {
    $("form#terminal-form").css("background-color", color_schemes[current_color_scheme][1].background_color);
    $("div#terminal").css("color", color_schemes[current_color_scheme][1].text_color);
    $("textarea#terminal-input").css("color", color_schemes[current_color_scheme][1].text_color);
    $("span.color-scheme-message").css("color", color_schemes[current_color_scheme][1].message_color);
    $("span.color-scheme-error").css("color", color_schemes[current_color_scheme][1].error_color);
    $("span.color-scheme-prompt").css("color", color_schemes[current_color_scheme][1].prompt_color);
    $("svg .hrule line, svg .vrule line").css("stroke", color_schemes[current_color_scheme][1].plot_grid_color);
    $("svg .hrule2 line, svg .vrule2 line").css("stroke", color_schemes[current_color_scheme][1].plot_axis_color);
    $("svg text").css("fill", color_schemes[current_color_scheme][1].plot_text_color);
    $("svg .line").css("stroke", color_schemes[current_color_scheme][1].plot_line_color);
    $("svg .rect").css("fill", color_schemes[current_color_scheme][1].plot_rect_color);
    $("svg .rect").css("stroke", color_schemes[current_color_scheme][1].plot_rect_stroke_width);
    
    if (Modernizr.localstorage) {
        localStorage.setItem("current_color_scheme", current_color_scheme);
    }
}


// when the DOM loads
$(document).ready(function() {
    apply_color_scheme();
    $.ajax({
        type: "GET",
        url: window.location.search.substring(1),
        success: function (response) {
            var converter = new Showdown.converter();
            $('#main_markdown').html(converter.makeHtml(response)); 
        }
    });
    setTimeout(init_session, 500);
});

/*
    Network Protol

    This needs to match the message
    types listed in ui/webserver/message_types.h.
*/

// input messages (to julia)
var MSG_INPUT_NULL              = 0;
var MSG_INPUT_START             = 1;
var MSG_INPUT_POLL              = 2;
var MSG_INPUT_EVAL              = 3;
var MSG_INPUT_REPLAY_HISTORY    = 4;
var MSG_INPUT_GET_USER          = 5;

// output messages (to the browser)
var MSG_OUTPUT_NULL             = 0;
var MSG_OUTPUT_WELCOME          = 1;
var MSG_OUTPUT_READY            = 2;
var MSG_OUTPUT_MESSAGE          = 3;
var MSG_OUTPUT_OTHER            = 4;
var MSG_OUTPUT_EVAL_INPUT       = 5;
var MSG_OUTPUT_FATAL_ERROR      = 6;
var MSG_OUTPUT_EVAL_INCOMPLETE  = 7;
var MSG_OUTPUT_EVAL_RESULT      = 8;
var MSG_OUTPUT_EVAL_ERROR       = 9;
var MSG_OUTPUT_PLOT             = 10;
var MSG_OUTPUT_GET_USER         = 11;

// active node for page calculating 
var $active_element = []; 

// map from user_id to and from user_name
var user_name_map = new Array();
var user_id_map = new Array();

// the user name
var user_name = "julia";

// the user id
var user_id = "";

// indent string
var indent_str = "    ";

// how long we delay in ms before polling the server again
var poll_interval = 300;

// how long before we drop a request and try anew

// keep track of whether we are waiting for a message (and don't send more if we are)
var waiting_for_response = false;

// a queue of messages to be sent to the server
var outbox_queue = [];

// a queue of messages from the server to be processed
var inbox_queue = [];

// keep track of whether new terminal data will appear on a new line
var new_line = true;

// keep track of whether we have received a fatal message
var dead = false;


// escape html
function escape_html(str) {
    // escape ampersands, angle brackets, tabs, and newlines
    return str.replace(/\t/g, "    ").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/\n/g, "<br />");
}

// indent and escape html
function indent_and_escape_html(str) {
    // indent newlines to line up with the end of the julia prompt
    return escape_html(str.replace(/\n/g, "\n       "));
}


// the first request
function init_session() {
    outbox_queue.push([MSG_INPUT_START, "jlmd_form", "jlmd"]);
    process_outbox();
    outbox_queue.push([MSG_INPUT_GET_USER]);
    process_outbox();
    $(".juliaresult").each(function(index, dom_ele) {
        var id = $(dom_ele).attr('id');
        outbox_queue.push([MSG_INPUT_START, id, "jlmd"]);
        process_outbox();
        outbox_queue.push([MSG_INPUT_GET_USER]);
        process_outbox();
    });
}

// check the server for data
function poll() {
    // send a poll message
    outbox_queue.push([MSG_INPUT_POLL]);
    process_outbox();
}

// send the messages in the outbox
function process_outbox() {
    // don't make new requests if we're waiting for old ones
    if (!waiting_for_response) {
        // don't send a request if there are no messages
        if (outbox_queue.length > 0) {
            // don't send any more requests while we're waiting for this one
            waiting_for_response = true;

            // send the messages
			$.ajax({
				type: "POST",
				url: "/repl.scgi",
				data: {"request": $.toJSON(outbox_queue)},
				dataType: "json",
				timeout: 500, // in milliseconds
				success: callback,
				error: function(request, status, err) {
				    //TODO: proper error handling
					if(status == "timeout") {
						waiting_for_response = false;
						setTimeout(poll,poll_interval);
					}
				}
		});
        }

        // we sent all the messages at once so clear the outbox
        outbox_queue = [];
    }
}

// an array of message handlers
var message_handlers = [];

message_handlers[MSG_OUTPUT_NULL] = function(msg) {}; // do nothing

message_handlers[MSG_OUTPUT_READY] = function(msg) {
};

message_handlers[MSG_OUTPUT_MESSAGE] = function(msg) {
    // print the message
    $("#"+user_id_map[msg[0]]).html("<span class=\"color-scheme-message\">"+escape_html(msg[0])+"</span><br /><br />");
};

message_handlers[MSG_OUTPUT_OTHER] = function(msg) {
    // just print the output
    var payload = msg[0];
    var res = $active_element.find(".juliaresult");
    var is_empty = res.html() == "";
    if ($active_element.attr("output") == "markdown") {
        var converter = new Showdown.converter();
        payload = converter.makeHtml(payload);
    } else {
        payload = escape_html(payload);
    }
    if (!is_empty) {
        payload = res.html() + "<br />" + payload;
    }
    res.html(payload);
};

message_handlers[MSG_OUTPUT_FATAL_ERROR] = function(msg) {
    // print the error message
    $("#jlmd_error_div").html("<span class=\"color-scheme-error\">"+escape_html(msg[0])+"</span><br /><br />");

    // stop processing new messages
    dead = true;
    inbox_queue = [];
    outbox_queue = [];
};

message_handlers[MSG_OUTPUT_EVAL_INPUT] = function(msg) {
    console.log("EVAL_INPUT", $("#"+msg[1]));
    $active_element = $("#"+msg[1]).parents(".juliablock").first();
}

message_handlers[MSG_OUTPUT_EVAL_INCOMPLETE] = function(msg) {
    $("#jlmd_error_div").html("<span class=\"color-scheme-error\">"+escape_html(msg[1])+"</span><br /><br />");
};

message_handlers[MSG_OUTPUT_EVAL_ERROR] = function(msg) {
    // print the error message
    $("#jlmd_error_div").html("<span class=\"color-scheme-error\">"+escape_html(msg[1])+"</span><br /><br />");
};

message_handlers[MSG_OUTPUT_EVAL_RESULT] = function(msg) {
    // print the result
    // if ($.trim(msg[1]) != ""){
    //     $("#"+user_name_map[msg[0]]).html($("#"+user_name_map[msg[0]]).html() + escape_html(msg[1]));
    // }
    var payload = msg[1];
    var res = $active_element.find(".juliaresult");
    var is_empty = res.html() == "";
    if ($active_element.attr("output") == "markdown") {
        var converter = new Showdown.converter();
        payload = converter.makeHtml(payload);
    } else {
        payload = escape_html(payload);
    }
    if (!is_empty) {
        payload = res.html() + "<br />" + payload;
    }
    if (res.attr("id") == user_name_map[msg[0]]) {
        res.html(payload);
        console.log("NEXT_NODE", next_node($active_element));
        calculate_block(next_node($active_element));
    }
};

message_handlers[MSG_OUTPUT_GET_USER] = function(msg) {
    // set the user name
    user_name = indent_and_escape_html(msg[0]);
    user_id = indent_and_escape_html(msg[1]);
    user_name_map[user_id] = user_name;        
    user_id_map[user_name] = user_id;        
}

var plotters = {};

plotters["line"] = function(plot) {
    // local variables
    var xpad = 0,
        ypad = (plot.y_max-plot.y_min)*0.1,
        x = d3.scale.linear().domain([plot.x_min - xpad, plot.x_max + xpad]).range([0, plot.w]),
        y = d3.scale.linear().domain([plot.y_min - ypad, plot.y_max + ypad]).range([plot.h, 0]),
        xticks = x.ticks(8),
        yticks = y.ticks(8);

    // create an SVG canvas and a group to represent the plot area
    var vis = d3.select("#"+$active_element.find(".juliaresult").attr('id'))
      .append("svg")
        .data([d3.zip(plot.x_data, plot.y_data)]) // coordinate pairs
        .attr("width", plot.w+plot.p*2)
        .attr("height", plot.h+plot.p*2)
      .append("g")
        .attr("transform", "translate("+String(plot.p)+","+String(plot.p)+")");

    // vertical tics
    var vrules = vis.selectAll("g.vrule")
        .data(xticks)
      .enter().append("g")
        .attr("class", "vrule");

    // horizontal tics
    var hrules = vis.selectAll("g.hrule")
        .data(yticks)
      .enter().append("g")
        .attr("class", "hrule");

    // vertical lines
    vrules.filter(function(d) { return (d != 0); }).append("line")
        .attr("x1", x)
        .attr("x2", x)
        .attr("y1", 0)
        .attr("y2", plot.h - 1);

    // horizontal lines
    hrules.filter(function(d) { return (d != 0); }).append("line")
        .attr("y1", y)
        .attr("y2", y)
        .attr("x1", 0)
        .attr("x2", plot.w + 1);

    // x-axis labels
    vrules.append("text")
        .attr("x", x)
        .attr("y", plot.h + 10)
        .attr("dy", ".71em")
        .attr("text-anchor", "middle")
        .text(x.tickFormat(10));

    // y-axis labels
    hrules.append("text")
        .attr("y", y)
        .attr("x", -5)
        .attr("dy", ".35em")
        .attr("text-anchor", "end")
        .text(y.tickFormat(10));

    // y-axis
    var vrules2 = vis.selectAll("g.vrule2")
        .data(xticks)
      .enter().append("g")
        .attr("class", "vrule2");

    // x-axis
    var hrules2 = vis.selectAll("g.hrule2")
        .data(yticks)
      .enter().append("g")
        .attr("class", "hrule2");

    // y-axis line
    vrules2.filter(function(d) { return (d == 0); }).append("line")
        .attr("x1", x)
        .attr("x2", x)
        .attr("y1", 0)
        .attr("y2", plot.h - 1);

    // x-axis line
    hrules2.filter(function(d) { return (d == 0); }).append("line")
        .attr("y1", y)
        .attr("y2", y)
        .attr("x1", 0)
        .attr("x2", plot.w + 1);

    // actual plot curve
    vis.append("path")
        .attr("class", "line")
        .attr("d", d3.svg.line()
        .x(function(d) { return x(d[0]); })
        .y(function(d) { return y(d[1]); }));

};

plotters["bar"] = function(plot) {
    var data = d3.zip(plot.x_data, plot.y_data); // coordinate pairs

    // local variables
    var x = d3.scale.linear().domain(d3.extent(plot.x_data)).range([0, plot.w]),
        y = d3.scale.linear().domain([0, d3.max(plot.y_data)]).range([0, plot.h]),
        xticks = x.ticks(8),
        yticks = y.ticks(8);
    // create an SVG canvas and a group to represent the plot area
    var vis = d3.select("#"+$active_element.find(".juliaresult").attr('id'))
      .append("svg")
        .data([data])
        .attr("width", plot.w+plot.p*2)
        .attr("height", plot.h+plot.p*2)
      .append("g")
        .attr("transform", "translate("+String(plot.p)+","+String(plot.p)+")");

    // horizontal ticks
    var hrules = vis.selectAll("g.hrule")
        .data(yticks)
      .enter().append("g")
        .attr("class", "hrule")
        .attr("transform", function(d) { return "translate(0," + (plot.h-y(d)) + ")"; });

    // horizontal lines
    hrules.append("line")
        .attr("x1", 0)
        .attr("x2", plot.w);

    // y-axis labels
    hrules.append("text")
        .attr("x", -5)
        .attr("dy", ".35em")
        .attr("text-anchor", "end")
        .text(y.tickFormat(10));

    // x-axis rules container
    var vrules = vis.selectAll("g.vrule")
        .data(xticks)
        .enter().append("g")
        .attr("class", "vrule")
        .attr("transform", function(d) { return "translate(" + (x(d)) + ",0)"; });

    // x-axis labels
    vrules.append("text")
        .attr("y", plot.h + 20)
        .attr("dx", "0")
        .attr("text-anchor", "middle")
        .text(x.tickFormat(10));

    // Redfining domain/range to fit the bars within the width
    x.domain([0, 1]).range([0, plot.w/data.length]);

    // actual plot curve
    vis.selectAll("rect")
        .data(data)
        .enter().append("rect")
        .attr("class", "rect")
        .attr("x", function(d, i) { return x(i); })
        .attr("y", function(d) { return plot.h - y(d[1]); })
        .attr("width", (plot.w - plot.p*2) / data.length)
        .attr("height", function(d) { return y(d[1]); });

};

message_handlers[MSG_OUTPUT_PLOT] = function(msg) {
    var plottype = msg[0],
        plot = {
            "x_data": eval(msg[1]),
            "y_data": eval(msg[2]),
            "x_min": eval(msg[3]),
            "x_max": eval(msg[4]),
            "y_min": eval(msg[5]),
            "y_max": eval(msg[6])
        },
        plotter = plotters[plottype];

    // TODO:
    // * calculate dynamically based on window size
    // * update above calculation with window resize
    // * allow user to resize
    plot.w = 450;
    plot.h = 275;
    plot.p = 40;

    if (typeof plotter == "function")
        plotter(plot);
};

// process the messages in the inbox
function process_inbox() {
    // iterate through the messages
    for (var id in inbox_queue) {
        console.log("inbox");
        var msg = inbox_queue[id],
            type = msg[0], msg = msg.slice(1),
            handler = message_handlers[type];
        console.log(type, msg);
        if (typeof handler == "function") {
            handler(msg);
        }
        if (dead)
            break;
    }

    // we handled all the messages so clear the inbox
    inbox_queue = [];
}

// called when the server has responded
function callback(data, textStatus, jqXHR) {
    // if we are dead, don't keep polling the server
    if (dead)
        return;

    // allow sending new messages
    waiting_for_response = false;

    // add the messages to the inbox
    inbox_queue = inbox_queue.concat(data);

    // process the inbox
    process_inbox();

    // send any new messages
    process_outbox();

    // poll the server again shortly
    setTimeout(poll, poll_interval);
}

function calculate_form(index, dom_ele) {
    if (dom_ele.type == "text") {
        outbox_queue.push([MSG_INPUT_EVAL, "jlmd_form", user_id_map["jlmd_form"], dom_ele.name + "= \"" + dom_ele.value + "\""]);
    } else if (dom_ele.type == "radio" && dom_ele.checked) {
        outbox_queue.push([MSG_INPUT_EVAL, "jlmd_form", user_id_map["jlmd_form"], dom_ele.name + "= \"" + dom_ele.value + "\""]);
    } else if (dom_ele.type == "checkbox") {
        outbox_queue.push([MSG_INPUT_EVAL, "jlmd_form", user_id_map["jlmd_form"], dom_ele.value + "= " + ((dom_ele.checked) ? "true" : "false")]);
    } else if (dom_ele.nodeName.toLowerCase() == "select") {
        outbox_queue.push([MSG_INPUT_EVAL, "jlmd_form", user_id_map["jlmd_form"], dom_ele.name + "= \"" + dom_ele[dom_ele.selectedIndex].text + "\""]);
    } 
}

function calculate_block(dom_ele) {
    if (dom_ele.length == 0) return;
    var code = $(dom_ele).find("pre").text();
    var name = $(dom_ele).find(".juliaresult").attr('id');
    $(dom_ele).find(".juliaresult").html("");
    outbox_queue.push([MSG_INPUT_EVAL, name, user_id_map[name], code]);
    process_outbox();
}

function next_node(node) { // non-recursive
// Return the next calculatable node.
// Traverses the DOM tree starting at the DOM node "node".
// Keeps going until it finds a "calculatable" DOM node.
    var starting_node = node;
    // while (node.length > 0) {
        n = node.children(".juliablock") // try children
        console.log("NEXT_NODE children", n);
        if (n.length > 0) {
            return n.first();
        } 
        n = node.nextAll(".juliablock") // try siblings
        if (n.length > 0) { 
            return n.first();
        } 
        // while (node.next().length > 0 && (node.nodeType != 1 || node.nodeName != 'BODY') && node != starting_node) { 
        //     node = node.parent();
        // }   
        // if (node.nodeName == 'BODY' || node == starting_node) {
        //     return [];
        // }
    // }
    return [];
}  

function calculate() {
    // $active_element = next_node($("#main_markdown"));
    $active_element = next_node($("#main_markdown"));
    $(":input").each(calculate_form); 
    process_outbox();
    console.log("ACTIVE EL",$active_element);
    if ($active_element.length > 0) {
        calculate_block($active_element);
    }
}

return{
    calculate:calculate,
    calculate_block:calculate_block
}

}();
