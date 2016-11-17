# -*- coding: utf-8 -*-
require 'fluent-logger'

Plugin::create(:fluentd) do
  on_boot do
    UserConfig[:fluentd_port] ||= 24224
    UserConfig[:fluentd_host] ||= '127.0.0.1'

    @logger = Fluent::Logger::FluentLogger.open('mikutter', host: UserConfig[:fluentd_host], port: UserConfig[:fluentd_port])
  end

  on_update do |s, m|
    if msg = m.first
      @logger.post("timeline", msg.to_hash)
    end
  end

  on_favorite do |s, u, m|
    m[:favoritedby] = u
    msg = m
    @logger.post("favorited", msg.to_hash)
  end

  on_appear do |message|
    message.map do |msg|
      @logger.post("appear", msg.to_hash)
    end
  end

  on_spectrum_set do |spectrum|
    @lock << spectrum
  end

  settings 'fluentd' do
    input "fluentd host", :fluentd_host
    adjustment "port number", :fluentd_port, 1024, 0xffff
  end

  def object_counts
    ObjectSpace.garbage_collect
    objects = Hash.new(0)
    ObjectSpace.each_object.to_a.each{|o| objects[o.class] += 1 unless (o.irregulareval? rescue nil) }
    @logger.post("memory", objects)
    objects.clear
    profile
  end

  def profile
    t = Reserver.new(1){ Plugin.call(:spectrum_set, -> { object_counts }) }
    notice "profile time: #{t}"
  end

  @lock = Queue.new
  Thread.new do
    loop do
      begin
        @lock.pop.call
      rescue => e
        error e
      end
    end
  end

  profile()
end
