select 
sum(amount) as total_amount
from {{ ref('stg_stripe__payments') }}
where payment_status='success'