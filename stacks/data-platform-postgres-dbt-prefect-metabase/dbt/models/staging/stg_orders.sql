select
    id as order_id,
    cast(ordered_at as date) as ordered_at,
    country,
    product,
    quantity,
    cast(amount as numeric(10, 2)) as amount
from {{ ref('orders') }}
