var startRoot =
        {type: "selection", name: "selection", children: [
            {type: "array", name: "group", children: [
                {type: "element", name: "tr"},
                {type: "element", name: "tr"},
                {type: "element", name: "tr"},
                {type: "element", name: "tr"}
            ]}
        ]};
var startHeight = 24 * 4;
var endRoot =
        {type: "selection", name: "kcsdw", children: [
            {type: "array", name: "kcsdw", children: [
                {type: "element", name: "a"},
                {type: "element", name: "b"},
                {type: "element", name: "c"},
                {type: "element", name: "d"}
            ]},
            {type: "array", name: "jjagars", children: [
                {type: "element", name: "o_files"},
                {type: "element", name: "o_data"}
            ]},
            {type: "array", name: "smendenh", children: [
                {type: "element", name: "table1"},
                {type: "element", name: "table2"},
                {type: "element", name: "table3"},
                {type: "element", name: "table4"}
            ]}
        ]};
var endHeight = 24 * 10;
var data1 = endRoot,
    data1Height = endHeight;

var data2 =
    {type: "selection", name: "kcsdw", children: [
        {type: "array", name: "kcsdw", children: [
            {type: "element", name: "a"},
            {type: "element", name: "b"},
            {type: "element", name: "c"},
            {type: "element", name: "d"}
        ]},
        {type: "array", name: "jjagars", children: [
            {type: "element", name: "o_files"},
            {type: "element", name: "o_data"}
        ]},
        {type: "array", name: "smendenh", children: [
            {type: "element", name: "table1"},
            {type: "element", name: "table2"},
            {type: "element", name: "table3"},
            {type: "element", name: "table4"}
        ]},
        {type: "array", name: "miclark", children: [
            {type: "element", name: "table5"},
            {type: "element", name: "table6"},
            {type: "element", name: "table7"},
            {type: "element", name: "table8"}
        ]}
    ]};
var data2Height = 24 * 14;

function doSelectAllAnimation () {
    selectAllAnimation(
        startRoot,
        startHeight,
        endRoot,
        endHeight
    ).on("start", function() {
        d3.select("#select-all-1-1").style("background", null);
    }).on("middle", function() {
        d3.select("#select-all-1-1").style("background", null);
    }).on("end", function() {
        d3.select("#select-all-1-2").style("background", null);
    }).on("reset", function() {
        d3.selectAll("#select-all-1-1,#select-all-1-2").style("background", null);
    });
}

function doAddTreeData () {
    selectAllData(
        data1,
        data1Height
    )
}

function name(d) {
    return d.name;
}

var margin = {top: 0, right: 40, bottom: 0, left: 40},
width = 720,
step = 100;

var svg = null;

function tree(leftRoot, rightRoot, outerHeight) {
    if (arguments.length < 3) {
        outerHeight = rightRoot, rightRoot = null;
    }

    var height = outerHeight - margin.top - margin.bottom;

    var tree = d3.layout.tree()
        .size([height, 1])
        .separation(function() { return 1; });

    if(!svg) {
        svg = d3.select("body").append("svg")
            .attr("width", width + margin.left + margin.right)
            .attr("height", height + margin.top + margin.bottom)
            .style("margin", "1em 0 1em " + -margin.left + "px");
    }

    var g = svg.selectAll("g")
        .data([].concat(
            leftRoot ? {type: "left", nodes: tree.nodes(leftRoot)} : [],
            rightRoot ? {type: "right", nodes: tree.nodes(rightRoot).map(flip), flipped: true} : []
        ))
        .enter().append("g")
        .attr("class", function(d) { return d.type; })
        .attr("transform", function(d) { return "translate(" + (!!d.flipped * width + margin.left) + "," + margin.top + ")"; });

    var link = g.append("g")
        .attr("class", "link")
        .selectAll("path")
        .data(function(d) { return tree.links(d.nodes); })
        .enter().append("path")
        .attr("class", linkType);

    var node = g.append("g")
        .attr("class", "node")
        .selectAll("g")
        .data(function(d) { return d.nodes; })
        .enter().append("g")
        .attr("class", function(d) { return d.type; });

    node.append("rect");

    node.append("text")
        .attr("dy", ".35em")
        .text(function(d) { return d.name; })
        .each(function(d) { d.width = Math.max(32, this.getComputedTextLength() + 12); })
        .attr("x", function(d) { return d.flipped ? 6 - d.width : 6; });

    node.filter(function(d) { return "join" in d; })
        .insert("path", "text")
        .attr("class", "join");

    svg.call(reset);

    function flip(d) {
        d.depth *= -1;
        d.flipped = true;
        return d;
    }

    return svg;
}

