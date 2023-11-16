# Draft - this is still WIP

# Example - Building a VM image in GCP using packer

Here are some example template snippets used to spin up Google Cloud resources
to build a VM image using packer in a private network environment.

Please note that these are provided only as examples to help guide
infrastructure planning and are not intended for use in production. They are
deliberately simplified for clarity and lack significant details required for
production-worthy infrastructure implementation.

In this example, you'll create:
- a builder service account with permissions needed to build VM images in
  Google Cloud
- A build controller node to drive the packer build process.  Packer will spin
  up builders as necessary to build VM images

Note that unlike other methods of running packer on GCP, this works with private
networks that don't allow ingress.  The build controller acts as a packer client
and will use packer's standard ssh communicator throughout the build process.
The enables ansible provisioners to work as expected as well.


## Costs

If you run the example commands below, you will use billable components of
Google Cloud Platform, including:

- Compute Engine

as well as a selection of other services.

You can use the
[Pricing Calculator](https://cloud.google.com/products/calculator)
to generate a cost estimate based on your projected usage.

Check out the [Google Cloud Free
Program](https://cloud.google.com/free/docs/gcp-free-tier) for potential
credits for tutorial resources.

## Before you begin

Start by opening the accompanying tutorial
[example compute cluster](example-compute-cluster.md)
and following the "setup" and "networking" steps.

Then open a Cloud Shell associated with the project you're using

[Launch Cloud Shell](https://console.cloud.google.com/?cloudshell=true)

It's important that the current Cloud Shell project is the one you're using
for the tutorial. Verify that

```bash
echo $GOOGLE_CLOUD_PROJECT
```

shows that project.

All example commands below run from this Cloud Shell.


## Tools

We use [Terraform](terraform.io) and [Packer](packer.io) for these examples and
the latest version of Terraform is already installed in your GCP Cloudshell.


## Find the builder service account and CMEK if used

We created a Service Account to use for the builder in the previous "setup" step.
Also a Customer-Managed Encryption Key (CMEK) if you chose to do so.  We need to
get the names of these to use for the builder.

```bash
cd terraform/setup
terraform output
```

The output of this command will display links for the Service Account and CMEK.
We'll need those in later steps.


## Create a build controller

Create a single static node to use as a build controller for this example.

Change to the build controller example directory

```bash
cd terraform/build-controller
```

Copy over the template variables

```bash
cp build-controller.tfvars.example build-controller.tfvars
```

Edit `build-controller.tfvars` to set some missing variables.

You need to edit several fields:


### Edit the CMEK used to encrypt disks and storage

Uncomment
```terraform
# cmek_self_link = "projects/<project>/locations/global/keyRings/tutorial-keyring/cryptoKeys/tutorial-cmek"
```
and set this variable to the value output from the setup step above.


### Edit Service Account used for the build controller

Uncomment the following variables throughout the file
```terraform
# service_account = "<my_service_account_email>"
```
and set the value of each to the builder service account value output from the
setup step above.


### Spin up the build controller

Next spin up the build controller..
Still within the `build-controller` example directory above, run

```bash
terraform init
terraform plan -var-file build-controller.tfvars
terraform apply -var-file build-controller.tfvars
```

and wait for the resources to be created.  This should only take a minute or two.


## Test that you can log into the build controller

Verify you can access the build controller
```
gcloud compute ssh build-controller --zone <my_zone>
```


## Copy packer config over to the build controller

Once the build controller is up, you'll need to copy your packer config over.

You can do this a number of different ways: scp the packer config from cloudshell, use a bucket
to transfer the packer config, or 

### (suggested) clone the packer config directly on the build controller

From the build controller:
```
git clone https://github.com/mmm/gcp-standalone-partition
cd gcp-standalone-partition/packer
```


## Use packer to build a VM image

Now, from the build controller, run packer:
```
packer build compute-image.pkr.hcl -var-file compute-image.pkrvars
```


## Cleaning up

To avoid incurring charges to your Google Cloud Platform account for the
resources used in this tutorial:

### Delete the project using the GCP Cloud Console

The easiest way to clean up all of the resources used in this tutorial is
to delete the project that you initially created for the tutorial.

Caution: Deleting a project has the following effects:
- Everything in the project is deleted. If you used an existing project for
  this tutorial, when you delete it, you also delete any other work you've done
  in the project.
- Custom project IDs are lost. When you created this project, you might have
  created a custom project ID that you want to use in the future. To preserve
  the URLs that use the project ID, such as an appspot.com URL, delete selected
  resources inside the project instead of deleting the whole project.

1. In the GCP Console, go to the Projects page.

    [GO TO THE PROJECTS PAGE](https://console.cloud.google.com/cloud-resource-manager)

2. In the project list, select the project you want to delete and click Delete
   delete.
3. In the dialog, type the project ID, and then click Shut down to delete the
   project.

### Deleting resources using Terraform

Alternatively, if you added the tutorial resources to an _existing_ project, you
can still clean up those resources using Terraform.

From the `compute-partition` sub-directory, run

```sh
terraform destroy
cd ../storage
terraform destroy
cd ../network
terraform destroy
```

...and then optionally,
```sh
cd ../setup
terraform destroy
```
to clean up the rest.

## What's next

There are so many exciting directions to take to learn more about what you've
done here!

- Infrastructure.  Learn more about
  [Cloud](https://cloud.google.com/),
  High Performance Computing (HPC) on GCP
  [reference architectures](https://cloud.google.com/solutions/hpc/) and 
  [posts](https://cloud.google.com/blog/topics/hpc).

