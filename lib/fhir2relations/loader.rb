require 'nokogiri'
require 'active_support/core_ext'

module Fhir2relations
  module Loader
    def _x
      Fhir2relations::Xml
    end

    def _db
      Fhir2relations::Db
    end

    def load_version(db, version)
      dt_xml = _x.xml("0.12/fhir-base.xsd")
      xml = _x.xml("0.12/profiles-resources.xml")
      self.load(db, version, dt_xml, xml)
    end

    def load(db, version, datatypes_xml, resources_xml)
      _db.dataset(db, :versions).insert(version: version)

      fill_datatypes(db, version, datatypes_xml)
      fill_resources_table(db, resources_xml)
    end

    def fill_datatypes(db, version, xml)
      datatypes = _db.dataset(db, :datatypes)
      (xml.xpath('//simpleType').to_a + xml.xpath('//complexType').to_a).each do |node|
        type = node[:name]
        next unless type
        datatypes.insert(
          kind: node.name,
          type: type,
          version: version,
          documentation: pg_array(node_text(node, './annotation/documentation')),
          extension: node_attr(node, './complexContent/extension/attribute', :type),
          restriction_base: node_attr(node, './restriction', :base)
        )

        fill_enums(db, node, type, version)
        fill_datatype_elements(db, node, type, version)
      end
    end

    def fill_datatype_elements(db, node, type, version)
      datatype_elements = _db.dataset(db, :datatype_elements)
      node.xpath('./complexContent/extension/sequence/element')
      .each_with_index do |enode, index|
        datatype_elements.insert(
          datatype: type,
          sequence: index,
          version: version,
          name: enode[:name] || enode[:ref],
          type: enode[:type],
          min_occurs: enode[:minOccurs],
          max_occurs: enode[:maxOccurs],
          documentation: node_text(enode, './annotation/documentation')
        )
      end
    end

    def fill_enums(db, node, type, version)
      datatype_enums = _db.dataset(db,:datatype_enums)
      node.xpath('./restriction/enumeration').each do |enode|
        datatype_enums.insert(
          datatype: type,
          version: version,
          value: enode[:value],
          documentation: node_text(enode, './annotation/documentation')
        )
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
      elements = db[:meta__elements]
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
