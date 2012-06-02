# -*- coding: utf-8 -*-
require 'fluent-logger'

Plugin::create(:fluentd) do
  on_boot do
    UserConfig[:fluentd_port] ||= 24224
    UserConfig[:fluentd_host] ||= '127.0.0.1'

    @logger = Fluent::Logger::FluentLogger.open('mikutter',
                                                :host=>UserConfig[:fluentd_host],
                                                :port=>UserConfig[:fluentd_port])
  end

  on_update do |s, m|
    m = m.first
    if m
      @logger.post("timeline", m.to_hash)
    end
  end

  on_favorite do |s, u, m|
    fluent = m.to_hash
    m[:favoritedby] = u
    @logger.post("favorited", m.to_hash)
  end

  settings 'fluentd' do
    input "fluentd host", :fluentd_host
    adjustment "port number", :fluentd_port, 1024, 0xffff
  end
end
