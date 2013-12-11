require 'active_support/core_ext'

module Fhir2relations
  class Facade
    attr :db

    def new(db)
      @db = db
    end

    def load_version(version)
      dt_xml = x.xml("0.12/fhir-base.xsd")
      xml = x.xml("0.12/profiles-resources.xml")
      Loader.load(db, '0.12', dt_xml, xml)
    end

    private

    def xml
      Fhir2relations::Xml
    end
  end
end
