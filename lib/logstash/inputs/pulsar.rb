require 'logstash/namespace'
require 'logstash/inputs/base'
require 'stud/interval'
require 'java'
require 'logstash-input-pulsar_jars'

class LogStash::Inputs::Pulsar < LogStash::Inputs::Base
  config_name "pulsar"

  default :codec, 'plain'

  config :service_url, :validate => :string
  config :topics, :validate => :array, :default => ["logstash"]
  config :topics_pattern, :validate => :string
  config :group_id, :validate => :string, :default => "logstash-group"
  config :client_id, :validate => :string, :default => "logstash-client"
  config :consumer_threads, :validate => :number, :default => 1
  config :decorate_events, :validate => :boolean, :default => false


  public
  def register
    @runner_threads = []
  end # def register

  public
  def run(logstash_queue)
    @runner_consumers = consumer_threads.times.map { |i| create_consumer("#{client_id}-#{i}") }
    @runner_threads = @runner_consumers.map { |consumer| thread_runner(logstash_queue, consumer) }
    @runner_threads.each { |t| t.join }
  end # def run

  # logstash 关闭回调
  public
  def stop
    logger.info("Stop pulsar input !!!")
    @runner_consumers.each { |c| c.close }
  end

  public
  def pulsar_consumers
    @runner_consumers
  end # 这个是什么用

  private
  def create_consumer(client_id)
    begin
      logger.info("client - ", :client => client_id)
      clientBuilder = org.apache.pulsar.client.api.PulsarClient.builder()
      clientBuilder.serviceUrl(@service_url)
      client = clientBuilder.build
      logger.info("topic:",:topic => @topics.to_java('java.lang.String'))
      subscriptionType = org.apache.pulsar.client.api.SubscriptionType
      consumer = client.newConsumer.clone.topic(@topics.to_java('java.lang.String'))
        .subscriptionName(@group_id)
        .consumerName(client_id)
        .subscriptionType(subscriptionType::Shared)
        .subscribe();
    rescue => e
      logger.error("Unable to create pulsar consumer from given configuration",
                   :pulsar_error_message => e,
                   :cause => e.respond_to?(:getCause) ? e.getCause() : nil)
      throw e
    end
  end

  private
  def thread_runner(logstash_queue, consumer)
    Thread.new do
      begin
        while !stop?
          record = consumer.receive;
          @codec.decode(record.getValue.to_s) do |event|
            decorate(event)
            if @decorate_events
              event.set("[pulsar][topic]", record.getTopicName)
              event.set("[pulsar][offset]", record.getMessageId)
              event.set("[pulsar][key]", record.getKey)
            end
            logstash_queue << event
          end
        end
      rescue => e
        logger.error("exit - ",:cause => e.respond_to?(:getCause) ? e.getCause() : nil)
        consumer.close
      end
    end
  end

end