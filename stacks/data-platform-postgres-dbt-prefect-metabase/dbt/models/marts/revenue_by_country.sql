select
    country,
    count(*) as orders,
    sum(quantity) as units,
    sum(amount) as revenue
from {{ ref('stg_orders') }}
group by country
