# update_aws
The update_aws file provides a nice GUI command tool for working with AWS Cloudformation stacks.  It requires that aws_manager be installed (credit to Cake Solutions for the aws_manager). It is a WIP and still heavily tailored for my own personal use.  I will get around to generalizing it once I find the time. Lastly, yes...there are many other languages better suited for this sort of GUI, but hey..I like bash. :)

# aws_manager
`aws_manager` is a toolkit (Ruby gem for the CLI) for interacting with AWS resources using the Ruby AWS SDK.

## Installation

Make sure that you use ruby version >= `2.1.0`. Currently, you would need to checkout the repository locally and then build the gem. Once you have the `.gem` file, you can then install it.

### Build

From the root of the project run;
```shell
$ gem build aws_manager.gemspec
```

This would download all gem dependencies and would then bundle the gem.

### Install

Now, you have `aws_manager.{VERSION}.gem` in the root of the project. To install run;

```shell
$ gem install ./aws_manager-0.3.2.gem
```

And then, to verify installation execute:

```shell
$ aws_manager help
```

That should display the help message of the gem.

## Structure
* hiera.yaml : The backend, datadir, and hierarchy rules

```yaml
---
:backends:
  - yaml
:yaml:
  :datadir: ./inventory
:hierarchy:
  - "%{Environment}-%{Region}-%{Project}"
  - "%{Environment}"
  - "%{Region}"
  - common

```
* scope_file.yaml : Yaml file contains the parameters for which hiera to lookup values from.

* CloudFormation templates : Json files that describe AWS resources grouped by AWS stacks
* inventory yaml files : Yaml files contains parameters values for different CloudFormation templates

## Usage
```shell
$ aws_manager help
```

To create a stack
```
$ aws_manager cf-create-stack --cfn-template path_to_cloudformation_templates/environment_customer_project_component.json --scope path_to_scope.yaml --hiera_conf /path/to/hiera.yaml
```

To list stacks with default status CREATE_COMPLETE
```shell
$ aws_manager cf-list-stacks
```

To list stacks with non-default status
```shell
$ aws_manager cf-list-stacks --stack_status_codes="CREATE_COMPLETE" "UPDATE_COMPLETE"
```

To validate a stack template
```shell
$ aws_manager cf-validate-stack --cfn-template path_to_cloudformation_templates/environment_customer_project_component.json
```

To delete a stack
```shell
$ aws_manager cf-delete-stack --cfn-template path_to_cloudformation_templates/environment_customer_project_component.json --scope path_to_scope.yaml --hiera_conf /path/to/hiera.yaml
```

To structurally update a stack (both template and parameters)
```shell
$ aws_manager cf-update-stack --stack_name environemnt-customer-project-component --cfn-template path_to_cloudformation_templates/environment_customer_project_component.json --scope path_to_scope.yaml --hiera_conf /path/to/hiera.yaml
```

To update a stack's parameters:
```shell
$ aws_manager cf-update-stack-parameters --stack_name environemnt-customer-project-component --scope path_to_scope.yaml
```

To create a route53 record
```shell
$ aws_manager route53-create-record --domain-name mydomain.io --hosted-zone-id Z3FGDDG45DBO --interface etho --record-name microservice
```

To attach a volume to an instance
```shell
$ aws_manager ec2-attach-volume --device /dev/xvdx --instance-id i-wlfaodha --volume-id vol-sdadwafs
```
To describe the CloudFormation stack outputs for a VPC
```shell
$ aws_manager describe-stack-outputs --stack-name=vpc-stack-name
```

To capture CloudFormation stack outputs into a YAML file
```shell
$ aws_manager capture-stack-outputs --stack-name=some-stack-name --yaml-file-path=/path/to/file.yml --items_to_extract=key
```

To upload to an S3 bucket
```shell
$ aws_manager s3-upload -f my_file.json -b my-s3-bucket -p path/in/bucket/to/file/
```
Creates: `my-s3-bucket/path/in/bucket/to/file/my_file.json`

To check your reserved instance usage
```shell
$ aws_manager check-reserved --instance-types=t2.micro,t2.medium --aws_region=eu-west-1
```
By default specifying no instance types checks all reserved and running instance types.

To cleanup Route53 record sets
```shell
$ aws_manager route53-cleanup --hosted-zone-name=<HOSTED_ZONE_NAME>
```

## Testing
```shell
cd /path/to/aws_manager
rspec .
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/aws_manager/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
