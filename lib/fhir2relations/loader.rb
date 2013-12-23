require 'nokogiri'
require 'active_support/core_ext'

module Fhir2relations
  module Loader
    def self.use(name, mod)
      self.send(:define_method, name) { mod }
    end

    use :_x, Fhir2relations::Xml
    use :_db, Fhir2relations::Db

    # @dirty
    def load_version(db, version, datatype_xml, resource_xml)
      _db.dataset(db, :versions).insert(version: version)
      insert_datatypes(db, version, datatype_xml)
      datatypes_transformations(db, version)
      fill_resources_table(db,resource_xml)
    end

    # @dirty
    def insert_datatypes(db, version, xml)
      datatypes = _db.dataset(db, :datatypes)
      elements = _db.dataset(db, :datatype_elements)
      enums = _db.dataset(db,:datatype_enums)

      versioned = ->(c){ update_all(c, version: version) }

      versioned.call(collect_datatypes(xml)).each do |dt|
        els = versioned.call(dt.delete(:elements))
        ens = versioned.call(dt.delete(:enums))
        datatypes.insert(dt)
        els.each{|el| elements.insert(el) }
        ens.each{|en| enums.insert(en) }
      end
    end

    def datatypes_transformations(db, version)
      db.execute <<-SQL
        update meta.datatype_enums
        set datatype = regexp_replace(datatype, '-list$', '')
      SQL

      db.execute <<-SQL
        delete from meta.datatypes
        where type ilike '%-list'
      SQL
    end

    def update_all(col, attrs)
      col.map{|e| e.merge(attrs)}
    end

    def collect_paths(xml, paths, &block)
      idx = 0
      paths.map{|p| xml.xpath(p).to_a}.sum.map do |node|
        idx+=1
        yield node, idx
      end.compact
    end

    def collect_datatypes(xml)
      collect_paths xml, ['//simpleType', '//complexType'] do |node, _|
        type = node[:name]
        next unless type
        {
          kind: node.name,
          type: type,
          documentation: pg_array(node_text(node, './annotation/documentation')),
          extension: node_attr(node, './complexContent/extension/attribute', :type),
          restriction_base: node_attr(node, './restriction', :base),
          elements: update_all(collect_datatype_elements(node), datatype: type),
          enums: update_all(collect_enums(node),datatype: type)
        }
      end
    end

    def collect_datatype_elements(node)
      collect_paths node, ['./complexContent/extension/sequence/element'] do |enode, idx|
        {
          sequence: idx,
          name: enode[:name] || enode[:ref],
          type: enode[:type],
          min_occurs: enode[:minOccurs],
          max_occurs: enode[:maxOccurs],
          documentation: node_text(enode, './annotation/documentation')
        }
      end
    end

    def collect_enums(node)
      collect_paths node, ['./restriction/enumeration'] do |enode, _|
        {
          value: enode[:value],
          documentation: node_text(enode, './annotation/documentation')
        }
      end
    end

    def node_text(node, path)
      node.xpath(path).map(&:text)
    end

    def node_attr(node, path, attr)
      node.xpath(path).first.try(:[],attr)
    end

    def node_attrs(node, path, attr)
      node.xpath(path).map{|n| n[attr]}
    end

    def fill_resources_table(db, xml)
      resources = db[:meta__resources]
      elements = db[:meta__resource_elements]
      version = '0.12'

      xml.xpath('//structure').each do |node|
        type = node.xpath('./type').first[:value]
        resources.insert(type: type, version: version)
        node.xpath('./element').each do |el|
          el_attrs = {
            version: version,
            path: pg_array(el.xpath("./path").first.try(:[], :value).split('.')),
            resource: type,
            short: el_attrs(el, :short),
            formal: el_attrs(el, :formal),
            max: el_attrs(el, :max),
            min: el_attrs(el, :min),
            synonym: pg_array(el_attrs(el, :synonym)),
            type: pg_array(el_attrs(el, 'type/code')),
            is_modifier: el_attr(el, :isModifier),
            mapping_target: el_attr(el, 'mapping/target'),
            mapping_map: el_attr(el, 'mapping/map')
          }
          elements.insert(el_attrs)
        end
      end
    end

    def pg_array(args)
      if args.empty?
        nil
      else
        Sequel.pg_array(args)
      end
    end

    def el_attr(el, attr)
      el.xpath("./definition/#{attr}").try(:first).try(:[],:value)
    end

    def el_attrs(el, attr)
      el.xpath("./definition/#{attr}").map{|i| i[:value]}
    end
    extend self
  end
end
