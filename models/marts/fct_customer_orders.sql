with 

-- Import CTEs

customers as (

  select * from {{ source('jaffle_shop', 'customers') }}

),

orders as (

  select * from {{ source('jaffle_shop', 'orders') }}

),

payments as (

  select * from {{ source('jaffle_shop', 'payments') }}

),
-- Logical CTEs
-- Final CTE
-- Simple Select Statment
payments_summary as  (
        select 
            orderid as order_id,
            max(created) as payment_finalized_date,
            sum(amount) / 100.0 as total_amount_paid
        from payments
        where status <> 'fail'
        group by 1
    ),
paid_orders as (
    select orders.id as order_id,
        orders.user_id as customer_id,
        orders.order_date as order_placed_at,
        orders.status as order_status,
        payments_summary.total_amount_paid,
        payments_summary.payment_finalized_date,
        c.first_name as customer_first_name,
        c.last_name as customer_last_name
    from orders
    left join payments_summary on orders.id = p.order_id
    left join customers as c on orders.user_id = c.id ),

customer_orders as (
    select 
        c.id as customer_id
        , min(order_date) as first_order_date
        , max(order_date) as most_recent_order_date
        , count(orders.id) as number_of_orders
    from customers as c 
    left join orders on orders.user_id = c.id 
    group by 1
),

final as (

    select
        paid_orders.*,

        -- sequence of all transactions
        row_number() over (
            order by paid_orders.order_id
        ) as transaction_seq,

        -- sequence of orders for each customer
        row_number() over (
            partition by paid_orders.customer_id
            order by paid_orders.order_id
        ) as customer_sales_seq,

        case
            when customer_orders.first_order_date =
                 paid_orders.order_placed_at
            then 'new'
            else 'return'
        end as nvsr,

        -- running customer lifetime value
        sum(paid_orders.total_amount_paid)
            over (
                partition by paid_orders.customer_id
                order by paid_orders.order_id
            ) as customer_lifetime_value,

        customer_orders.first_order_date as fdos

    from paid_orders

    left join customer_orders
        using (customer_id)

)
select * from final