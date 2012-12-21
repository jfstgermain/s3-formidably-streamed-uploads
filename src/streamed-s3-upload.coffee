async = require 'async'
formidable = require 'formidable'
knox = require 'knox'
MultiPartUpload = require 'knox-mpu'
util = require 'util'

# @see:
# https://github.com/Obvious/pipette
# https://github.com/dominictarr/mux-demux
# https://github.com/substack/stream-handbook
# https://groups.google.com/forum/?fromgroups=#!topic/nodejs/4e3gphdKos0
# https://groups.google.com/forum/?fromgroups=#!topic/nodejs/Avf95ibIqHo    <---
# https://github.com/Obvious/pipette/blob/danfuzz-write/lib/tee.js
# https://github.com/mikeal/morestreams/blob/master/main.js (buffered streams)

module.exports = (options) ->
  processPart = options.processPart || (readStream, done) ->
    done null, [part]
    
  pushToS3 = (readStream, cb) ->
    console.log "[ image-uploader-helper ] Pushing to S3"

    mpu = new MultiPartUpload
      client: options.knoxClient
      objectName: readStream.filename
      stream: readStream
      cb
      
  handleFilePart = (readStream, cb) ->
    # TODO: verify that processPart's signature is ok b4 proceeding
    processPart readStream, (err, readStreams) ->
      async.map readStreams, pushToS3, cb
      
      
    # https://groups.google.com/forum/?fromgroups=#!topic/nodejs/Avf95ibIqHo
    ###
    async.forEach thumbnailSizes,
      (size, cb) ->
        saveThumbnail part, size, cb
      (err) ->
        cb err
    ###
  
  handleFileUpload = (req, done) ->
    form = new formidable.IncomingForm()

    form.keepExtensions = true
    #form.uploadDir = process.env.TMP || process.env.TMPDIR || process.env.TEMP || '/tmp' || process.cwd()
    # TODO: Why use event handlers? Just call done in 'onPart'
    form.on 's3-upload-completed', (s3res) ->
      done null, s3res
    
    form.on 'error', (err) ->
      done err, null
      
    form.onPart = (part) ->
      console.log '**onPart'
      if not part.filename then form.handlePart part
      else
        handleFilePart part, (err, s3res) ->
          if err? then form.emit 'error', err
          else form.emit 's3-upload-completed', null, s3res

    form.parse req

  return handleFileUpload: handleFileUpload