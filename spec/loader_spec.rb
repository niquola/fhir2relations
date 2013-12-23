require 'spec_helper'
require 'uuid'
require 'yaml'

describe 'Loader' do
  def subject
    @subject ||= Fhir2relations::Facade.new(DB)
  end

  def _res_rep
    Fhir2relations::ResourcesRepository
  end

  def _dt_rep
    Fhir2relations::DatatypesRepository
  end

  before(:all) do
    next
    subject.migrate!
    subject.load_version('0.12')
  end

  example do
    vss = subject.dataset(:versions)
    vss.where(version: '0.12').first[:version].should == '0.12'
  end

  describe "datatypes" do

    def datatypes_repo
      subject.datatypes_repository
    end

    example do
      add = datatypes_repo.complex_type(version: '0.12', type: 'Address')
      add.should_not be_nil
      add[:elements].should_not be_empty
      add[:kind].should == 'complexType'
      add[:elements].map{|h| h[:name]}.should == ["use", "text", "line", "city", "state", "zip", "country", "period"]
    end

    example do
      sched = datatypes_repo.complex_type(version: '0.12', type: 'Schedule').to_json
      sched.should_not be_nil
    end

    example do
      dts = datatypes_repo.complex_types(version: '0.12')
      dts.should_not be_empty
      dt = dts.last
      dt.key?(:documentation).should be_true
    end

    example do
      enms = datatypes_repo.enum_types(version: '0.12')
      enms.size.should == 13
      enms.each do |en|
        en[:enums].should_not be_empty
      end
    end

    example do
      ut = datatypes_repo.enum_type(version: '0.12', type: 'UnitsOfTime')
      ut[:enums].map{|e| e[:value]}.should =~ ["s", "min", "h", "d", "wk", "mo", "a"]
    end

    example do
      prims = datatypes_repo.primitive_types.map{|t| t[:type]}
      prims.should =~ ["integer", "dateTime", "code", "date", "decimal", "uri", "id", "base64Binary", "oid", "string", "boolean", "uuid", "instant"]
    end
  end

  describe "resources" do
    def resources_repo
      subject.resources_repository
    end

    example do
      enc = resources_repo.resource(with_elements: true, version: '0.12', type: 'Encounter')
      print_recurcive(enc)
    end

    def print_recurcive(el, ident = 0)
      return if el[:type] == ['Extension']
      puts '  ' * ident + '* ' + (el[:path] || []).last.to_s + " #{el[:type]}" + '  ' + el[:short].to_s
      (el[:elements] || []).each do |e|
        print_recurcive(e, ident + 1)
      end
    end

    example do
      enc = resources_repo.resources(version: '0.12', type: 'Encounter')
      enc.should_not be_nil
    end
  end
end
