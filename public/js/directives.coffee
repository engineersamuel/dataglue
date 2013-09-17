define ["angular", "services", "d3", "nv", "moment"], (angular, services, d3, nv, moment) ->
  "use strict"
  angular.module("dataGlue.directives", ["dataGlue.services"])
  .directive("appVersion", ["version", (version) ->
    (scope, elm, attrs) ->
      elm.text version
  ])
  .directive "dirTableVis", ->
    restrict: "E"
    scope:
      val: "="
      grouped: "="

    # http://knowledgestockpile.blogspot.com/2012/01/understanding-selectall-data-enter.html
    link: (scope, element, attrs) ->

      tables = (data) ->
        console.log "tables:data: #{JSON.stringify(data)}"
        vis = d3.select(element[0])
        divs = vis.selectAll("div").data(data, (d) -> d['TABLE_NAME'])
        divs.enter().append('div').attr('class', 'db-info-item').text((d) -> d['TABLE_NAME'])

        # Transition the element being removed
        divs.exit()
          .transition()
          .duration(300)
          .ease("exp")
          .style("opacity", 0)
          .remove()

        # Transition the element coming into existence
        divs
          .attr("opacity", 1)
          .transition()
          .duration(500)
          .ease("exp")

      # Setup with the initial data
      scope.$watch 'val', (newVal, oldVal) ->

        if newVal is undefined
          return

        tables newVal
