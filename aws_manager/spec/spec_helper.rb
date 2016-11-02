require 'simplecov'
require 'simplecov-rcov'

require_relative '../lib/aws_manager/util/file_reader'
require_relative '../lib/aws_manager/util/cf_differ'
require_relative '../lib/aws_manager/util/yaml_loader'
require_relative '../lib/aws_manager/util/backup'
require_relative '../lib/aws_manager/auto_scaling'
require_relative '../lib/aws_manager/aws_ops'
require_relative '../lib/aws_manager/cloud_formation_ops'
require_relative '../lib/aws_manager/cloud_formation'
require_relative '../lib/aws_manager/ec2'
require_relative '../lib/aws_manager/route53'
require_relative '../lib/aws_manager/cli/application'

SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::RcovFormatter
]
SimpleCov.start do
  add_filter '/spec/'
end

def capture(stream)
  begin
    stream = stream.to_s
    eval "$#{stream} = StringIO.new"
    yield
    result = eval("$#{stream}").string
  ensure
    eval("$#{stream} = #{stream.upcase}")
  end
  result
end