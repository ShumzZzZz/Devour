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

product_general_score_fv = FeatureView(
	name="product_general_score",
	entities=[product],
	# ttl=timedelta(days=30),
	schema=[
		Field(name="product_id", dtype=Int64),
		Field(name="general_score", dtype=Float32),
		Field(name="event_timestamp", dtype=String),
	],
	source=product_general_score_source
)