#  .directive "dbInfoTree", () ->
#      restrict: "E"
#      scope:
#        val: "="
#
#      link: (scope, element, attrs) ->
#        #id = scope.svgId
#        id = attrs.svgId
#        jQueryId = "##{id}"
#
#        # Auto set the width/height
#        m = {top: 10, left: 40, bottom: 10, right: 10}
##        w = parseInt(d3.select($(element)).style('width'))
##        h = parseInt(d3.select($(element)).style('height'))
#        w = $(jQueryId).width()
#        h = $(jQueryId).height()
#        w = w - m.left - m.right
#        h = h - m.top - m.bottom
#        i = 0
#
#        diagonal = d3.svg.diagonal()
#          .projection((d) -> return [d.y, d.x])
#
#        tree = undefined
#        vis = undefined
#        root = undefined
#
#        console.log "scope: #{scope}"
##        console.log "attrs: #{JSON.stringify(attrs)}"
##        console.log "element: #{JSON.stringify(element)}"
#        console.log "jQueryId: #{jQueryId}, w: #{w}, h: #{h}"
#        console.log "attrs.svgId: #{attrs.svgId}"
#
#        toggleAll = (d) ->
#          if d.children
#            d.children.forEach(toggleAll)
#            toggle(d)
#
#        toggle = (d) ->
#          if d.children
#            d._children = d.children
#            d.children = null
#          else
#            d.children = d._children
#            d._children = null
#
#        handleVisualization = (data) ->
#
#          if not tree
#            tree = d3.layout.tree().size([h, w])
#
#          if not vis
#            vis = d3.select(jQueryId).append("svg:svg")
#              .attr("width", w + m.left + m.right)
#              .attr("height", h + m.top + m.bottom)
#              .append("svg:g")
#              .attr("transform", "translate(" + m.right + "," + m.top + ")");
#
#          duration = d3.event && if d3.event.altKey then 5000 else 500
#
#          # Compute the new tree layout.
#          nodes = tree.nodes(root).reverse()
#
#          # Normalize for fixed-depth.
#          nodes.forEach((d) -> d.y = d.depth * 180)
#
#          # Update the nodes…
#          node = vis.selectAll("g.node")
#            .data(nodes, (d) -> d.id or (d.id = ++i))
#
#          # Enter any new nodes at the parent's previous position.
#          nodeEnter = node.enter().append("svg:g")
#            .attr("class", "node")
#            .attr("transform", (d) -> return "translate(" + data.y0 + "," + data.x0 + ")")
#            .on("click", (d) ->
#              toggle(d)
#              handleVisualization(d)
#            )
#
#          nodeEnter.append("svg:circle")
#            .attr("r", 1e-6)
#            .style("fill", (d) -> `d._children ? "lightsteelblue" : "#fff"`)
#
#          nodeEnter.append("svg:text")
#            .attr("x", (d) -> `d.children || d._children ? -10 : 10`)
#            .attr("dy", ".35em")
#            .attr("text-anchor", (d) -> `d.children || d._children ? "end" : "start"`)
#            .text((d) -> d.name)
#            .style("fill", '#cccccc')
#            .style("fill-opacity", 1e-6)
#
#          # Transition nodes to their new position.
#          nodeUpdate = node.transition()
#            .duration(duration)
#            .attr("transform", (d) -> "translate(" + d.y + "," + d.x + ")")
#
#          nodeUpdate.select("circle")
#            .attr("r", 4.5)
#            .style("fill", (d) -> `d._children ? "#1eff00" : "#fff"`)
#
#          nodeUpdate.select("text")
#            .style("fill-opacity", 1)
#
#          # Transition exiting nodes to the parent's new position.
#          nodeExit = node.exit().transition()
#            .duration(duration)
#            .attr("transform", (d) -> "translate(" + data.y + "," + data.x + ")")
#            .remove()
#
#          nodeExit.select("circle")
#            .attr("r", 1e-6)
#
#          nodeExit.select("text")
#            .style("fill-opacity", 1e-6)
#
#          # Update the links…
#          link = vis.selectAll("path.link")
#            .data(tree.links(nodes), (d) -> d.target.id)
#
#          # Enter any new links at the parent's previous position.
#          link.enter().insert("svg:path", "g")
#            .attr("class", "link")
#            .attr("d", (d) ->
#              o = {x: data.x0, y: data.y0}
#              return diagonal({source: o, target: o})
#            )
#            .transition()
#            .duration(duration)
#            .attr("d", diagonal)
#
#          # Transition links to their new position.
#          link.transition()
#            .duration(duration)
#            .attr("d", diagonal)
#
#          # Transition exiting nodes to the parent's new position.
#          link.exit().transition()
#            .duration(duration)
#            .attr("d", (d) ->
#              o = {x: data.x, y: data.y}
#              return diagonal({source: o, target: o})
#            )
#            .remove()
#
#          # Stash the old positions for transition.
#          nodes.forEach((d) ->
#            d.x0 = d.x
#            d.y0 = d.y
#          )
#        scope.$watch "val", (newVal, oldVal) ->
#          console.log "newVal.length: #{newVal?.length}"
#
#          if newVal
#            root = newVal
#            root.x0 = h / 2
#            root.y0 = 10
#
#            # Initialize the display to show a few nodes.
#            console.log "newVal: #{JSON.stringify(newVal)}"
#            if root.children
#              root.children.forEach(toggleAll)
#              # toggle(root.children[1]);
#              # toggle(root.children[1].children[2]);
#              # toggle(root.children[9]);
#              # toggle(root.children[9].children[0]);
#
#              handleVisualization(root)

  .directive "d3Visualization", () ->
    restrict: "E"
    scope:
      val: "="

    link: (scope, element, attrs) ->

      stream_index = `
        function (d, i) {
          return {x: i, y: Math.max(0, d)};
        }`

      stream_layers = `
        function (n, m, o) {
          if (arguments.length < 3) o = 0;
          function bump(a) {
            var x = 1 / (.1 + Math.random()),
              y = 2 * Math.random() - .5,
              z = 10 / (.1 + Math.random());
            for (var i = 0; i < m; i++) {
              var w = (i / m - y) * z;
              a[i] += x * Math.exp(-w * w);
            }
          }
          return d3.range(n).map(function() {
            var a = [], i;
              for (i = 0; i < m; i++) a[i] = o + o * Math.random();
              for (i = 0; i < 5; i++) bump(a);
            return a.map(stream_index);
          });
        }`

      exampleData = () -> return stream_layers(3,10+Math.random()*100,.1).map((data, i) -> return { key: 'Stream' + i, values: data})

      # Auto set the width/height
