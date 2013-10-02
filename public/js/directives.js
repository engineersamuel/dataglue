// Generated by CoffeeScript 1.6.2
(function() {
  define(["angular", "services", "nv", "moment", "bubble"], function(angular, services, nv, moment, Bubble) {
    "use strict";    return angular.module("dataGlue.directives", ["dataGlue.services"]).directive("appVersion", [
      "version", function(version) {
        return function(scope, elm, attrs) {
          return elm.text(version);
        };
      }
    ]).directive("d3Visualization", function() {
      return {
        restrict: "E",
        scope: {
          val: "=",
          type: "="
        },
        link: function(scope, element, attrs) {
          var chart, chartType, chartXType, containerSelector, createChartByType, dataSet, elementId, handleBubble, handleChart, handleOptionsChanges, handlePie, resetSvg, setAxisFormatting, svgSelector, updateChartByType;

          elementId = element.attr('id');
          containerSelector = "#" + elementId;
          svgSelector = "#" + elementId + " svg";
          dataSet = void 0;
          chartType = void 0;
          chart = void 0;
          chartXType = void 0;
          setAxisFormatting = function(dataSet) {
            var xAxisDataType, xAxisGroupBy, yAxisDataType, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;

            xAxisDataType = (_ref = dataSet[0]) != null ? (_ref1 = _ref['values']) != null ? (_ref2 = _ref1[0]) != null ? _ref2.xType : void 0 : void 0 : void 0;
            chartXType = xAxisDataType;
            xAxisGroupBy = (_ref3 = dataSet[0]) != null ? (_ref4 = _ref3['values']) != null ? (_ref5 = _ref4[0]) != null ? _ref5.xGroupBy : void 0 : void 0 : void 0;
            yAxisDataType = (_ref6 = dataSet[0]) != null ? (_ref7 = _ref6['values']) != null ? (_ref8 = _ref7[0]) != null ? _ref8.yType : void 0 : void 0 : void 0;
            console.debug("xAxisDataType: " + xAxisDataType);
            console.debug("xAxisGroupBy: " + xAxisGroupBy);
            console.debug("yAxisDataType: " + yAxisDataType);
            if (_.contains(['int', 'float'], yAxisDataType)) {
              chart.yAxis.tickFormat(d3.format(',.2f'));
            }
            if (_.contains(['datetime', 'date'], xAxisDataType)) {
              if (xAxisGroupBy === 'hour') {
                return chart.xAxis.tickFormat(function(d) {
                  return moment.utc(d).format('YYYY-MM-DD HH');
                });
              } else if (xAxisGroupBy === 'day') {
                return chart.xAxis.tickFormat(function(d) {
                  return moment.utc(d).format('YYYY-MM-DD');
                });
              } else if (xAxisGroupBy === 'month') {
                return chart.xAxis.tickFormat(function(d) {
                  return moment.utc(d).format('YYYY-MM');
                });
              } else if (xAxisGroupBy === 'year') {
                return chart.xAxis.tickFormat(function(d) {
                  return moment.utc(d).format('YYYY');
                });
              } else {
                return chart.xAxis.tickFormat(function(d) {
                  return moment.utc(d).format('YYYY-MM-DD');
                });
              }
            } else if (xAxisDataType === 'varchar') {
              return chart.xAxis.tickFormat(function(d) {
                return d;
              });
            }
          };
          createChartByType = function() {
            if (chartType === 'multiBarChart') {
              chart = nv.models.multiBarChart().margin({
                top: 10,
                right: 30,
                bottom: 150,
                left: 60
              }).x(function(d) {
                return d.x;
              }).y(function(d) {
                return d.y;
              }).tooltip(function(key, x, y, e, graph) {
                return "<h3>" + key + "</h3><p>" + y + " on " + x + "</p>";
              });
            } else if (chartType === 'stackedAreaChart') {
              chart = nv.models.stackedAreaChart().margin({
                top: 10,
                right: 30,
                bottom: 150,
                left: 60
              }).x(function(d) {
                return d.x;
              }).y(function(d) {
                return d.y;
              }).clipEdge(true).tooltip(function(key, x, y, e, graph) {
                return "<h3>" + key + "</h3><p>" + y + " on " + x + "</p>";
              });
            }
            return void 0;
          };
          updateChartByType = function() {
            if (chartType === 'multiBarChart' || chartType === 'stackedAreaChart') {
              console.log("Updating the d3 graph with: " + (JSON.stringify(dataSet)));
              setAxisFormatting(dataSet);
              d3.select(svgSelector).datum(dataSet).transition().duration(500).call(chart);
              chart.update();
            }
            return void 0;
          };
          handleChart = function() {
            if (chart === void 0) {
              console.log("Creating a new d3 Graph");
              return nv.addGraph(function() {
                createChartByType();
                setAxisFormatting(dataSet);
                d3.select(svgSelector).datum(dataSet).transition().duration(500).call(chart);
                nv.utils.windowResize(chart.update);
                return chart;
              });
            } else {
              return updateChartByType();
            }
          };
          handlePie = function() {
            var pieData;

            pieData = _.flatten(_.map(dataSet, function(stream) {
              return _.map(stream.values, function(item) {
                return item;
              });
            }));
            if (chart === void 0) {
              console.log("Creating a new Pie Graph with dataSet: " + (JSON.stringify(dataSet)));
              return nv.addGraph(function() {
                chart = nv.models.pieChart().x(function(d) {
                  return d.x;
                }).y(function(d) {
                  return d.y;
                }).showLabels(true);
                d3.select(svgSelector).datum(pieData).transition().duration(500).call(chart);
                nv.utils.windowResize(chart.update);
                return chart;
              });
            } else {
              console.log("Updating the Pie graph with: " + (JSON.stringify(dataSet)));
              d3.select(svgSelector).datum(pieData).transition().duration(500).call(chart);
              return chart.update();
            }
          };
          handleBubble = function() {
            chart = new Bubble("graph_container");
            chart.initialize_data(dataSet);
            chart.start();
            return chart.display_group_all();
          };
          handleOptionsChanges = function() {
            if ((dataSet != null ? dataSet.length : void 0) > 0) {
              if (chartType === 'multiBarChart' || chartType === 'stackedAreaChart') {
                return handleChart();
              } else if (chartType === 'bubble') {
                return handleBubble();
              } else if (chartType === 'pie') {
                return handlePie();
              } else {
                return console.warn("Data to graph but no type of Graph selected!");
              }
            } else {
              return console.warn("No data given to graph!");
            }
          };
          resetSvg = function() {
            chart = void 0;
            console.debug("Resetting SVG");
            d3.selectAll(svgSelector).remove();
            return d3.select(containerSelector).append("svg");
          };
          scope.$watch("val", function(newVal, oldVal) {
            dataSet = newVal;
            console.debug("Dataset changed to: " + (JSON.stringify(dataSet)));
            return handleOptionsChanges();
          });
          return scope.$watch("type", function(newVal, oldVal) {
            chartType = newVal;
            console.debug("chartType changed to: " + chartType);
            if (newVal !== oldVal && newVal !== void 0) {
              resetSvg();
            }
            return handleOptionsChanges();
          });
        }
      };
    });
  });

}).call(this);

/*
//@ sourceMappingURL=directives.map
*/
