module Fhir2relations
  module ResourcesRepository

    def resources(db, cnd, &block)
      ress = _db.query_block(_db.dataset(db, :resources).where(cnd), &block)
      els = _db.dataset(db, :resource_elements)
      .where(resource:  _db.pluck(ress, :type)).all

      els = coll_to_tree(els)
      _db.with_children(ress, :type, :elements, els, :resource)
    end

    def coll_to_tree(coll)
      coll.select do |e|
        next false unless e[:path].length == 2
        collect_elements_recursive(e, coll)
      end.compact
    end

    def collect_elements_recursive(parent, coll)
      parent[:elements] = coll.select do |e|
        next false unless e[:path][0..-2] == parent[:path]
        collect_elements_recursive(e, coll)
      end
      parent
    end

    def resource(db, cnd)
      resources(db, cnd){|rel| rel.limit(1)}.first
    end

    private

    def _db
      Db
    end

    extend self
  end
end
