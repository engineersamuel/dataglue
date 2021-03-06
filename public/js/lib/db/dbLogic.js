// Generated by CoffeeScript 1.6.2
(function() {
  define(['underscore'], function(_) {
    var dbLogic;

    dbLogic = {};
    dbLogic.processDataSet = function(dataSet, dataSetData, callback) {
      var streams;

      console.log("dataSet length: " + dataSet.length);
      streams = [];
      _.each(dataSetData, function(resultsHash) {
        return _.each(resultsHash, function(theHash, dbRefKey) {
          if (_.has(theHash, 'd3Data')) {
            return _.each(theHash.d3Data, function(d3Data) {
              return streams.push(d3Data);
            });
          }
        });
      });
      return callback(null, streams);
    };
    return dbLogic;
  });

}).call(this);

/*
//@ sourceMappingURL=dbLogic.map
*/
