jlmd = function() {


// when the DOM loads
$(document).ready(function() {
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
    $("#"+user_id_map[msg[0]]).html = "<span class=\"color-scheme-message\">"+escape_html(msg[0])+"</span><br /><br />";
};

message_handlers[MSG_OUTPUT_OTHER] = function(msg) {
    // just print the output
    $("#"+user_id_map[msg[0]]).html = escape_html(msg[0]);
};

message_handlers[MSG_OUTPUT_FATAL_ERROR] = function(msg) {
    // print the error message
    $("#"+user_id_map[msg[0]]).html = "<span class=\"color-scheme-error\">"+escape_html(msg[0])+"</span><br /><br />";

    // stop processing new messages
    dead = true;
    inbox_queue = [];
    outbox_queue = [];
};

message_handlers[MSG_OUTPUT_EVAL_INPUT] = function(msg) {
}

message_handlers[MSG_OUTPUT_EVAL_INCOMPLETE] = function(msg) {
};

message_handlers[MSG_OUTPUT_EVAL_ERROR] = function(msg) {
    // print the error message
    $("#"+user_id_map[msg[0]]).html = "<span class=\"color-scheme-error\">"+escape_html(msg[1])+"</span><br /><br />";
};

message_handlers[MSG_OUTPUT_EVAL_RESULT] = function(msg) {
    // print the result
    if ($.trim(msg[1]) != ""){
        $("#"+user_name_map[msg[0]]).html(escape_html(msg[1]));
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

plotters["line"] = function(plot, location) {
    // local variables
    var xpad = 0,
        ypad = (plot.y_max-plot.y_min)*0.1,
        x = d3.scale.linear().domain([plot.x_min - xpad, plot.x_max + xpad]).range([0, plot.w]),
        y = d3.scale.linear().domain([plot.y_min - ypad, plot.y_max + ypad]).range([plot.h, 0]),
        xticks = x.ticks(8),
        yticks = y.ticks(8);

    // create an SVG canvas and a group to represent the plot area
    var vis = d3.select(location)
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

plotters["bar"] = function(plot, location) {
    var data = d3.zip(plot.x_data, plot.y_data); // coordinate pairs

    // local variables
    var x = d3.scale.linear().domain(d3.extent(plot.x_data)).range([0, plot.w]),
        y = d3.scale.linear().domain([0, d3.max(plot.y_data)]).range([0, plot.h]),
        xticks = x.ticks(8),
        yticks = y.ticks(8);

    // create an SVG canvas and a group to represent the plot area
    var vis = d3.select(location)
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
    var plottype = msg[1],
        plot = {
            "x_data": eval(msg[2]),
            "y_data": eval(msg[3]),
            "x_min": eval(msg[4]),
            "x_max": eval(msg[5]),
            "y_min": eval(msg[6]),
            "y_max": eval(msg[7])
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
        plotter(plot, "#"+msg[0]);
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

function calculate_block(index, dom_ele) {
    var code = $(dom_ele).find("pre").text();
// console.log($.toJSON([MSG_INPUT_EVAL, user_name, user_id, code]));
    var name = $(dom_ele).find(".juliaresult").attr('id');
console.log($.toJSON([MSG_INPUT_EVAL, name, user_id_map[name], code]));
console.log($.toJSON([MSG_INPUT_EVAL, name, user_id_map[name], code]));
    outbox_queue.push([MSG_INPUT_EVAL, name, user_id_map[name], code]);
    process_outbox();
}

function calculate() {
    $(".juliablock").each(calculate_block);
}

return{
    calculate:calculate,
    calculate_block:calculate_block
}

}();
