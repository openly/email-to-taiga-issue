winston = require 'winston'
config = require 'config'

global.log = new (winston.Logger)(transports: [
  new (winston.transports.Console)
  new (winston.transports.File)(filename: 'logs/app.log')
])

global.config = require 'config'