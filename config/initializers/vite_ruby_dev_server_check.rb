# Workaround: on macOS 26.7.1, Socket.tcp(..., connect_timeout:) returns an
# unconnected socket instead of raising ECONNREFUSED when nothing is listening.
# vite_ruby uses that call to detect the Vite dev server, so it always thinks
# one is running and never falls back to autoBuild. TCPSocket.new still reports
# refused connections correctly. Remove once Ruby or macOS fixes Socket.tcp.
module ViteRubyDevServerCheck
  def dev_server_running?
    return false unless run_proxy?
    return @running if defined?(@running) && Time.now - @running_checked_at < 1

    begin
      TCPSocket.new(config.host, config.port, connect_timeout: config.dev_server_connect_timeout).close
      @running = true
    rescue
      @running = false
    ensure
      @running_checked_at = Time.now
    end
  end
end

ViteRuby.prepend(ViteRubyDevServerCheck) if Rails.env.development?
