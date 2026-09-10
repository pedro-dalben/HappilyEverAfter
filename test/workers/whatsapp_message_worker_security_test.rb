# frozen_string_literal: true

# Run with: ruby test/workers/whatsapp_message_worker_security_test.rb
# No application boot, database connection, queue, or outbound messages.
require "active_record"
require "sidekiq"
require "logger"
require "ostruct"

module Rails
  def self.env = OpenStruct.new(test?: true)
end

class WhatsappMessage < ActiveRecord::Base
  self.table_name = "whatsapp_messages"

  class << self
    attr_accessor :observed_ids

    def where(id:)
      observed_ids << id
      OpenStruct.new(exists?: false)
    end

    def find_by(id:) = nil
  end
end

require_relative "../../app/workers/whatsapp_message_worker"
worker = WhatsappMessageWorker.new
worker.define_singleton_method(:logger) { Logger.new(File::NULL) }
WhatsappMessage.observed_ids = []
[42, "1); SELECT pg_sleep(30); --"].each do |id|
  begin
    worker.perform(id)
    raise "Missing records must still raise"
  rescue ActiveRecord::RecordNotFound
    raise "ID did not use the parameterized model API" unless WhatsappMessage.observed_ids.last == id
  end
end
puts "PASS: numeric and hostile IDs use the model query API; missing records still raise"
