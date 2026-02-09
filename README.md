# Ceph RGW Write-Restriction Hook

This Lua script provides a mechanism to prevent write operations on specific Ceph RGW buckets for the non admin users.

## Configuration

Modify these variables at the top of the script to fit your environment:

| Variable | Description | Default |
| --- | --- | --- |
| `ADMIN_USER_ID` | The User ID that is exempt from the lock. | `adminid` |
| `LOCK_TAG_KEY` | The key of the bucket tag used to trigger the lock. | `write-lock` |
| `LOCK_TAG_VALUE` | The value the tag must have to activate the lock. | `true` |


## Installation & Deployment

Enable the script using:
radosgw-admin script put --infile=restrict_write.lua --context=prerequest



## Usage: Locking a Bucket

To "lock" a bucket, simply add the configured tag to the bucket.

