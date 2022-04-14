create
or replace view locations_neighborhoods as
select
  locations.id as location_id,
  toronto_neighborhoods.id as neighborhood_id
from
  locations
  left join toronto_neighborhoods on st_covers(toronto_neighborhoods.geog, locations.coords)