#      margin = {top: 10, left: 10, bottom: 10, right: 10}
#      width = parseInt(d3.select(element[0]).style('width'))
#      height = parseInt(d3.select(element[0]).style('height'))
#      width = width - margin.left - margin.right
#      height = height - margin.top - margin.bottom

      chart = undefined

      setAxisFormatting = (dataSet, chart) ->
        xAxisDataType = dataSet[0]?[0]?.xType
        xAxisGroupBy = dataSet[0]?[0]?.xGroupBy
        yAxisDataType = dataSet[0]?[0]?.yType

        if yAxisDataType in ['int']
          chart.yAxis.tickFormat((d) -> d3.format("d")(d))
        else if yAxisDataType in ['float']
          chart.yAxis.tickFormat(d3.format(',.1f'))

        if xAxisDataType in ['datatime']
          if xAxisGroupBy? is 'day'
            chart.xAxis
              .tickFormat((d) -> return moment(d).format('YYYY-MM-DD'))
          else if xAxisGroupBy? is 'month'
            chart.xAxis
              .tickFormat((d) -> return moment(d).format('YYYY-MM'))
          # Default
          else
            chart.xAxis
              .tickFormat((d) -> return moment(d).format('YYYY-MM-DD'))

        chart.yAxis.tickFormat((d) -> d3.format("d")(d))


      handleChart = (dataSet) ->
        # If no chart create the chart and add it to nv
        if not chart?
          console.log "Creating a new d3 Graph"
          nv.addGraph () ->
            chart = nv.models.multiBarChart()
              .margin({top: 10, right: 30, bottom: 150, left: 30})
              .x((d) -> return d.x)
              .y((d) -> return d.y)
              .tooltip((key, x, y, e, graph) ->
                return "<h3>#{key}</h3><p>#{y} on #{x}</p>"
              )

            setAxisFormatting dataSet, chart
#            chart.xAxis.tickFormat((d) -> return moment(d).format('YYYY-MM-DD'))
#            chart.yAxis.tickFormat((d) -> d3.format("d")(d))

            data = if not dataSet? then exampleData() else dataSet
            console.log "data: #{data}"

            #d3.select(element[0])
            d3.select("#graph_container svg")
              .datum(data)
              .transition().duration(500).call(chart)

            nv.utils.windowResize chart.update

            return chart
        # Otherwise just update the data and redraw
        else
          console.log "Updating the d3 graph with: #{JSON.stringify(dataSet)}"

          setAxisFormatting dataSet, chart

          d3.select("#graph_container svg")
            .datum(dataSet)
            .transition().duration(500).call(chart)

          nv.utils.windowResize chart.update

      scope.$watch "val", (newVal, oldVal) ->
        # console.log "handleChart: #{JSON.stringify(newVal)}"
        if newVal?
          handleChart newVal



#  .directive "d3Graph", ["dbInfo", (dbInfo) ->
#      restrict: "E"
#
#      # http://knowledgestockpile.blogspot.com/2012/01/understanding-selectall-data-enter.html
#      link: (scope, element, attrs) ->
#
#        tables = (data) ->
#          console.log "tables:data: #{JSON.stringify(data)}"
#          vis = d3.select(element[0])
#          divs = vis.selectAll("div").data(data, (d) -> d['TABLE_NAME'])
#          divs.enter().append('div').attr('class', 'db-info-item').text((d) -> d['TABLE_NAME'])
#
#          # Transition the element being removed
#          divs.exit()
#          .transition()
#          .duration(300)
#          .ease("exp")
#          .style("opacity", 0)
#          .remove()
#
#          # Transition the element coming into existence
#          divs
#          .attr("opacity", 1)
#          .transition()
#          .duration(500)
#          .ease("exp")
#
#        # Setup with the initial data
#        scope.$watch 'val', (newVal, oldVal) ->
#
#          if newVal is undefined
#            return
#
#          tables newVal
#    ]
