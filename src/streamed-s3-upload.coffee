async = require 'async'
formidable = require 'formidable'
knox = require 'knox'
MultiPartUpload = require 'knox-mpu'
util = require 'util'
fs = require 'fs'
BufferedStream = require('morestreams').BufferedStream
logger = require 'winston'

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

  options.processFilePart = options.processFilePart || (filePartStream, done) ->
    done null, [ filePartStream ]

  options.getUploadPath = options.getUploadPath || (fileSetName) ->
    "#{fileSetName}"
    
  pushToS3 = (readStream, s3UploadPath, cb) ->
    console.log "[ streamed-s3-upload ] Pushing to S3 (#{readStream.filename})"

    logger.profile 'pushToS3'
    mpuOptions = 
      objectName: "#{s3UploadPath}/#{readStream.filename}"
      stream: readStream
      processFilePart: options.processFilePart
      client: options.client
      headers: options.headers

    if readStream.size?
      mpuOptions.metaInfo = 
        size: readStream.size

    mpu = new MultiPartUpload mpuOptions, (err, res) -> 
      logger.profile 'pushToS3'
      cb err, res
      
  handleFilePart = (filePartStream, cb) ->
    s3UploadPath = options.getUploadPath filePartStream.filename

    options.processFilePart filePartStream, (err, readStreams) ->
      console.log "**** processFilePart"
      if not Array.isArray readStreams 
        readStreams = [ readStreams ]
        
      async.map readStreams, ((readStream, cb2) -> pushToS3 readStream, s3UploadPath, cb2), cb   
      
      
  # https://groups.google.com/forum/?fromgroups=#!topic/nodejs/Avf95ibIqHo
  unlinkTempfile = (file, form) ->
    console.info "[ streamed-s3-upload ] unlinking #{file.path}"
    fs.unlink file.path, (err) ->
      if err?
        form.emit 'error', error       
            
  handleFileUpload = (req, done) ->
    filesMeta = []
    form = new formidable.IncomingForm
      uploadDir: options.uploadDir

    form.keepExtensions = true
    #form.uploadDir = process.env.TMP || process.env.TMPDIR || process.env.TEMP || '/tmp' || process.cwd()
    # TODO: Why use event handlers? Just call done in 'onPart'
    form.on 's3-upload-completed', (s3res) ->
      console.info "[ streamed-s3-upload ] finished uploading"
      filesMeta.push s3res
      form._flushing--
      form._maybeEnd()
    
    form.on 'error', (err) ->
      console.info "[ streamed-s3-upload ] an error occured"
      console.error err
      done err, null

    form.on 'end', ->
      done null, filesMeta
    
    form.onPart = (part) ->
      console.info "[ streamed-s3-upload ] onPart begin"
      try
        if not part.filename then form.handlePart part
        else
          form._flushing++
          handleFilePart part, (err, s3res) ->    
            if err? 
              form.emit 'error', err
            else 
              form.emit 's3-upload-completed', s3res
      catch error
        form.emit 'error', error
            
    form.parse req

  return handleFileUpload: handleFileUpload
