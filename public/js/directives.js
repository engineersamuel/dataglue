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
          var chart, containerSelector, dataSet, elementId, graphType, handleBubble, handleChart, handleOptionsChanges, handlePie, resetSvg, setAxisFormatting, svgSelector;

          elementId = element.attr('id');
          containerSelector = "#" + elementId;
          svgSelector = "#" + elementId + " svg";
          dataSet = void 0;
          graphType = void 0;
          chart = void 0;
          setAxisFormatting = function(dataSet, chart) {
            var xAxisDataType, xAxisGroupBy, yAxisDataType, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;

            xAxisDataType = (_ref = dataSet[0]) != null ? (_ref1 = _ref[0]) != null ? _ref1.xType : void 0 : void 0;
            xAxisGroupBy = (_ref2 = dataSet[0]) != null ? (_ref3 = _ref2[0]) != null ? _ref3.xGroupBy : void 0 : void 0;
            yAxisDataType = (_ref4 = dataSet[0]) != null ? (_ref5 = _ref4[0]) != null ? _ref5.yType : void 0 : void 0;
            if (yAxisDataType === 'int') {
              chart.yAxis.tickFormat(function(d) {
                return d3.format("d")(d);
              });
            } else if (yAxisDataType === 'float') {
              chart.yAxis.tickFormat(d3.format(',.1f'));
            }
            if (xAxisDataType === 'datetime') {
              if ((xAxisGroupBy != null) === 'day') {
                chart.xAxis.tickFormat(function(d) {
                  return moment(d).format('YYYY-MM-DD');
                });
              } else if ((xAxisGroupBy != null) === 'month') {
                chart.xAxis.tickFormat(function(d) {
                  return moment(d).format('YYYY-MM');
                });
              } else {
                chart.xAxis.tickFormat(function(d) {
                  return moment(d).format('YYYY-MM-DD');
                });
              }
            }
            return chart.yAxis.tickFormat(function(d) {
              return d3.format("d")(d);
            });
          };
          handleChart = function() {
            if (chart === void 0) {
              console.log("Creating a new d3 Graph");
              return nv.addGraph(function() {
                chart = nv.models.multiBarChart().margin({
                  top: 10,
                  right: 30,
                  bottom: 150,
                  left: 30
                }).x(function(d) {
                  return d.x;
                }).y(function(d) {
                  return d.y;
                }).tooltip(function(key, x, y, e, graph) {
                  return "<h3>" + key + "</h3><p>" + y + " on " + x + "</p>";
                });
                setAxisFormatting(dataSet, chart);
                d3.select(svgSelector).datum(dataSet).transition().duration(500).call(chart);
                nv.utils.windowResize(chart.update);
                return chart;
              });
            } else {
              console.log("Updating the d3 graph with: " + (JSON.stringify(dataSet)));
              setAxisFormatting(dataSet, chart);
              d3.select(svgSelector).datum(dataSet).transition().duration(500).call(chart);
              return chart.update();
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
              if (graphType === 'multiBarChart') {
                return handleChart();
              } else if (graphType === 'bubble') {
                return handleBubble();
              } else if (graphType === 'pie') {
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
            return handleOptionsChanges();
          });
          return scope.$watch("type", function(newVal, oldVal) {
            graphType = newVal;
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
