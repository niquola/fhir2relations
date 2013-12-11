module Fhir2relations
  module Repository
    def wrap_collection(collection, mod)
      collection.map do |attrs|
        mod.wrap(attrs)
      end
    end

    extend self
  end
end
