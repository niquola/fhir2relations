module Fhir2relations
  module Db
    def dataset(db, name)
      (@dataset ||= {})[name.to_sym] ||= db["meta__#{name}".to_sym]
    end

    # extract attrs from coll
    def pluck(coll, attr_name)
      coll.map{|ct| ct[attr_name]}.uniq.compact
    end

    # yield with block for relation
    def query_block(rel, &block)
      rel = yield(rel) if block_given?
      rel.all
    end


    # put has_many into collection
    def with_children(parents, pkey, coll_name, children, ckey)
      parents.each_with_object({}) do |p, acc|
        acc[p[pkey]] = p
      end.tap do |parents_idx|
        children.each do |c|
          (parents_idx[c[ckey]][coll_name] ||= [])<< c
        end
      end.values
    end
    extend self
  end
end
