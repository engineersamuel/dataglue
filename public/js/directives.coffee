define ["angular", "services", "nv", "moment", "bubble"], (angular, services, nv, moment, Bubble) ->
  "use strict"
  angular.module("dataGlue.directives", ["dataGlue.services"])
  .directive("appVersion", ["version", (version) ->
    (scope, elm, attrs) ->
      elm.text version
  ])
#  .directive "dirTableVis", ->
#    restrict: "E"
#    scope:
#      val: "="
#      grouped: "="
#
#    # http://knowledgestockpile.blogspot.com/2012/01/understanding-selectall-data-enter.html
#    link: (scope, element, attrs) ->
#
#
#      tables = (data) ->
#        console.log "tables:data: #{JSON.stringify(data)}"
#        vis = d3.select(element[0])
#        divs = vis.selectAll("div").data(data, (d) -> d['TABLE_NAME'])
#        divs.enter().append('div').attr('class', 'db-info-item').text((d) -> d['TABLE_NAME'])
#
#        # Transition the element being removed
#        divs.exit()
#          .transition()
#          .duration(300)
#          .ease("exp")
#          .style("opacity", 0)
#          .remove()
#
#        # Transition the element coming into existence
#        divs
#          .attr("opacity", 1)
#          .transition()
#          .duration(500)
#          .ease("exp")
#
#      # Setup with the initial data
#      scope.$watch 'val', (newVal, oldVal) ->
#
#        if newVal is undefined
#          return
#
#        tables newVal

  .directive "d3Visualization", () ->
    restrict: "E"
    scope: {
      val: "=",
      type: "="
    }
    link: (scope, element, attrs) ->

      elementId = element.attr('id')
      containerSelector = "##{elementId}"
      svgSelector = "##{elementId} svg"

      dataSet = undefined
      chartType = undefined
      chart = undefined
      chartXType = undefined

      setAxisFormatting = (dataSet) ->
        xAxisDataType = dataSet[0]?['values']?[0]?.xType
        chartXType = xAxisDataType
        xAxisGroupBy = dataSet[0]?['values']?[0]?.xGroupBy
        yAxisDataType = dataSet[0]?['values']?[0]?.yType
        console.debug "xAxisDataType: #{xAxisDataType}"
        console.debug "xAxisGroupBy: #{xAxisGroupBy}"
        console.debug "yAxisDataType: #{yAxisDataType}"

        # I may do some better logic in the future but for now float is the safe case
        if _.contains ['int', 'float'], yAxisDataType
          chart.yAxis.tickFormat(d3.format(',.2f'))
        #if yAxisDataType in ['int']
        #  chart.yAxis.tickFormat((d) -> d3.format("d")(d))
        #else if yAxisDataType in ['float']
        #  chart.yAxis.tickFormat(d3.format(',.1f'))
        #chart.yAxis.tickFormat((d) -> d3.format("d")(d))

        if _.contains ['datetime', 'date'], xAxisDataType
          if xAxisGroupBy is 'hour'
            chart.xAxis.tickFormat((d) -> moment.utc(d).format('YYYY-MM-DD HH'))
          else if xAxisGroupBy is 'day'
            chart.xAxis.tickFormat((d) -> moment.utc(d).format('YYYY-MM-DD'))
          else if xAxisGroupBy is 'month'
            chart.xAxis.tickFormat((d) -> moment.utc(d).format('YYYY-MM'))
          else if xAxisGroupBy is 'year'
            chart.xAxis.tickFormat((d) -> moment.utc(d).format('YYYY'))
          # Default
          else
            chart.xAxis.tickFormat((d) -> moment.utc(d).format('YYYY-MM-DD'))
        else if xAxisDataType is 'varchar'
          chart.xAxis.tickFormat((d) -> d)

      createChartByType = () ->
        if chartType is 'multiBarChart'
          chart = nv.models.multiBarChart()
            .margin({top: 10, right: 30, bottom: 150, left: 60})
            #.staggerLabels(true)
            .x((d) -> d.x)
            .y((d) -> d.y)
            .tooltip((key, x, y, e, graph) ->
                return "<h3>#{key}</h3><p>#{y} on #{x}</p>"
            )
        else if chartType is 'stackedAreaChart'
          chart = nv.models.stackedAreaChart()
            .margin({top: 10, right: 30, bottom: 150, left: 60})
            #.staggerLabels(true)
            .x((d) -> d.x)
            .y((d) -> d.y)
            .clipEdge(true)
            .tooltip((key, x, y, e, graph) ->
                return "<h3>#{key}</h3><p>#{y} on #{x}</p>"
            )
        return undefined

      updateChartByType = () ->
        if chartType in ['multiBarChart', 'stackedAreaChart']
          console.log "Updating the d3 graph with: #{JSON.stringify(dataSet)}"

          setAxisFormatting(dataSet)

          d3.select(svgSelector)
            .datum(dataSet)
            .transition().duration(500).call(chart)

          chart.update()

        return undefined

      handleChart = () ->
        # If no chart create the chart and add it to nv
        if chart is undefined
          console.log "Creating a new d3 Graph"
          nv.addGraph () ->
            createChartByType()
            setAxisFormatting(dataSet)

            d3.select(svgSelector)
              .datum(dataSet)
              .transition().duration(500).call(chart)

            nv.utils.windowResize chart.update

            return chart
        # Otherwise just update the data and redraw
        else
          updateChartByType()

      handlePie = () ->
        # There is a major discrepency with the pieChart
        pieData = _.flatten _.map dataSet, (stream) -> _.map stream.values, (item) -> item

        # If no chart create the chart and add it to nv
        if chart is undefined
          console.log "Creating a new Pie Graph with dataSet: #{JSON.stringify(dataSet)}"
          nv.addGraph () ->
            chart = nv.models.pieChart()
              .x((d) -> d.x )
              .y((d) -> d.y )
              .showLabels(true)

            d3.select(svgSelector)
              .datum(pieData)
              .transition().duration(500).call(chart)

            nv.utils.windowResize chart.update

            return chart
          # Otherwise just update the data and redraw
        else
          console.log "Updating the Pie graph with: #{JSON.stringify(dataSet)}"

          d3.select(svgSelector)
            .datum(pieData)
            .transition().duration(500).call(chart)

          chart.update()

      handleBubble = () ->
        chart = new Bubble "graph_container"
        chart.initialize_data dataSet
        chart.start()
        chart.display_group_all()

      handleOptionsChanges = () ->
        if dataSet?.length > 0
          if chartType in ['multiBarChart', 'stackedAreaChart']
            handleChart()
          else if chartType is 'bubble'
            handleBubble()
          else if chartType is 'pie'
            handlePie()
          else
            console.warn "Data to graph but no type of Graph selected!"
        else
          console.warn "No data given to graph!"

      resetSvg = () ->
        chart = undefined
        console.debug "Resetting SVG"
        d3.selectAll(svgSelector).remove()
        d3.select(containerSelector).append("svg")

      scope.$watch "val", (newVal, oldVal) ->
        dataSet = newVal

        console.debug "Dataset changed to: #{JSON.stringify(dataSet)}"

        handleOptionsChanges()
      scope.$watch "type", (newVal, oldVal) ->
        chartType = newVal
        console.debug "chartType changed to: #{chartType}"

        # If the type of the graph has changed, remove the current element
        if (newVal isnt oldVal and newVal isnt undefined) then resetSvg()

        # Now handle the options changes
        handleOptionsChanges()



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

