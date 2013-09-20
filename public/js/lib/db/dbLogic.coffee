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
define ['underscore'], (_) ->
  dbLogic = {}

  dbLogic.processDataSet = (dataSet, dataSetData, callback) ->

#    console.log "dataSet: #{JSON.stringify(dataSet)}"
    console.log "dataSet length: #{dataSet.length}"
#    console.log "dataSetData: #{JSON.stringify(dataSetData)}"

    # Take each d3 formatted key/values hash from each dbReference in the dataset and put it in one single array
    streams = []
    _.each dataSetData, (resultsHash) ->
      _.each resultsHash, (theHash, dbRefKey) ->
        if _.has theHash, 'd3Data'
          # With introduction of mutliplexed data I've made it so all d3Data results are arrays.  Either 1 or more
          _.each theHash.d3Data, (d3Data) ->
            streams.push d3Data


    callback null, streams

  return dbLogic
