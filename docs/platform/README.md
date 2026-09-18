# Platform composition

`platform/` modules are what a service stack calls. They name the
service, trust GitHub OIDC, write repository variables, and compose
`aws` primitives with a relative path.

Application developers do not call these. Backstage and
`platform-infrastructure` do.

| Module | Status | What it provisions |
| --- | --- | --- |
| [Container release](service-container-release.md) | Available | ECR, `*-github-release` role, GitHub variables, production environment |
| [Lambda service](service-lambda.md) | Exists | Artifact prefix IAM, staging function, release and deploy roles |

```text
Backstage
    ↓
service repository
    ↓
infrastructure pull request
    ↓
Terraform applies a platform module
    ↓
GitHub variables exist
    ↓
ci-cd-templates release workflow can run
```

Stacks pin a git tag. Relative `source = "../../aws/..."` is only
inside this repository.

Lambda CD in `ci-cd-templates` is not reviewed yet. Prefer container
release for a new golden-path service.
