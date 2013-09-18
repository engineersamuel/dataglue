define ['underscore', 'd3', 'customToolTip'], (_, d3, CustomToolTip) ->
  class DataGlueBubbleChart

    constructor: (container_id) ->
      console.log "SolutionsLinkedBubbleChart created!"

      @container_selector = "##{container_id}"
      @svg_selector = "##{container_id} svg"
      @width = $(@container).width()
      @height = 800
      console.log "Height: #{@height}, width: #{@width}"
      @display_type = "all"

      @tooltip = CustomToolTip("gates_tooltip", 240)
      @center = {x: @width / 2, y: @height / 2}
      @layout_gravity = -0.01
      @damper = 0.1

#      @origins = {
#        "Search": {x: @width / 6, y: @height / 2, color: "#BFBFBF"}
#        "Search;Suggestion": {x: (@width / 6) * 2, y: @height / 2, color: "#FFA200"}
#        "Suggestion": {x: (@width / 6) * 3 , y: @height / 2, color: "#02F0EC"}
#        "From Case": {x: (@width / 6) * 4, y: @height / 2, color: "#F00202"}
#        "Suggestion;From Case": {x: (@width / 6) * 5, y: @height / 2, color: "#00BD00"}
#      }


#      @linking_mechanisms = {
#        "Suggestion": {x: (@width / 7) * 6, y: @height / 2}
#        "Search": {x: (@width / 7) * 5, y: @height / 2}
#        "Quick Search": {x: (@width / 7) * 4, y: @height / 2}
#        "Probably Search": {x: (@width / 7) * 3 , y: @height / 2}
#        "GET": {x: (@width / 7) * 2, y: @height / 2},
#        "From Case": {x: @width / 7, y: @height / 2},
#      }
      @fill_color_linking_mechanism = d3.scale.ordinal()
        .domain(["Suggestion", "Search", "Quick Search", "Probably Search", "GET", "From Case"])
        .range(["#609376", "#1F3662", "#DF95D4", "#AF67BF", "#66573D", "#332911"])


    # Data is in the form of streams
    #    example = [
    #      {
    #        "key":"Stream0",
    #        "values":[
    #          {"x":0,"y":0.21822935637400104},
    #          {"x":1,"y":0.9060637492616568},
    #          {"x":2,"y":4.546998750065884}
    #        ]
    #      }
    #      {
    #        "key":"Stream1",
    #        "values":[
    #          {"x":0,"y":0.12126328994207859},
    #          {"x":1,"y":0.13279333392038253},
    #          {"x":2,"y":0.5631966101277897}
    #        ]
    #      },
    #    ]
    initialize_data: (data) ->
      # these will be set in create_nodes and create_vis
      @vis = null
      @nodes = []
      @force = null
      @circles = null

      # Since there could be multiple streams though this is recommended against, but the common format is in a stream
      # Go ahead and reformat the data to smash it all together
      #@data = data
      @data = _.map data, (stream) -> _.map stream.values, (item) -> item

      # Grab the unique x's as the domain
      #uniqueXs = _.unique _.map data, (stream) -> _.map stream.values, (item) -> item.x
      uniqueXs = _.unique _.map data, (item) -> item.x
      console.log "Discovered unique x values: #{uniqueXs}"

      # The fill color will be the unique groups of x's
      @fill_color_x = d3.scale.ordinal()
      .domain(uniqueXs)
      .category20c()
      #.range(["#BFBFBF", "#FFA200", "#02F0EC", "#F00202", "#00BD00"])

      # use the max total_amount in the data as the max in the scale's domain
      max_amount = d3.max(@data, (d) -> parseInt(d.y))
      @radius_scale = d3.scale.pow().exponent(0.5).domain([0, max_amount]).range([2, 85])

      this.create_nodes()
      this.create_vis()

    create_nodes: () ->
      @data.forEach (d) =>
        node =
          radius: @radius_scale(parseInt(d.y))
          y: d.y
          x: d.x
#          x: Math.random() * 900
#          y: Math.random() * 800

        @nodes.push node

      @nodes.sort (a,b) -> b.y - a.y

    create_vis: () ->
      d3.selectAll(@svg_selector).remove()
      @vis = d3.select(@container_selector).append("svg")
        .attr("width", @width)
        .attr("height", @height)
        #.attr("id", "svg_vis")

      @circles = @vis.selectAll("circle").data(@nodes, (d) -> d.x)
