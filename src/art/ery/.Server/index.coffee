# generated by Neptune Namespaces v1.x.x
# file: Art/Ery/.Server/index.coffee

module.exports = require './namespace'
.includeInNamespace require './Server'
.addModules
  Main:                require './Main'               
  PromiseHttp:         require './PromiseHttp'        
  PromiseJsonWebToken: require './PromiseJsonWebToken'