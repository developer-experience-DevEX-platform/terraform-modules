# AWS S3 module

Creates one private S3 bucket with company defaults that callers cannot turn off:

- Versioning enabled
- AES-256 encryption
- All public access blocked
- Bucket owner enforced
- Force-destroy disabled

Callers pass `name` and optional `tags`. There are no inputs for encryption, versioning, or public access.
