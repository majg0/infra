# AWS Infra

👋 Hi! I have abandoned this project, as I found during my exploration that AWS is billing for simple resources like VPCs even in the free tier.
The design I was aiming for was a minimal, secure, always-up cloud env - but as I don't need the resources, I don't see a point in paying for them.
In conclusion, I would say AWS is powerful but costly, both in terms of price tag and vendor lock-in.
It will likely only make sense to use AWS professionally for a mid- to large-size company.
Smaller ventures will likely want to run on-prem.

---

General purpose AWS (Amazon Web Services) infrastructure setup for scalable and secure cloud applications.

## Bootstrapping

For a guide on configuring AWS for use with this repository's GitHub Actions workflows and leveraging Terraform for infrastructure as code, see [docs/aws-setup.md](docs/aws-setup.md).
