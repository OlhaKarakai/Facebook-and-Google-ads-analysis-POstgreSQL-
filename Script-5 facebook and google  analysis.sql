with facebook_google_details as(
with facebook_details  as (
select * from facebook_ads_basic_daily fabd),

facebook_adset_details as (
select * from facebook_adset),

facebook_campaign_details as (
select * from 
facebook_campaign fc ),

google_details as (
select * from google_ads_basic_daily gabd)

select ad_date, 
url_parameters,
coalesce (spend,0) spend, 
coalesce (impressions,0) impressions, 
coalesce(reach,0) reach, 
coalesce (clicks,0) clicks,
coalesce (leads,0) leads,
coalesce (value,0) value
from facebook_details fd
left join facebook_adset_details fad on fad.adset_id=fd.adset_id
left join facebook_campaign fc on fc.campaign_id=fd.campaign_id

union 

select ad_date, 
url_parameters,
coalesce (spend,0) spend, 
coalesce (impressions,0) impressions, 
coalesce(reach,0) reach, 
coalesce (clicks,0) clicks,
coalesce (leads,0) leads,
coalesce (value,0) value
from google_details)

select ad_date, 
decode_url_part(case 
	when lower(substring(url_parameters, 'utm_campaign=([^&#$]+)')) = 'nan'
	then null
else lower(substring(url_parameters, 'utm_campaign=([^&#$]+)'))
end) utm_campaign,
sum(spend),
sum(impressions),
sum(clicks),
sum(value),
case 
	when sum (impressions)<>0 then sum(clicks::float)/sum(impressions::float)
end as CTR,
case 
	when sum(clicks)<>0 then sum (spend::float)/sum(clicks::float)
end as CPC,
case 
	when sum(impressions)<>0 then sum(spend::float)*1000/sum(impressions::float)
	end as CPM,
case 
	when sum(spend)<>0 then (sum(value)-sum(spend))/sum(spend::float)
end as ROMI
from facebook_google_details
group by ad_date, utm_campaign
order by ad_date;


--decoding function
CREATE OR REPLACE FUNCTION pg_temp.decode_url_part(p varchar) RETURNS varchar AS $$
SELECT convert_from(CAST(E'\\x' || string_agg(CASE WHEN length(r.m[1]) = 1 THEN encode(convert_to(r.m[1], 'SQL_ASCII'), 'hex') ELSE substring(r.m[1] from 2 for 2) END, '') AS bytea), 'UTF8')
FROM regexp_matches($1, '%[0-9a-f][0-9a-f]|.', 'gi') AS r(m);
$$ LANGUAGE SQL IMMUTABLE STRICT;




