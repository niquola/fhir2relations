require 'bundler'
require 'bundler/setup'

require 'sinatra'
require 'sinatra/reloader'
require 'fhir2relations'
require 'sequel'
require 'sinatra/partial'

Sequel.extension :pg_array_ops, :pg_row_ops
DB = Sequel.connect(ENV['SEQUEL'] || 'postgres:///fhirrelational')
DB.extension(:pg_array, :pg_row, :pg_hstore)

def sys
  Fhir2relations::Facade.new(DB)
end

def resources_repository
  sys.resources_repository
end

get '/' do
  @resources = resources_repository.resources(version: '0.12').sort_by{|r| r[:type]}
  haml :index
end

get '/resources/:resource' do |res|
  @resource = resources_repository
  .resource(version: '0.12', type: res, with_elements: true)

  haml :resource
end
