# generated by Neptune Namespaces v3.x.x
# file: Art.Ery/.Flux/index.coffee

module.exports = require './namespace'
module.exports
.includeInNamespace require './Flux'
.addModules
  ArtEryFluxModel:      require './ArtEryFluxModel'     
  ArtEryQueryFluxModel: require './ArtEryQueryFluxModel'