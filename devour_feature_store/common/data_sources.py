from feast import (
    FileSource,
    PushSource,
    RequestSource,
)

from feast import ValueType
from feast.data_format import ParquetFormat

product_general_score_source = FileSource(
    name="product_general_score_source",
    path="/Users/shuminzheng/PycharmProjects/devour/devour_feature_store/data/product_features/",
    file_format=ParquetFormat(),
    timestamp_field="event_timestamp",
)
