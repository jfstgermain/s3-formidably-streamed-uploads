fs = require 'fs'
rimraf = require 'rimraf'

{print} = require 'util'
{spawn} = require 'child_process'

execCommand = (command, options, cb) ->
  commandProc = spawn command, options
  commandProc.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  commandProc.stdout.on 'data', (data) ->
    print data.toString()
  commandProc.on 'exit', (code) ->
    if code is 0
      console.log "Completed executing #{command}"
      cb?()
    else
      console.log "Command #{command} ended with exit code: #{code}"

clean = (cb) ->
  rimraf './lib', ->
    fs.mkdir './lib', cb

coffeeCall = (compileOption = '', cb) ->
  execCommand 'coffee', ["-c#{compileOption}", '-o', 'lib', 'src'], cb

build = (cb) ->
  clean ->
    coffeeCall '', cb

local = (cb) ->
  build ->
    coffeeCall 'w'
    #execCommand 'nodemon', ['--delay','7','--watch', 'lib'], cb

debug = (cb) ->
  build ->
    coffeeCall 'w'
    #execCommand 'nodemon', ['--debug','--delay','7','--watch', 'lib'], cb

task 'clean', 'Clean compiled js files in \'lib\'', ->
  clean ->
    console.log '\'lib\' cleaned.'

task 'build', 'Build lib/ from src/', ->
  build()

task 'watch', 'Build and watch files', ->
  local()

# https://github.com/TrevorBurnham/connect-assets/blob/master/Cakefile
