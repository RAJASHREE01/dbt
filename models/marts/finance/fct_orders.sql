select 
    order_id,
    payment_id,
    amount / 100 as amount
from {{ref('stg_stripe__payments')}}