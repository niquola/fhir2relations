module Fhir2relations
  module DatatypesRepository
    class Datatype
      include Virtus.model
      attribute :version, String
      attribute :type, String
      attribute :kind, String
      attribute :extension, String
      attribute :documentation, Array[String]
    end

    def complex_type_by_name(db, version, name)
      wrap(_complex_types(db, version).where(type: name).first)
    end

    def complex_types(db, version)
      wrap_collection(_complex_types(db, version).all)
    end

    def datatypes(db, version)
      wrap_collection(_datatypes(db, version).all)
    end

    def _db
      Db
    end

    private :_db

    def _complex_types(db, version)
      _db.dataset(db, :complex_types).where(version: version)
    end

    def _datatypes(db, version)
      _db.dataset(db, :datatypes).where(version: version)
    end

    def wrap_collection(collection)
      collection.map do |attrs|
        wrap(attrs)
      end
    end

    def wrap(attrs)
      case attrs[:kind]
      when 'complexType'
        Datatype.new(attrs)
      when 'simpleType'
        Datatype.new(attrs)
      else
        Datatype.new(attrs)
      end
    end

    extend self
  end
end
