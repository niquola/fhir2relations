--db:fhir2relations
--{{{
drop schema if exists meta cascade;
create schema meta;

create table meta.versions (
  version varchar,
  documentation text,
  PRIMARY KEY(version)
);
create table meta.datatypes (
  version varchar references meta.versions(version),
  type varchar,
  kind varchar,
  extension varchar,
  restriction_base varchar,
  documentation text[],
  PRIMARY KEY(type)
);

create table meta.datatype_elements (
  version varchar,
  sequence integer,
  datatype varchar references meta.datatypes(type),
  name varchar,
  type varchar,
  min_occurs integer,
  max_occurs varchar,
  documentation text,
  PRIMARY KEY(datatype, name)
);

create table meta.datatype_enums (
  version varchar,
  datatype varchar references meta.datatypes(type),
  value varchar,
  documentation text,
  PRIMARY KEY(datatype, value)
);

create table meta.resources (
  version varchar,
  type varchar,
  publish boolean,
  PRIMARY KEY(type)
);

create table meta.elements (
  version varchar,
  path varchar[],
  is_modifier boolean,
  min integer,
  max varchar,
  resource varchar references meta.resources(type),
  synonym varchar[],
  type varchar[],
  short text,
  formal text,
  mapping_target varchar,
  mapping_map varchar,
  PRIMARY KEY(path)
);

create view meta.complex_types as (
  select dt.type
  ,dt.version
  ,count(*) as num_attrs
  ,array_agg(de.name) as attrs
  from meta.datatypes dt
  join meta.datatype_elements de on de.datatype = dt.type
  group by dt.type, dt.version
  order by type
);

create view meta.enums as (
  select type
  , dt.version
  ,count(*) as num_options
  ,array_agg(value) as options
  from meta.datatypes dt
  join meta.datatype_enums de on de.datatype = dt.type
  group by type, dt.version
);

create view meta.primitives as (
  select type, version
  from meta.datatypes
  where
  type not in (select distinct(datatype) from meta.datatype_enums)
  and type not in (select distinct(datatype) from meta.datatype_elements)
  and extension not in (select distinct(datatype) from meta.datatype_enums)
);
--}}}
