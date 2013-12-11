module Fhir2relations
  module ResourcesRepository
    def _db
      Db
    end

    private :_db

    def find_by_name( db, version, name)
      _db.dataset(db, :resources)
      .where(version: version)
      .where(type: name)
      .first
    end

    extend self
  end
end