#      @circles = @vis.selectAll("circle").data(@nodes)

      # used because we need 'this' in the mouse callbacks
      that = this
      @circles.enter().append("circle")
        .attr("r", 0)
        #.attr("fill", (d) => @fill_color_origin(d.origin))
        .attr("stroke-width", 2)
        .attr("stroke", (d) => d3.rgb(@fill_color_origin(d.x)).darker())
        .attr("id", (d) -> "bubble_#{d.x}")
        .on("mouseover", (d,i) -> that.show_details(d,i,this))
        .on("mouseout", (d,i) -> that.hide_details(d,i,this))
        .on("click", (d,i) -> that.open_article(d, i, this))

      @circles.transition().duration(2000).attr("r", (d) -> d.radius)

    charge: (d) -> -Math.pow(d.radius, 2.0) / 8

    start: () =>
      @force = d3.layout.force()
        .nodes(@nodes)
        .size([@width, @height])

    display_group_all: () =>
      @force.gravity(@layout_gravity)
      .charge(this.charge)
      .friction(0.9)
      .on "tick", (e) =>
          @circles.each(this.move_towards_center(e.alpha))
          .attr("cx", (d) -> d.x)
          .attr("cy", (d) -> d.y)
      @force.start()

      @hide_groups()

    move_towards_center: (alpha) =>
      (d) =>
        d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
        d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

    # move all circles to their associated @group_centers
#    move_towards_origin: (alpha) =>
#      (d) =>
#        target = @origins[d.origin]
#        d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 1.1
#        d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 1.1

#    move_towards_linking_mechanism: (alpha) =>
#      (d) =>
#        target = @linking_mechanisms[d.linking_mechanism]
#        d.x = d.x + (target.x - d.x) * (@damper + 0.02) * alpha * 2.0
#        d.y = d.y + (target.y - d.y) * (@damper + 0.02) * alpha * 2.0

    # sets the display of bubbles to be separated
    # into each year. Does this by calling move_towards_year
#    display_by_origin: () =>
#
#      @display_type = "origin"
#
#      @force.gravity(@layout_gravity)
#      .charge(this.charge)
#      .friction(0.9)
#      .on "tick", (e) =>
#          @circles.each(@move_towards_origin(e.alpha))
#          .attr("cx", (d) -> d.x)
#          .attr("cy", (d) -> d.y)
#      @force.start()
#
#      @display_origins()
#      @circles.transition().duration(2000)
#      .attr("fill", (d) => @fill_color_origin(d.origin))
#      .attr("stroke", (d) => d3.rgb(@fill_color_origin(d.origin)).darker())
#
#    display_by_linking_mechanism: () =>
#
#      @display_type = "linking_mechanism"
#
#      @force.gravity(@layout_gravity)
#      .charge(@charge)
#      .friction(0.9)
#      .on "tick", (e) =>
#          @circles.each(@move_towards_linking_mechanism(e.alpha))
#          .attr("cx", (d) -> d.x)
#          .attr("cy", (d) -> d.y)
#      @force.start()
#
#      @display_linking_mechanisms()
#      @circles.transition().duration(2000)
#      .attr("fill", (d) => @fill_color_linking_mechanism(d.linking_mechanism))
#      .attr("stroke", (d) => d3.rgb(@fill_color_linking_mechanism(d.linking_mechanism)).darker())
#
#    display_linking_mechanisms: () =>
#      groups = @vis.selectAll(".groups").remove()
#      groups_x = {
#        "From Case": @linking_mechanisms["From Case"].x
#        "GET": @linking_mechanisms["GET"].x
#        "Probably Search": @linking_mechanisms["Probably Search"].x
#        "Quick Search": @linking_mechanisms["Quick Search"].x
#        "Search": @linking_mechanisms["Search"].x
#        "Suggestion": @linking_mechanisms["Suggestion"].x
#      }
#      groups_data = d3.keys(groups_x)
#      groups = @vis.selectAll(".groups").data(groups_data)
#
#      groups.enter().append("text")
#      .attr("class", "groups")
#      .attr("x", (d) => groups_x[d] )
#      .attr("y", 40)
#      .attr("text-anchor", "middle")
#      .text((d) -> d)
#
#    display_origins: () =>
#      groups = @vis.selectAll(".groups").remove()
#      groups_x = {
#        "Suggestion;From Case": @origins["Suggestion;From Case"].x
#        "From Case": @origins["From Case"].x
#        "Suggestion": @origins["Suggestion"].x
#        "Search;Suggestion": @origins["Search;Suggestion"].x
#        "Search": @origins["Search"].x
#      }
#      groups_data = d3.keys(groups_x)
#      groups = @vis.selectAll(".groups").data(groups_data)
#
#      groups.enter().append("text")
#      .attr("class", "groups")
#      .attr("x", (d) => groups_x[d] )
#      .attr("y", 40)
#      .attr("text-anchor", "middle")
#      .text((d) -> d)

    hide_groups: () =>
      groups = @vis.selectAll(".groups").remove()

    show_details: (data, i, element) =>
      d3.select(element).attr("stroke", "black")
      content = "<span class=\"name\">Name: </span><span class=\"value\">#{data.x}</span><br/>"
      content +="<span class=\"name\">Value: </span><span class=\"value\">#{data.y}</span><br/>"
      @tooltip.showTooltip(content,d3.event)


    hide_details: (data, i, element) =>
      d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color_x(d.x)).darker())
      @tooltip.hideTooltip()

