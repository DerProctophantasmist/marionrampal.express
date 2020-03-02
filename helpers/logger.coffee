bunyan = require('bunyan')
rfs = require('rotating-file-stream');
path = require('path')

# create a rotating write stream
accessLogStream = rfs('access.log', {
  interval: '3d', # rotate every 3 days
  maxFiles: 3,
  path: path.join(process.env.EXPRESS_ROOT, 'log')
})

loggerInstance = bunyan.createLogger(
    name: 'main Logger',
    serializers: 
        req: require('bunyan-express-serializer')
        res: bunyan.stdSerializers.res
        err: bunyan.stdSerializers.err
    streams: [
            stream: accessLogStream
            level: 'info'
        ,
            stream: process.stdout
            level: 'error'
    ]
)

logResponse = (id, body, statusCode) ->
    log = loggerInstance.child({
        id: id,
        body: body,
        statusCode: statusCode
    }, true)
    log.info('response')

requestLogger = (req) ->
    if req == null 
        loggerInstance.error('logger: request not set when initializing logger')
    if req.id == null
        loggerInstance.error('logger: id not set on request')
    loggerInstance.child({
        id: req.id
    }, true)




module.exports = {
    mainLogger: loggerInstance
    logResponse
    requestLogger
}
