from datetime import timedelta

import pandas as pd

from feast import (
    Entity,
    ValueType
)

user = Entity(
    name="user",
    join_keys=["user_id"],
    value_type=ValueType.INT64,
    description="User ID"
)
product = Entity(
    name="product",
    join_keys=["product_id"],
    value_type=ValueType.INT64,
    description="Product ID"
)
