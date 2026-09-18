# AWS ECR module

Creates one ECR repository with company defaults that callers cannot turn off:

- Immutable image tags
- Scan on push
- AES-256 encryption
- Force-destroy disabled

Callers pass `name` and optional `tags`. There are no inputs for mutability, scanning, or deletion.
