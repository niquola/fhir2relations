require 'spec_helper'
require 'uuid'

describe Fhir2relations::Loader do
  subject { described_class }

  around(:each) do |example|
    DB.transaction do # BEGIN
      DB.execute(
        File.read(
          File.dirname(__FILE__) + '/../db/migrations/20131121_schema.sql'))

      dt_xml = subject.xml('0.12/fhir-base.xsd')
      xml = subject.xml('0.12/profiles-resources.xml')
      subject.load(DB, '0.12', dt_xml, xml)

      example.run
      raise Sequel::Rollback
    end
  end

  def rfile(path)
    File.read(File.dirname(__FILE__) + "/#{path}")
  end

  example do
    vss = subject.dataset(DB, :versions)
    vss.where(version: '0.12').first[:version].should == '0.12'
  end

  example do
    dts = subject.dataset(DB, :datatypes)

    add = dts.where(type: 'Address').first
    add.should_not be_nil
    add[:kind].should == 'complexType'

    dtes = subject.dataset(DB, :datatype_elements)
    a_dtes = dtes.where(datatype: 'Address').order(:sequence)
    a_dtes.all.map{|h| h[:name]}.should == ["use", "text", "line", "city", "state", "zip", "country", "period"]
  end

  example do
    cts = subject.dataset(DB, :complex_types)
    names = cts.all.map{|h| h[:type]}
    names.should include('Address')
    names.should include('Schedule')
  end

  example do
    subject.dataset(DB, :complex_types).all.should_not be_empty
  end

  example do
    subject.dataset(DB, :enums).all.should_not be_empty
  end

  example do
    subject.dataset(DB, :primitives).all.should_not be_empty
  end
end
