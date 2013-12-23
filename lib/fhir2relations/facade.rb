require 'active_support/core_ext'

module Fhir2relations
  class Facade
    attr :db

    def initialize(db)
      @db = db
    end

    def migrate!
      db.execute(File.read(File.dirname(__FILE__) + '/../../db/migrations/20131121_schema.sql'))
    end

    def load_version(version)
      Loader.load_version(
        db, '0.12',
        _xml.xml("#{version}/fhir-base.xsd"),
        _xml.xml("#{version}/profiles-resources.xml")
      )
    end

    def dataset(table_name)
      _db.dataset(db, table_name)
    end

    class RepositoryProxy
      attr :db
      attr :mod

      def initialize(db, mod)
        @mod = mod
        @db = db
      end

      def method_missing(name, *args)
        if mod.respond_to?(name)
          mod.send(name, *([db] + args))
        else
          super
        end
      end
    end

    def datatypes_repository
      @datatypes_repository ||= RepositoryProxy.new(db, DatatypesRepository)
    end

    def resources_repository
      @resources_repository ||= RepositoryProxy.new(db, ResourcesRepository)
    end

    private

    #REQUIRES

    def _xml
      Fhir2relations::Xml
    end

    def _db
      Fhir2relations::Db
    end
  end
end
