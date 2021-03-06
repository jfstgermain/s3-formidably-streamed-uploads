fs = require 'fs'
http = require 'http'
net = require 'net'
knox = require 'knox'
MultiPartUpload = require 'knox-mpu'
should = require 'should'
s3auth = require './s3auth.json'
StreamS3upload = require '../lib/streamed-s3-upload'
mockstream = require 'mockstream'

server = http.createServer()
port = 13532

describe 'Formidable / knox multipart form uploads', ->
  knoxClient = null;
    
  before (done) ->
    try 
      knoxClient = knox.createClient s3auth
      done()
    catch err
      done 'Could not create Knox client - please provide an ./s3auth.json file'
    
  it 'should be able to pipe parts without demuxing', (done) ->
    # TODO: Clean up in S3 after...
    socket = net.createConnection port
    file = fs.createReadStream "#{__dirname}/fixtures/400.png"
    
    server.listen port, ->
      server.once 'request', (req, res) ->
        new streamS3upload = StreamS3upload 
          knoxClient: knoxClient
          
        streamS3upload.handleFileUpload req, (err, s3res) ->
          done()
          
      file.pipe socket    

  ###
  it 'should be able to pipe a stream directly to Amazon S3 using the multi part upload', (done) ->
    testLength = 7242880
    chunkSize = 2048
    stream = new mockstream.MockDataStream 
      chunkSize: chunkSize
      streamLength: testLength
    opts =
      client: client
      objectName: Date.now() + '.txt'
      stream: stream
    mpu = null
            
    # Upload the file
    mpu = new MultiPartUpload opts, (err, body) ->
      if err? then done err
      else
        body['Key'].should.be.equal opts.objectName
            
        # Clean up after ourselves
        client.deleteFile opts.objectName, (err, res) ->
          if err? then done "Could not delete file [#{err}]"
          else done()
           
    stream.start()
  ###
