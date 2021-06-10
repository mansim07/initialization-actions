# Teradata Connector for Hadoop Initialization Action

This initialization action installs [TDCH]() on a [Google Cloud Dataproc](https://cloud.google.com/dataproc) cluster. The script will also install the connector on all or specific nodes of the cluster depending on the Dataproc version.

## Using this initialization action

**:warning: NOTICE:** See [best practices](/README.md#how-initialization-actions-are-used) of using initialization actions in production.

Check the variables set in the script to ensure they're to your liking.

Please follow the blogpost here for the detailed instruction
https://medium.com/@maharanam/enabling-teradata-connector-for-hadoop-tdch-on-google-cloud-dataproc-cluster-8278017237ec