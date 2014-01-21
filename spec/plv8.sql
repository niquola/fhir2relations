--db:fhirr
--{{{
--CREATE EXTENSION plv8;
drop FUNCTION plv8_init();
CREATE OR REPLACE FUNCTION plv8_init() RETURNS
text AS $$
return 'ok';
$$ LANGUAGE plv8 IMMUTABLE STRICT;

SET plv8.start_proc = 'plv8_init';

drop FUNCTION do_it();
CREATE OR REPLACE FUNCTION do_it() RETURNS
text AS $$
str = JSON.stringify;
log = function(mess){
  plv8.elog(INFO, str(mess));
};

iterateSql = function (sql, cb){
  var plan = plv8.prepare(sql);
  var rows = plan.execute();
  res = rows.map(cb)
  plan.free();
  return res;
}
plv8.execute('drop schema if exists  fhir cascade')
plv8.execute('drop extension  "uuid-ossp"')
plv8.execute('create extension  "uuid-ossp"')
plv8.execute('create schema  fhir')

iterateSql("select * from meta.resources", function(res){
  var fields = iterateSql("select * from meta.resource_elements where array_length(path, 1) = 2 and resource = '" + res.type +  "'", function(e){
    return e.path[e.path.length -1] + ' varchar'
  }).join(',')
  log("create table fhir." + res.type + "( uuid uuid PRIMARY KEY, " + fields + ")");
  });

return 'ok';
$$ LANGUAGE plv8 IMMUTABLE STRICT;

\timing

SELECT do_it();
--}}}

--{{{
\d meta.resource_elements
\d fhir.*
--}}}
