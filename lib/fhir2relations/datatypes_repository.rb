module Fhir2relations
  module DatatypesRepository
    def primitive_types(db, cnd = {})
      prim_cnd = <<-SQL
      (
        type not in (select distinct(datatype) from meta.datatype_enums)
        and type not in (select distinct(datatype) from meta.datatype_elements)
        and extension not in (select distinct(datatype) from meta.datatype_enums)
      ) AND type <> 'Extension'
      SQL

      _datatypes(db).where(cnd)
      .where(prim_cnd).all
    end

    def complex_type(db, cnd)
      complex_types(db, cnd){|rel| rel.limit(1)}.first
    end

    def complex_types(db, cnd, &block)
      cts = _db.query_block(_complex_types(db).where(cnd), &block)

      els = _elements(db, _db.pluck(cts, :version))
      .where( datatype: _db.pluck(cts, :type)).all

      _db.with_children(cts, :type, :elements, els, :datatype)
    end

    def enum_type(db, cnd)
      enum_types(db, cnd){|rel| rel.limit(1)}.first
    end

    def enum_types(db, cnd, &block)
      cts = _db.query_block(_enum_types(db).where(cnd), &block)

      els = _enums(db, _db.pluck(cts, :version))
      .where(datatype: _db.pluck(cts, :type))

      _db.with_children(cts, :type, :enums, els, :datatype)
    end

    private

    def _db
      Db
    end

    def _complex_types(db)
      de = _db.dataset(db, :datatype_elements)
      _db.dataset(db, :datatypes)
      .where(type: de.distinct(:datatype).select(:datatype))
    end

    def _enum_types(db)
      de = _db.dataset(db, :datatype_enums)
      _db.dataset(db, :datatypes)
      .where(type: de.distinct(:datatype).select(:datatype))
    end

    def _enums(db, version)
      _db.dataset(db, :datatype_enums).where(version: version)
    end

    def _elements(db, version)
      _db.dataset(db, :datatype_elements)
      .where(version: version)
    end

    def _datatypes(db)
      _db.dataset(db, :datatypes)
    end

    extend self
  end
end