//function tree(leftRoot, rightRoot, outerHeight) {
//    if (arguments.length < 3) {
//        outerHeight = rightRoot, rightRoot = null;
//    }
//
//    var height = outerHeight - margin.top - margin.bottom;
//
//    var tree = d3.layout.tree()
//        .size([height, 1])
//        .separation(function() { return 1; });
//
//
//    var svg = d3.select("body").append("svg")
//        .attr("width", width + margin.left + margin.right)
//        .attr("height", height + margin.top + margin.bottom)
//        .style("margin", "1em 0 1em " + -margin.left + "px");
//
//    var g = svg.selectAll("g")
//        .data([].concat(
//            leftRoot ? {type: "left", nodes: tree.nodes(leftRoot)} : [],
//            rightRoot ? {type: "right", nodes: tree.nodes(rightRoot).map(flip), flipped: true} : []
//        ))
//        .enter().append("g")
//        .attr("class", function(d) { return d.type; })
//        .attr("transform", function(d) { return "translate(" + (!!d.flipped * width + margin.left) + "," + margin.top + ")"; });
//
//    var link = g.append("g")
//        .attr("class", "link")
//        .selectAll("path")
//        .data(function(d) { return tree.links(d.nodes); })
//        .enter().append("path")
//        .attr("class", linkType);
//
//    var node = g.append("g")
//        .attr("class", "node")
//        .selectAll("g")
//        .data(function(d) { return d.nodes; })
//        .enter().append("g")
//        .attr("class", function(d) { return d.type; });
//
//    node.append("rect");
//
//    node.append("text")
//        .attr("dy", ".35em")
//        .text(function(d) { return d.name; })
//        .each(function(d) { d.width = Math.max(32, this.getComputedTextLength() + 12); })
//        .attr("x", function(d) { return d.flipped ? 6 - d.width : 6; });
//
//    node.filter(function(d) { return "join" in d; })
//        .insert("path", "text")
//        .attr("class", "join");
//
//    svg.call(reset);
//
//    function flip(d) {
//        d.depth *= -1;
//        d.flipped = true;
//        return d;
//    }
//
//    return svg;
//}

function linkType(d) {
    return d.target.type.split(/\s+/).map(function(t) { return "to-" + t; })
    .concat(d.source.type.split(/\s+/).map(function(t) { return "from-" + t; }))
    .join(" ");
}

function reset(svg) {
    svg.selectAll("*")
        .style("stroke-opacity", null)
        .style("fill-opacity", null)
        .style("display", null);

    var node = svg.selectAll(".node g")
        .attr("class", function(d) { return d.type; })
        .attr("transform", function(d, i) { return "translate(" + d.depth * step + "," + d.x + ")"; });

    node.select("rect")
        .attr("ry", 6)
        .attr("rx", 6)
        .attr("y", -10)
        .attr("height", 20)
        .attr("width", function(d) { return d.width; })
        .filter(function(d) { return d.flipped; })
        .attr("x", function(d) { return -d.width; });

    node.select(".join")
        .attr("d", d3.svg.diagonal()
        .source(function(d) { return {y: d.width, x: 0}; })
        .target(function(d) { return {y: 88, x: d.join * 24}; })
        .projection(function(d) { return [d.y, d.x]; }));

    svg.selectAll(".link path")
        .attr("class", linkType)
        .attr("d", d3.svg.diagonal()
        .source(function(d) { return {y: d.source.depth * step + (d.source.flipped ? -1 : +1) * d.source.width, x: d.source.x}; })
        .target(function(d) { return {y: d.target.depth * step, x: d.target.x}; })
        .projection(function(d) { return [d.y, d.x]; }));
}

