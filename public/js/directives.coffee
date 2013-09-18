define ["angular", "services", "d3", "nv", "moment", "bubble"], (angular, services, d3, nv, moment, Bubble) ->
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

  .directive "d3Visualization", () ->
    restrict: "E"
    scope: {
      val: "=",
      type: "="
    }
    link: (scope, element, attrs) ->

      data = undefined
      graphType = undefined
      chart = undefined
      bubbleGraph = undefined

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
              #.staggerLabels(true)
              .x((d) -> return d.x)
              .y((d) -> return d.y)
              .tooltip((key, x, y, e, graph) ->
                return "<h3>#{key}</h3><p>#{y} on #{x}</p>"
              )
            setAxisFormatting dataSet, chart

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

          chart.update()

      handleBubble = () ->
        bubbleGraph = new Bubble()
        bubbleGraph.initialize_data(data)
        bubbleGraph.start()
        bubbleGraph.display_group_all()


      handleOptionsChanges = () ->
        if data?
          if graphType is 'multiBarChart'
            handleChart()
          else if graphType is 'bubble'
            handleBubble()
          else
            console.warn "Data to graph but no type of Graph selected!"
        else
          console.warn "No data given to graph!"


      scope.$watch "val", (newVal, oldVal) ->
        console.log "$watch val: #{JSON.stringify(newVal)}"
        data = newVal
        handleOptionsChanges()
      scope.$watch "type", (newVal, oldVal) ->
        console.log "$watch type: #{newVal}"
        graphType = newVal
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
