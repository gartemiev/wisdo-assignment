# Wisdo assignment
This repo contains Terraform code for infra provisioning and CI/CD pipelines for infra deployment and microservices deployment 
via GitHub actions. 

Note: environment segregation is not covered for this POC to safe time and considering that it is just POC.
Also note: assumption is that both backend services should access to MongoDB atlas and both of them communicate between via SQS.
For microservice CI/CD: this should be created for each app repo separately. Of course logic may differ in terms of build/other requirements.
This is just a general POC.