# This was being used as example data for the graph if there was no other data, but this is unecessary I think, but good ref
#      stream_index = `
#        function (d, i) {
#          return {x: i, y: Math.max(0, d)};
#        }`
#
#      stream_layers = `
#        function (n, m, o) {
#          if (arguments.length < 3) o = 0;
#          function bump(a) {
#            var x = 1 / (.1 + Math.random()),
#              y = 2 * Math.random() - .5,
#              z = 10 / (.1 + Math.random());
#            for (var i = 0; i < m; i++) {
#              var w = (i / m - y) * z;
#              a[i] += x * Math.exp(-w * w);
#            }
#          }
#          return d3.range(n).map(function() {
#            var a = [], i;
#              for (i = 0; i < m; i++) a[i] = o + o * Math.random();
#              for (i = 0; i < 5; i++) bump(a);
#            return a.map(stream_index);
#          });
#        }`
#
#      exampleData = () -> return stream_layers(3,10+Math.random()*100,.1).map((data, i) -> return { key: 'Stream' + i, values: data})
#
## Auto set the width/height
##      margin = {top: 10, left: 10, bottom: 10, right: 10}
##      width = parseInt(d3.select(element[0]).style('width'))
##      height = parseInt(d3.select(element[0]).style('height'))
##      width = width - margin.left - margin.right
##      height = height - margin.top - margin.bottom
