module AwsManager
  class FileReadError < RuntimeError; end
  class CloudFormationDiffError < RuntimeError; end
  class CloudFormationError < RuntimeError; end
  class YAMLLoadError < RuntimeError; end
end
