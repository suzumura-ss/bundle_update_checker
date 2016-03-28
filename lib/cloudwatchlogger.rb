require 'aws-sdk'


class CloudWatchLogger
  attr_accessor :region, :log_group_name, :log_stream_name

  def initialize(region:nil, log_group_name:nil, log_stream_name:nil)
    @region = region
    @log_group_name = log_group_name
    @log_stream_name = log_stream_name
  end

  def put_log(message)
    @client ||= Aws::CloudWatchLogs::Client.new({
      region:     @region,
      http_proxy: ENV['HTTPS_PROXY']||ENV['HTTP_PROXY']
    })
    param = {
      log_group_name:  @log_group_name,
      log_stream_name: @log_stream_name,
      log_events:[{
        timestamp: (Time.now.to_f*1000).to_i,
        message:   message
      }]
    }
    param.merge!(sequence_token:@next_sequence_token) if @next_sequence_token
    begin
      res = @client.put_log_events(param)
    rescue Aws::CloudWatchLogs::Errors::ResourceNotFoundException=>e
      @client.create_log_stream(log_group_name:@log_group_name, log_stream_name:@log_stream_name)
      retry
    rescue Aws::CloudWatchLogs::Errors::InvalidSequenceTokenException=>e
      seq = e.to_s.scan(/\d{48,}/)[0]
      param.merge!(sequence_token:seq)
      retry
    end
    @next_sequence_token = res.next_sequence_token
  end
end
