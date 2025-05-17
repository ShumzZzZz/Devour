from datetime import timedelta

import pandas as pd
from feast import (
	FeatureView,
	Field,
)
from feast.types import Float32, Int64, String
from feast.on_demand_feature_view import on_demand_feature_view

from common.data_sources import *
from common.entities import *

fv_product_general_score = FeatureView(
	name="fv_product_general_score",
	entities=[et_product],
	ttl=timedelta(days=365),
	schema=[
		Field(name="product_id", dtype=Int64),
		Field(name="general_score", dtype=Float32),
	],
	source=ds_file_product_general_score
)

fv_push_product_general_score = FeatureView(
	name="fv_push_product_general_score",
	entities=[et_product],
	ttl=timedelta(days=365),
	schema=[
		Field(name="product_id", dtype=Int64),
		Field(name="general_score", dtype=Float32),
	],
	online=True,
	offline=True,
	source=ds_push_product_general_score
	# has to be push source, otherwise the push source will not be registered and found
)
