module Fhir2relations
  module Db
    def dataset(db, name)
      (@dataset ||= {})[name.to_sym] ||= db["meta__#{name}".to_sym]
    end
    extend self
  end
end
