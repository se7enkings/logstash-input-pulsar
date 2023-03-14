require 'logstash/namespace'
require 'logstash/inputs/base'
require 'stud/interval'
require 'java'
require 'logstash-input-pulsar_jars'

class LogStash::Inputs::Pulsar < LogStash::Inputs::Base
  config_name "pulsar"

  default :codec, 'plain'

  config :service_url, :validate => :string, :required => true
  config :auth_plugin_class_name, :validate => :string
  config :auth_params, :validate => :password

  config :topics, :validate => :array, :default => ["topic-1"]
  config :topics_pattern, :validate => :string

  config :subscription_name, :validate => :string, :default => "logstash-group"
  config :client_id, :validate => :string, :default => "logstash-client"
  config :subscription_type, :validate => :string, :default => "Shared"
  config :subscription_initial_position, :validate => :string, :default => "Earliest"
  config :consumer_threads, :validate => :number, :default => 1


  config :decorate_events, :validate => :boolean, :default => false
  config :commit_async, :validate => :boolean, :default => false


  

  public
  def register
    logger.info("register logstash-input-pulsar")
    @runner_threads = []
    @runner_pulsar_clients = Array.new
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
    logger.info("Stop all pulsar consumer !")
    @runner_consumers.each { |c| c.close }

    logger.info("Stop all pulsar client  !!!")
    @runner_pulsar_clients.each { |c| c.close }

    @runner_threads.each { |t| t.exit }
  end

  private
  def create_consumer(client_id)
    begin
      logger.info("client - ", :client => client_id)
      clientBuilder = org.apache.pulsar.client.api.PulsarClient.builder()
      clientBuilder.serviceUrl(@service_url)
      if not @auth_plugin_class_name.nil? and not @auth_params.nil?
        auth = org.apache.pulsar.client.api.AuthenticationFactory.create(@auth_plugin_class_name, @auth_params.value)
        clientBuilder.authentication(auth)
      end
      client = clientBuilder.build
      @runner_pulsar_clients.push(client)

      logger.info("topic:",:topic => @topics.to_java('java.lang.String'))

      consumerBuilder = client.newConsumer.clone
      unless @topics_pattern.nil?
        consumerBuilder.topicsPattern(@topics_pattern.to_java('java.lang.String'))
      else
        consumerBuilder.topic(@topics.to_java('java.lang.String')) 
      end

      subscriptionType = org.apache.pulsar.client.api.SubscriptionType
      if @subscription_type == "Exclusive"
        consumerBuilder.subscriptionType(subscriptionType::Exclusive)
      elsif @subscription_type == "Failover"
        consumerBuilder.subscriptionType(subscriptionType::Failover)
      elsif @subscription_type == "Key_Shared"
        consumerBuilder.subscriptionType(subscriptionType::Key_Shared)
      else
        consumerBuilder.subscriptionType(subscriptionType::Shared)
      end

      subscriptionInitialPositionType = org.apache.pulsar.client.api.SubscriptionInitialPosition
      if @subscription_initial_position == "Latest"
        consumerBuilder.subscriptionInitialPosition(subscriptionInitialPositionType::Latest)
      else
        consumerBuilder.subscriptionInitialPosition(subscriptionInitialPositionType::Earliest)
      end

      consumer = consumerBuilder.subscriptionName(@subscription_name)
        .consumerName(client_id)
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
            if commit_async
              consumer.acknowledgeAsync(record)
            else
              consumer.acknowledge(record)
            end
            
          end
        end
      rescue => e
        logger.error("exit - ",:cause => e.respond_to?(:getCause) ? e.getCause() : nil)
        consumer.close
      end
    end
  end

end