/**
 * Query Name: Deal ID,
 * Database: ISSDW,
 * Created By: yngcy,
 * Created On: 2018-10-08 07:20:32.0,
 * Updated On: 2018-12-09 09:25:46.0
**/
/* Write your queries in this editor and hit Run button or Shift + Return to execute */
SELECT
      date_part('y',ed.start_date) as activity_year
      , case when ed.marketplace_id in (1,7,771770) then 'NA'
           when ed.marketplace_id in (3,4,5,35691,44551) then 'EU'
            when ed.marketplace_id in (6) then 'JP'
           else null end as region
      , decode(ed.marketplace_id,1,'US',3,'UK',4,'DE',5,'FR',6,'JP',7,'CA',35691,'IT',44551,'ES',771770,'MX') as marketplace
      , ed.deal_id
      , ed.type as deal_type
      , case when ed.owner = 'EMU' then 'Automatically Picked' else 'Manually Picked' end as deal_channel
      , trunc(ed.start_date) as deal_start_day
      , ed.start_date as deal_start_datetime
      , ed.end_date as deal_end_day
      , dsl.merchant_customer_id
      , dsl.merchant_name
      , case when extract(year from dsl.launch_date) = extract(year from ed.start_date) then 'New' else 'Existing' end as all_ags
      
      , case when extract(year from dsl.launch_date) = extract(year from ed.start_date) then 
            (case when dsl.sales_center in ('CN Sales Center','CN SSR') then 'CN'
                  when dsl.sales_center in ('KR Sales Center','KR SSR') then 'KR'
                  when dsl.sales_center in ('SEAsia Sales Center','SEAsia SSR') then 'SEA'
                  when dsl.sales_center in ('US Sales Center','US SSR') then 'US'
                  when dsl.sales_center in ('UK Sales Center','DE Sales Center','EU SSR','EU Sales Center') then 'EU'
                  when dsl.sales_center in ('JP Sales Center', 'JP SSR') then 'JP'
                  when dsl.sales_center in ('IN Sales Center', 'IN SSR') then 'IN'
                  when dsl.sales_center in ('Domestic DS','Domestic SSR') then 'Domestic'
                  else 'Other OOC' end)
             when extract(year from dsl.launch_date) != extract(year from ed.start_date) then 
            (case when decode(dsl.marketplace_id,1,'US',3,'UK',4,'DE',5,'FR',6,'JP',7,'CA',35691,'IT',44551,'ES',771770,'MX') = 
                      (case when dsl.reporting_country in ('CN','HK','TW','MO') then 'CN'
                            when dsl.reporting_country in ('US','CA','MX') then dsl.reporting_country
                            when dsl.reporting_country in ('UK','DE','FR','IT','ES') then dsl.reporting_country
                            when dsl.reporting_country in ('GB') then 'UK' 
                            when dsl.reporting_country in ('JP') then dsl.reporting_country
                            when dsl.reporting_country in ('KR','KP') then 'KR'
                            when dsl.reporting_country in ('in') then dsl.reporting_country
                            when dsl.reporting_country in ('SG','TH','AU','NZ','ID','MY','VN','KH','PH') then 'SG'
                            else 'Other OOC' end) then 'Domestic' else  (case when dsl.reporting_country in ('CN','HK','TW','MO') then 'CN'
                                                                              when dsl.reporting_country in ('US','CA','MX') then dsl.reporting_country
                                                                              when dsl.reporting_country in ('UK','DE','FR','IT','ES') then dsl.reporting_country
                                                                              when dsl.reporting_country in ('GB') then 'UK' 
                                                                              when dsl.reporting_country in ('JP') then dsl.reporting_country
                                                                              when dsl.reporting_country in ('KR','KP') then 'KR'
                                                                              when dsl.reporting_country in ('in') then dsl.reporting_country
                                                                              when dsl.reporting_country in ('SG','TH','AU','NZ','ID','MY','VN','KH','PH') then 'SEA'
                                                                              else 'Other OOC' end) end) else NULL end as seller_origin

      , dsl.reporting_country
      
    /*  , case when extract(year from dsl.launch_date) = date_part('y',ed.start_date) then (case when dsl.merchant_type = 'Direct Sales' then 'DSR' else 'SSR' end)
             when extract(year from dsl.launch_date) < date_part('y',ed.start_date) then (case when sa.team is null then 'TBAM' else 'SAM' end)
             else null end as channel

      , case when extract(year from dsl.launch_date) = date_part('y',ed.start_date) then (case when dsl.merchant_type <> 'Direct Sales' and dsl.function is null then 'SSR' else dsl.function end)
             when extract(year from dsl.launch_date) < date_part('y',ed.start_date) then (case when sa.team is null then 'TBAM' else sa.subteam end)
             else null end as team */
             

      , case when extract(year from dsl.launch_date) < date_part('y',ed.start_date) then (case when sa.owner_alias is null then tb.owner_alias else sa.owner_alias end)
             when extract(year from dsl.launch_date) = date_part('y',ed.start_date) then dsl.opportunity_owner else null end as opportunity_owner
             
      , edi.item_id as asin
      , case when dma.gl_program_rollup = 'Hardlines'
             then (case when dma.product_group in (23,107,147,229,267,421,504,422) then 'CE' else 'Other Hardlines' end) 
             else dma.gl_program_rollup end as gl_rollup 
      , dma.gl_category_description as gl
      , doi.order_day
      , edi.item_quantity as deal_proposed_unit
      , sum(doi.order_quantity) as deal_soldout_unit
      , sum(doi.deal_ops*der.exchange_rate) as deal_ops_usd
  , sum(case when doi.deal_hit = 'Y' then doi.deal_ops*der.exchange_rate end) as deal_hit_ops_usd

      
  from  goldbox_ddl.e_deal ed

      inner join goldbox_ddl.e_deal_item edi 
      on ed.marketplace_id = edi.marketplace_id
      and ed.deal_id = edi.deal_id

      left join goldbox_ddl.e_deal_customer_order_items doi
      on doi.marketplace_id = ed.marketplace_id
      and doi.deal_id = ed.deal_id 
      and doi.asin = edi.item_id
      and doi.is_deal_order = 'Y'
      and doi.is_retail_order_item = 'N'

      inner join iss_dimension.d_seller_launches dsl
      on edi.merchant_id = dsl.merchant_customer_id
      and edi.marketplace_id = dsl.marketplace_id

      inner join iss_dimension.d_mp_asins dma 
      on edi.marketplace_id = dma.marketplace_id
      and edi.item_id = dma.asin

      left join isscn.seller_am_mapping sa
      on sa.region_id = dsl.region_id
      and sa.merchant_customer_id = dsl.merchant_customer_id
  
      left join isscn.tbam_b2b_launches tb
      on dsl.marketplace_id = tb.marketplace_id
      and dsl.merchant_customer_id = tb.merchant_customer_id

      left join iss_dimension.d_exchange_rates der
      on der.marketplace_id = doi.marketplace_id
      and der.is_current = 'Y'
      and der.rate_period = 'OP2'

  WHERE 
        ed.marketplace_id in (1)
        and ed.is_valid = 'Y'
        and ed.start_date >= '20180101'
        and dsl.merchant_customer_id in (48795929902)
and edi.item_id in ('B07NW38NBS')

  GROUP BY
  1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20

