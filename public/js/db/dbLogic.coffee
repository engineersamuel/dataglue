# This doesn't work
define ['underscore'], (_) ->

  tmp = {}
  data = undefined

  dbLogic = {}

  dbLogic.processDataSet = (dataSet, dataSetData) ->
    if dataSetData
      data = dataSetData

    console.log "dataSet: #{JSON.stringify(dataSet)}"
    console.log "dataSet length: #{dataSet.length}"
    console.log "dataSetData length: #{data.length}"
    # Loop through each dataset
    _.each _.keys(data), (key) ->
      # console.log "Looping on key: #{key}"

      tmp[key] = {
        rawValues: undefined
      }
      # Make sure the d3 key is in the hash
      if not tmp[key]['d3']?
        tmp[key]['d3'] = {}

      # Discover any group bys and group by
      _.each dataSet.dbReferences[key].fields, (field) ->
        # console.log "Looping on field: #{JSON.stringify(field)}"

        # Make sure the field is in the hash
        if not tmp[key]['field']?
          tmp[key]['field'] = field

        ################################################
        # Grouping by must always come first
        ################################################
        if field['groupBy']? and field['groupBy'] isnt ""
          groupedRows = undefined
          console.log "Grouping by #{field.groupBy}"
          if field.groupBy is 'year'
            groupedRows = _.groupBy data[key], (row) ->
              fieldValue = row[field['COLUMN_NAME']]
              return moment(fieldValue).format('YYYY')
          else if field['groupBy'] is 'month'
            groupedRows = _.groupBy data[key], (row) ->
              fieldValue = row[field['COLUMN_NAME']]
              return moment(fieldValue).format('YYYY-MM')
          else if field['groupBy'] is 'day'
            groupedRows = _.groupBy data[key], (row) ->
              fieldValue = row[field['COLUMN_NAME']]
              return moment(fieldValue).format('YYYY-MM-DD')

          tmp[key].rawValues = groupedRows

      # Discover aggregations and aggregate
      _.each dataSet.dbReferences[key].fields, (field) ->
        # console.log "Looping on field: #{JSON.stringify(field)}"
        ################################################
        # Then other aggregate operations
        ################################################
        if field['aggregation']? and field['aggregation'] isnt ""
          if field['aggregation'] is 'count'
            #console.log "Aggregating by #{field['aggregation']} on field: #{JSON.stringify(field)}"

            # If not tmp[key] we have a problem
            if not tmp[key]?
              console.error "No tmp[#{key}] found, tmp: #{JSON.stringify(tmp)}"

              # If not rawValues we have a problem
            else if not tmp[key].rawValues?
              console.error "No rawValues found for key: #{key}, tmp[key]: #{JSON.stringify(tmp[key])}"

              # If there is a group by iterate each group and execute the counts
            else if not _.isArray(tmp[key].rawValues)
              # Get a list of the groups
              _.each _.keys(tmp[key].rawValues), (group) ->
                # Each group contains an array of database records
                # The count will result in { field: <number>} which may be desirable later, for now
                # This assumes the length of the array in each group is the count which is not always
                # Going to be correct
                # TODO
                theCount = _.countBy(tmp[key].rawValues[group], (row) -> return if _.has(row, field['COLUMN_NAME']) then field['COLUMN_NAME'] else undefined)

                # Since right now I am only concerned with 1d counts, grab the field only
                theCount = theCount[field['COLUMN_NAME']]

                #console.log "The count of group: #{group} is #{theCount}"

                # Make sure the hash exists on the d3 group
                if not tmp[key]['d3'][group]?
                  tmp[key]['d3'][group] = {}

                # Set the count, which is determined by the field obj
                tmp[key]['d3'][group]['count'] = theCount

              # Otherwise we are dealing with an array of values not grouped
            else if _.isArray tmp.rawValues
              console.warn "Not yet Implemented!"


  dbLogic.convertToD3 = () ->
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
    #Object {kcsdw⦀kcsdw_jjaggars⦀omniture_processed_files: Object}
    #  kcsdw⦀kcsdw_jjaggars⦀omniture_processed_files: Object
    #    d3: Object
    #      2013-07-28: Object
    #        count: 173
    #      2013-07-29: Object
    #        count: 67

    tmpD3DataSet = []
    _.each _.keys(tmp), (dbReference) ->
      stack = {
        key: tmp[dbReference]['field']['COLUMN_NAME']
        values: []
      }
      _.each _.keys(tmp[dbReference]['d3']), (groupedKey) ->
        stack['values'].push
          x: groupedKey
          y: tmp[dbReference]['d3'][groupedKey]['count']
          f: tmp[dbReference]['field']

      # Push the stack onto the d3 dataset
      tmpD3DataSet.push stack

#      console.log $scope.d3DataSet
#      $scope.d3DataSet = tmpD3DataSet
      return tmpD3DataSet


  return dbLogic
