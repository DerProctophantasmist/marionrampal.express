module.exports = (() ->
    # files are loaded at startup time, and their compilation result is cached. Data can then be accessed synchronously.
    # On file change, we modify the compiled cache, subsequent calls to the data will return the modified cache (synchronously)

    files = {}
    
    loadDataFile = (filename, callbacks, scope) -> 
      ref = (files[filename] = {callbacks: [callbacks]})
      scope[filename + "-watcher"] = 0
      $http({method: 'get', url: Config.dataPath + '/' +  filename, headers: {'Cache-Control': 'no-cache'}})
      .then (response) ->
          ref.data = response.data
          # we could have asked for the file numerous times between the call to $http and the response
          # hence the loop on the callback list
          for key, callbacks of files[filename].callbacks
            callbacks.onSuccess(response.data) if callbacks.onSuccess 
          return 
        ,(err) -> 
          if err.status == 404 #file doesn't exist. Beware, subsequent calls for the same file will be treated as success    
            for key, callbacks of files[filename].callbacks
              if callbacks.on404 then callbacks.on404('')              
          else #pbm, beware subsequent calls for the same file will be treated as success               
            for key, callbacks of files[filename].callbacks
              if callbacks.onError then callbacks.onError(err)       
              State.showEditors = false #disable editors, so that we don't wipe our files      
          console.log 'Could not load '+filename+' : ' + JSON.stringify(err)
          ref.data = ''
      return
    
    #this mimicks the behaviour of loading data when we have done preloading
    #simplyfies things for the calling code
    cacheData = (filename, content) -> 
      ref = (files[filename] = {callbacks: [callbacks]})
      scope[filename + "-watcher"] = 0
      ref.data = content
      callbacks.onSuccess(content) if callbacks.onSuccess 

 
    markdownContent = 
      #callbacks: {onChange, on404, onError, onSuccess }
      get: (filename) ->
        ref = files[filename]
        if !ref # we haven't yet asked for this file
          loadDataFile(filename, callbacks, scope)
        else 

          if ref.data? # already loaded
            callbacks.onSuccess(ref.data)

          ref.callbacks.push(callbacks)
          scope[filename+"-watcher"] = ref.callbacks.length  - 1
        
          scope.$on '$destroy', ()-> 
            delete callbacks[scope[filename+"-watcher"]]
            return
        return
      onChange: (filename, content) ->
        ref = files[filename]
        # console.log ref
        ref.data = content
        for own key, callbacks of ref.callbacks
          # console.log callbacks
          callbacks.onChange(content)
        return
      #this mimicks the behaviour of loading data when we have done preloading
      #simplyfies things for the calling code
      cache: (filename, content) ->
        ref = files[filename]
        if !ref # we haven't yet asked for this file
          cacheData(filename, callbacks, scope, content)
        else 
          callbacks.onSuccess(ref.data)

          ref.callbacks.push(callbacks)
          scope[filename+"-watcher"] = ref.callbacks.length  - 1
        
          scope.$on '$destroy', ()-> 
            delete callbacks[scope[filename+"-watcher"]]
            return
        return

    return markdownContent
  )()