function selectAllData(data, dataHeight) {
    var dataTree = tree(data, dataHeight),
        event = d3.dispatch("start", "middle", "end", "reset"),
        height = +dataTree.attr("height"),
        svg = dataTree.node(),
        offset = 0;

    dataTree = d3.select(svg.firstChild);

    resetAll();
    animation();

    return event;

    function resetAll() {
        dataTree.style("display", null).call(reset);
        event.reset();
    }

    function animation() {
        dataTree.call(fadeIn, 150);
        setTimeout(transition1, 1250);
        event.start();
    }
    function transition1() {
        var dataTree2 = tree(data2, data2Height);
        event.end();
    }

//    function transition1() {
//        var t = dataTree.transition()
//            .duration(1000 + (startElements.length - 1) * 50);
//            .each("end", transition2);
//
//        t.selectAll(".selection,.array,.link")
//            .duration(0)
//            .style("stroke-opacity", 0)
//            .style("fill-opacity", 0);
//
//        t.selectAll(".element")
//            .duration(500)
//            .delay(function(d, i) { return 500 + i * 50; })
//            .attr("transform", function(d, i) { return "translate(" + (d.depth - 1) * step + "," + (endGroups[i].x - offset) + ")"; })
//            .attr("class", "array")
//            .select("rect")
//            .attr("width", function(d, i) { return endGroups[i].width; });
//
//        event.end();
//    }

}
function selectAllAnimation(startRoot, startHeight, endRoot, endHeight) {
    var end = tree(endRoot, endHeight).remove(),
    event = d3.dispatch("start", "middle", "end", "reset"),
    height = +end.attr("height"),
    start = tree(startRoot, startHeight).attr("height", height),
    svg = start.node(),
    offset = (endHeight - startHeight) / 2,
    transform = "translate(" + margin.left + "," + offset + ")";

    var play = start.append("g")
        .attr("class", "play");

    // Circle with array
    play.append("circle")
        .attr("r", 45)
        .attr("transform", "translate(" + (margin.left + width / 2) + "," + height / 2 + ")");

    // Arrow
    play.append("path")
        .attr("d", "M-22,-30l60,30l-60,30z")
        .attr("transform", "translate(" + (margin.left + width / 2) + "," + height / 2 + ")scale(.7)");

    play.append("rect")
        .attr("width", width)
        .attr("height", height)
        .on("mousedown", function() {
            play.classed("mousedown", true);
            d3.select(window).on("mouseup", function() {
                play.classed("mousedown", false);
            });
        })
        .on("click", function() {
            resetAll();
            animation();
        });

    end = d3.select(svg.appendChild(end.node().firstChild));
    start = d3.select(svg.firstChild).attr("transform", transform);
    end.selectAll(".array").each(function() { this.parentNode.appendChild(this); }); // mask elements

    var startNodes = start.datum().nodes,
        startElements = startNodes.filter(function(d) { return d.type === "element"; }),
        endNodes = end.datum().nodes,
        endGroups = endNodes.filter(function(d) { return d.type === "array"; });

    resetAll();

    return event;

    function resetAll() {
        start.style("display", "none").call(reset);
//        start.style("display", null).call(reset);
        end.style("display", null).call(reset);
        play.style("display", null);
        event.reset();
    }

    function animation() {
        start.call(fadeIn, 150);
        end.style("display", "none");
        play.style("display", "none");
        setTimeout(transition1, 1250);
        event.start();
    }

    function transition1() {
        var t = start.transition()
            .duration(1000 + (startElements.length - 1) * 50)
            .each("end", transition2);

        t.selectAll(".selection,.array,.link")
            .duration(0)
            .style("stroke-opacity", 0)
            .style("fill-opacity", 0);

        t.selectAll(".element")
            .duration(500)
            .delay(function(d, i) { return 500 + i * 50; })
            .attr("transform", function(d, i) { return "translate(" + (d.depth - 1) * step + "," + (endGroups[i].x - offset) + ")"; })
            .attr("class", "array")
            .select("rect")
            .attr("width", function(d, i) { return endGroups[i].width; });

        event.middle();
    }

    function transition2() {
        end.style("display", null)
            .selectAll(".element,.to-element")
            .style("display", "none");

        end.selectAll(".selection,.to-array,.array")
            .call(fadeIn);

        end.transition()
            .duration(500)
            .each("end", transition3);

        event.end();
    }

    function transition3() {
        start.style("display", "none");

        end.selectAll(".element")
            .style("display", null)
            .attr("transform", function(d) { return "translate(" + d.parent.depth * step + "," + d.parent.x + ")"; })
            .transition()
            .duration(500)
            .delay(function(d, i) { return i * 50; })
            .attr("transform", function(d) { return "translate(" + d.depth * step + "," + d.x + ")"; });

        end.selectAll(".to-element")
            .style("display", null)
            .attr("d", d3.svg.diagonal()
            .source(function(d) { return {y: d.source.depth * step + d.source.width, x: d.source.x}; })
            .target(function(d, i) { return {y: d.source.depth * step + d.source.width, x: d.source.x}; })
            .projection(function(d) { return [d.y, d.x]; }))
            .transition()
            .duration(500)
            .delay(function(d, i) { return i * 50; })
            .attr("d", d3.svg.diagonal()
            .source(function(d) { return {y: d.source.depth * step + d.source.width, x: d.source.x}; })
            .target(function(d, i) { return {y: d.target.depth * step, x: d.target.x}; })
            .projection(function(d) { return [d.y, d.x]; }));

        end.transition()
            .duration(2000)
            .each("end", resetAll);
    }
}

function fadeIn(selection, delay) {
    selection
        .style("display", null)
        .style("stroke-opacity", 0)
        .style("fill-opacity", 0)
        .transition()
        .duration(delay || 0)
        .style("stroke-opacity", 1)
        .style("fill-opacity", 1);
}

