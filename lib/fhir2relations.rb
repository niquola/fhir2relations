require "fhir2relations/version"
require 'virtus'
require 'active_support/core_ext'

module Fhir2relations
  autoload :Loader, 'fhir2relations/loader'
  autoload :Facade, 'fhir2relations/facade'
  autoload :Xml, 'fhir2relations/xml'
  autoload :Db, 'fhir2relations/db'
  autoload :ResourcesRepository, 'fhir2relations/resources_repository'
  autoload :DatatypesRepository, 'fhir2relations/datatypes_repository'
end
