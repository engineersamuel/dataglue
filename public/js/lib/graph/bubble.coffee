define ['underscore', 'd3', 'customTooltip'], (_, d3, CustomTooltip) ->
  class DataGlueBubbleChart
    constructor: (container_id) ->
      console.log "D3 Bubble Chart Created!"

      @container_selector = "##{container_id}"
      @svg_selector = "##{container_id} svg"
      @width = $(@container_selector).parent().width()
      @height = $(@container_selector).parent().height()
      #@height = 800
      console.log "Height: #{@height}, width: #{@width}"
      @display_type = "all"

      @tooltip = CustomTooltip("gates_tooltip", 240)
      @center = {x: @width / 2, y: @height / 2}
      @layout_gravity = -0.01
      @damper = 0.1

#      myOperative = operative (a, b, c, callback) ->
#        result = a + b + c
#        callback(result)
#      myOperative(1, 2, 3, (result) -> console.log(JSON.stringify(result)) )

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
#      @fill_color_linking_mechanism = d3.scale.ordinal()
#        .domain(["Suggestion", "Search", "Quick Search", "Probably Search", "GET", "From Case"])
#        .range(["#609376", "#1F3662", "#DF95D4", "#AF67BF", "#66573D", "#332911"])


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
    initialize_data: (streams) ->
      console.log "bubble:initialize_data"
      # these will be set in create_nodes and create_vis
      @vis = null
      @nodes = []
      @force = null
      @circles = null

      # Since there could be multiple streams though this is recommended against, but the common format is in a stream
      # Go ahead and reformat the data to smash it all together
      #@data = data
      @data = _.flatten _.map streams, (stream) -> _.map stream.values, (item) -> item
      #console.log "Streams converted to bubble data: #{JSON.stringify(@data)}"

      # Grab the unique x's as the domain
      #uniqueXs = _.unique _.map data, (stream) -> _.map stream.values, (item) -> item.x
      uniqueXs = _.unique _.map @data, (item) -> item.x
      #console.debug "Discovered unique x values: #{uniqueXs}"
      #console.debug "CustomTooltip: #{_.isObject(CustomTooltip)}"
      #console.debug "operative: #{_.isObject(operative)}"

      # The fill color will be the unique groups of x's
      #@fill_color_x = d3.scale.linear()
      #  .domain(uniqueXs)
      #  .range(["yellow", "green"])

      # http://stackoverflow.com/questions/12217121/continuous-color-scale-from-discrete-domain-of-strings?rq=1
      @fill_color_x = d3.scale.ordinal()
        .domain(uniqueXs)
        .range(d3.range(uniqueXs.length)
          .map(d3.scale.linear()
            .domain([0, uniqueXs.length - 1])
            .range(["yellow", "green"])
            .interpolate(d3.interpolateLab)))

      #@fill_color_x = d3.scale.ordinal()
      #  .domain(uniqueXs)
      #  .range(["red", "blue"])
      #.range(["#BFBFBF", "#FFA200", "#02F0EC", "#F00202", "#00BD00"])

      # use the max total_amount in the data as the max in the scale's domain
      max_amount = d3.max(@data, (d) -> parseInt(d.y))
      @radius_scale = d3.scale.pow().exponent(0.5).domain([0, max_amount]).range([2, 85])

      this.create_nodes()
      this.create_vis()

    create_nodes: () ->
      @data.forEach (d) =>
        node =
          radius: @radius_scale(parseInt(d.y || 0))
          y: d.y
          x: d.x
          name: d.x
          value: d.y
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

      # used because we need 'this' in the mouse callbacks
      that = this
      @circles.enter().append("circle")
        .attr("r", 0)
        .attr("fill", (d) => @fill_color_x(d.x))
        .attr("stroke-width", 1)
        .attr("stroke", (d) => d3.rgb(@fill_color_x(d.x)).darker())
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
      # Non Web Workers
#      @force.gravity(@layout_gravity)
#        .charge(this.charge)
#        .friction(0.9)
#        .on "tick", (e) =>
#          @circles.each(this.move_towards_center(e.alpha))
#            .attr("cx", (d) -> d.x)
#            .attr("cy", (d) -> d.y)



      # Web Workified
      @force.gravity(@layout_gravity)
        .charge(this.charge)
        .friction(0.9)
        .on "tick", (e) =>
          # This doesn't work since the function can't be serialized by web workeres
#          myOperative e.alpha, (result) ->
#            @circles.each(result)
#              .attr("cx", (d) -> d.x)
#              .attr("cy", (d) -> d.y)

#          myOperative e.alpha, (result) ->
#            @circles.each(result)
#            .attr("cx", (d) -> d.x)
#            .attr("cy", (d) -> d.y)

          # Working reference
          @circles.each(this.move_towards_center(e.alpha))
            .attr("cx", (d) -> d.x)
            .attr("cy", (d) -> d.y)
      @force.start()

      @hide_groups()

#    myOperativeX: operative (d, center, damper, alpha, callback) ->
#      callback d.x = d.x + (center.x - d.x) * (damper + 0.02) * alpha
#
#    myOperativeY: operative (d, center, damper, alpha, callback) ->
#      callback d.y + (center.y - d.y) * (damper + 0.02) * alpha

    move_towards_center: (alpha) =>
      # This works but is NOT performant.  Chrome grinds hard on [program] so something up.
      # Non web workers impl works fine for now.
#      return (d) =>
#        @myOperativeX d, @center, @damper, alpha, (result) ->
#          d.x = result
#        @myOperativeY d, @center, @damper, alpha, (result) ->
#          d.y = result

       # original
      (d) =>
        d.x = d.x + (@center.x - d.x) * (@damper + 0.02) * alpha
        d.y = d.y + (@center.y - d.y) * (@damper + 0.02) * alpha

    hide_groups: () =>
      groups = @vis.selectAll(".groups").remove()

    show_details: (data, i, element) =>
#      console.log "Show details of data: #{JSON.stringify(data)}"
#      console.log "element: #{JSON.stringify(element)}"
      d3.select(element).attr("stroke", "black")
      content = "<span class=\"name\">Name: </span><span class=\"value\">#{data.name}</span><br/>"
      content +="<span class=\"name\">Value: </span><span class=\"value\">#{data.value}</span><br/>"
      @tooltip.showTooltip(content, d3.event)


    hide_details: (data, i, element) =>
      d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color_x(d.x)).darker())
#      d3.select(element).attr("stroke", (d) => d3.rgb(@fill_color_x(d.x)))
      @tooltip.hideTooltip()

