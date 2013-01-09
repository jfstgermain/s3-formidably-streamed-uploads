async = require 'async'
formidable = require 'formidable'
knox = require 'knox'
MultiPartUpload = require 'knox-mpu'
util = require 'util'
fs = require 'fs'

# @see:
# https://github.com/Obvious/pipette
# https://github.com/dominictarr/mux-demux
# https://github.com/substack/stream-handbook
# https://groups.google.com/forum/?fromgroups=#!topic/nodejs/4e3gphdKos0
# https://groups.google.com/forum/?fromgroups=#!topic/nodejs/Avf95ibIqHo    <---
# https://github.com/Obvious/pipette/blob/danfuzz-write/lib/tee.js
# https://github.com/mikeal/morestreams/blob/master/main.js (buffered streams)

module.exports = (options) ->
  options = options || {}

  options.uploadDir = options.uploadDir || null
  options.processFile = options.processFile || (file, done) ->
    done null, [ fs.createReadStream file.path ]
    
  pushToS3 = (readStream, cb) ->
    console.log "[ streamed-s3-upload ] Pushing to S3 (#{readStream.filename})"

    mpu = new MultiPartUpload
      client: options.knoxClient
      objectName: readStream.filename
      stream: readStream
      cb
      
  handleFile = (file, cb) ->
    options.processFile file, (err, readStreams) ->
      if not Array.isArray readStreams 
        readStreams = [ readStreams ]
        
      async.map readStreams, pushToS3, cb   
      
      
    # https://groups.google.com/forum/?fromgroups=#!topic/nodejs/Avf95ibIqHo
    ###
    async.forEach thumbnailSizes,
      (size, cb) ->
        saveThumbnail part, size, cb
      (err) ->
        cb err
    ###
  unlinkTempfile = (file, form) ->
    console.info "[ streamed-s3-upload ] unlinking #{file.path}"
    fs.unlink file.path, (err) ->
      if err?
        form.emit 'error', error       
            
  handleFileUpload = (req, done) ->
    form = new formidable.IncomingForm
      uploadDir: options.uploadDir

    form.keepExtensions = true
    #form.uploadDir = process.env.TMP || process.env.TMPDIR || process.env.TEMP || '/tmp' || process.cwd()
    # TODO: Why use event handlers? Just call done in 'onPart'
    form.on 's3-upload-completed', (s3res) ->
      console.info "[ streamed-s3-upload ] finished uploading"
      done null, s3res
    
    form.on 'error', (err) ->
      console.error err
      done err, null
      
    ###
    Lookup the 'file' or 'fileBegin' events instead:
    https://github.com/felixge/node-formidable#file
    ###
    
    #form.on 'fileBegin', (name, file) ->
    form.on 'file', (name, file) ->
      console.info "[ streamed-s3-upload ] file begins uploading"
      try
        handleFile file, (err, s3res) ->
          if err? 
            console.dir err
            form.emit 'error', err
          else 
            console.dir s3res
            form.emit 's3-upload-completed', null, s3res
            
          unlinkTempfile file, form  
      catch error
        form.emit 'error', error
        unlinkTempfile file, form
        
    ###
    form.onPart = (part) ->
      console.log '**onPart'
      if not part.filename then form.handlePart part
      else
        handleFilePart part, (err, s3res) ->          
          if err? 
            console.dir err
            form.emit 'error', err
          else 
            console.dir s3res
            form.emit 's3-upload-completed', null, s3res
    ###
    form.parse req

  return handleFileUpload: handleFileUpload