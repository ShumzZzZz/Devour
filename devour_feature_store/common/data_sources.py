from feast import FileSource, PushSource, RequestSource
from feast.infra.offline_stores.contrib.spark_offline_store.spark_source import SparkSource

from feast.data_format import ParquetFormat

ds_file_product_general_score = FileSource(
    name="ds_file_product_general_score",
    path="data/product_features/product_general_scores.parquet",
    file_format=ParquetFormat(),
    timestamp_field="event_timestamp",
)

ds_push_product_general_score = PushSource(
    name="ds_push_product_general_score",
    batch_source=ds_file_product_general_score
)

