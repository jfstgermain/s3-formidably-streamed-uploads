## s3-formidably-streamed-uploads
Wraps knox, knox-mpu and formidable for easy streaming of file uploads directly to S3 without touching the hard drive

** Take note that when used as an express middlewear, it needs to be the first in the list if there are many that are used **
> "This is not a problem specific to any module really. It's how node core works, since everything is asynchronous. TCP (and thus HTTP) streams in node emit 'data' events every time a chunk of data is received from the client (this can often happen within the same tick where the incoming connection event occurs). If nobody is listening for data on that stream, then the data is discarded. This technique allows for low memory usage since chunks are emitted as they come in and they are not stored or buffered up anywhere.

Express also does not buffer requests' 'data' events for the same reason node core doesn't (memory usage). Express could support something like that, but I doubt you'll see that added anytime soon."
See [] (https://github.com/felixge/node-formidable/issues/130#issuecomment-3781889)

see: http://anders.janmyr.com/2012/04/writing-node-module.html