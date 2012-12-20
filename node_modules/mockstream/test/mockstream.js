var assert = require('assert'),
    mockstream = require('..');

describe('Mock data stream', function() {
    
    it('should emit mock data', function(done) {
        var chunkSize = 1024,
            streamLength = 2048,
            stream = new mockstream.MockDataStream({
                chunkSize: chunkSize,
                streamLength: streamLength
            }),
            read = 0;
            
        stream
            .start()
            .on('data', function(data) {
                read += data.length;
            })
            .on('end', function() {
                assert.equal(streamLength, read);
                done();
            });        
    });    
});