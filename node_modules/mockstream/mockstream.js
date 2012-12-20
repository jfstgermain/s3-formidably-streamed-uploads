var stream = require('stream'),
    util = require('util');

/**
  The MockDataStream merely emits blocks of data in chunks of a given size
  up until a stream length is reached
 **/
function MockDataStream(opts) {
    opts = opts || {};
    this.chunkSize = opts.chunkSize || 1024; // Default 1K chunk size
    this.streamLength = opts.streamLength || 1048576; // Default 1MB stream length
    this.written = 0;
    this.paused = false;
}   
util.inherits(MockDataStream, stream); 

/**
  Starts pumping on mock data
 **/
MockDataStream.prototype.start = function() {
    process.nextTick(this._writeData.bind(this));
    return this;
}

/**
  Pause the stream
 **/
MockDataStream.prototype.pause = function() {
    this.paused = true;
}

/**
  Resume the stream
 **/
MockDataStream.prototype.resume = function() {
    this.start();
}

MockDataStream.prototype._writeData = function() {
    
    if (this.paused) return;
    
    var remainder = this.streamLength - this.written,
        dataLength = (remainder > this.chunkSize ? this.chunkSize : remainder),
        data = new Array(dataLength + 1).join("0"),
        buf = new Buffer(data);
        
    this.emit('data', buf);
    
    this.written += dataLength;        
    
    if (this.written >= this.streamLength) {
        this.emit('end');
    } else {
        process.nextTick(this._writeData.bind(this));
    }
}

module.exports = {
    MockDataStream: MockDataStream
}