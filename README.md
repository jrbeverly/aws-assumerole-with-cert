# AWS AssumeRole with Certificate for CI

Exploring the concept of using AWS IoT Certificates for authenticating with AWS.

This came up while working with minio, which supports authentication with certificates:

> MinIO provides a custom STS API that allows authentication with client X.509 / TLS certificates.

## Getting Started

The commands `boostrap.sh` and `cert.sh` are provided for working with the IoT devices. Bootstrap is responsible for provisioning the certificate, IoT resources, and the permissionless IAM role. Assuming that AWS credentials are configured, a test can be started by running the following:

```bash
bash scripts/bootstrap.sh github-my-repository-name
```

This will create the following resources:

- An IAM Role with a trust policy for IoT credentials
- An IoT Thing & ThingType
- An IoT Certificate
- An IoT Role Alias, Policy & associations with the ceritifcate & thing

The output of this command will be located in the `output` directory under the name provided above (e.g. `github-my-repository-name`). This will contain the certificate, private/public keys and `auth.yaml`. The `auth.yaml` file is intended to work similar to a kubeconfig file, allowing the command `get-aws-credentials.bash` to retrieve credentials from AWS over HTTPS.

This can be done by then running:

```bash
bash scripts/get-aws-credentials.bash github-my-repository-name
```

## Notes

This has some potential. Rather than leveraging Terraform, I wanted to use an API oriented approach to this, as that is likely how the certificates + associated components would be provisioned. They would be created by an `operator`-like service that identifies repositories that are requesting authentication to the artifact publishing services. The credentials would be populated into the Continuous Integration/Delivery platform (like GitHub Actions), with rotation and revocation happening base on how the operator is interacted with.

It may be possible with this model to support using the "generic" S3 API for publishing, rather than relying on the AWS CLI. This wouldn't decoupled the CI/CD system from AWS credentials & publishing, but it does create a case where we are no longer relying on `AWS_*` environment variables, but instead on things like X.509 certificates, and standard-based publishers (e.g. `minio - mc`)
