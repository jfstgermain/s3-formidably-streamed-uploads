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
    console.time "[ image-uploader-helper ] Pushing to S3"

    mpu = new MultiPartUpload
      client: global.knoxClient
      objectName: readStream.filename
      stream: readStream
      cb
      
  handleFilePart = (readStream, cb) ->
    # TODO: verify that processPart's signature is ok b4 proceeding
    processPart readStream, (err, readStreams) ->
      async.map readStreams, pushToS3, (err, results) ->
        cb err, results
      
      
    # https://groups.google.com/forum/?fromgroups=#!topic/nodejs/Avf95ibIqHo
    ###
    async.forEach thumbnailSizes,
      (size, cb) ->
        saveThumbnail part, size, cb
      (err) ->
        cb err
    ###
      
  handleImageUpload = (req, res, next) ->
    form = new formidable.IncomingForm()

    form.keepExtensions = true
    form.uploadDir = process.env.TMP || process.env.TMPDIR || process.env.TEMP || '/tmp' || process.cwd()
    form.onPart = (part) ->
      console.log '**onPart'
      if not part.filename then form.handlePart part
      else
        handleFilePart part, (err, res) ->
          if err?
            console.error err
            @emit 'error', err
          else @emit 'end'

    form.parse req, (err, fields, files) ->
      if err?
        console.dir err
        next err
      else next()