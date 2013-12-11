require 'spec_helper'
require 'uuid'

describe Fhir2relations::Facade do
  subject { described_class.new(DB) }

  def x
    Fhir2relations::Xml
  end

  before(:all) do
    subject.load_version('0.12')
  end

  def rfile(path)
    File.read(File.dirname(__FILE__) + "/#{path}")
  end

  example do
    subject.methods
  end
end
