require 'spec_helper'
require 'uuid'

describe Fhir2relations::Loader do
  subject { described_class }

  def _db
    Fhir2relations::Db
  end

  def _res_rep
    Fhir2relations::ResourcesRepository
  end

  def _dt_rep
    Fhir2relations::DatatypesRepository
  end

  before(:all) do
    next
    DB.execute(
      File.read(
        File.dirname(__FILE__) + '/../db/migrations/20131121_schema.sql'))

    described_class.load_version(DB, '0.12')
  end

  def rfile(path)
    File.read(File.dirname(__FILE__) + "/#{path}")
  end

  example do
    vss = _db.dataset(DB, :versions)
    vss.where(version: '0.12').first[:version].should == '0.12'
  end

  example do
    dts = _db.dataset(DB, :datatypes)

    add = dts.where(type: 'Address').first
    add.should_not be_nil
    add[:kind].should == 'complexType'

    dtes = _db.dataset(DB, :datatype_elements)
    a_dtes = dtes.where(datatype: 'Address').order(:sequence)
    a_dtes.all.map{|h| h[:name]}.should == ["use", "text", "line", "city", "state", "zip", "country", "period"]
  end

  example do
    add = _dt_rep.complex_type_by_name(DB, '0.12', 'Address')
    add.should_not be_nil
  end

  example do
    _dt_rep.complex_type_by_name(DB, '0.12', 'Schedule')
    .should_not be_nil
  end

  example do
    dts = _dt_rep.datatypes(DB, '0.12')
    dts.should_not be_empty
    dt = dts.last
    dt.should respond_to(:documentation)
  end

  example do
    _db.dataset(DB, :enums).all.should_not be_empty
  end

  example do
    _db.dataset(DB, :primitives).all.should_not be_empty
  end

  example do
    enc = _res_rep.find_by_name(DB, '0.12', 'Encounter')
    enc.should_not be_nil
  end
end
