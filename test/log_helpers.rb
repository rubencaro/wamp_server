
module Helpers
  module Log

    @@next_color = 0 # for alternate
    @@palette = [:dark_gray, :light_gray]

    def log(msg, opts = {})

      if not opts[:clean] then
        opts[:location] ||= caller_locations(1,1)[0].label # much faster than 'caller'
        msg = "[#{opts[:location]}] #{msg}"
      end

      if opts[:color] then
        msg = send(opts[:color],msg)
      end

      msg = "[#{Time.now.strftime('%F %T')}]" + msg if not opts[:clean]
      puts msg
      $stdout.flush # as soon as possible
    end

    def log_ex(ex, opts = {})
      trace = opts[:trace] || true
      msg = opts[:msg] || ''
      msg += light_purple(" \n Exception: #{ex} \n ")
      msg << purple(" Backtrace: #{ex.backtrace.join("\n")} ") if trace
      log msg
    end

    def spit(msg, opts = {}) # allow hashes as msg
      opts[:color] ||= :light_red
      opts[:clean] = true
      l = caller_locations(1,1)[0]
      log "\n[#{l.label}:#{l.lineno}] \n " + msg.inspect + " \n ", opts
    end

    def announce(msg = nil, opts = {})
      label = caller_locations(1,1)[0].label
      place = File.basename(caller_locations(1,1)[0].path) + ":" + caller_locations(1,1)[0].lineno.to_s
      msg ||= "\n ==> Entering #{label} (#{place})..."
      opts[:color] ||= :cyan
      opts[:clean] = true
      log msg, opts
    end

    def yellow(str)
      " \033[1;33m " + str + " \033[00m "
    end

    def cyan(str)
      " \033[0;36m " + str + " \033[00m "
    end

    def light_cyan(str)
      " \033[1;36m " + str + " \033[00m "
    end

    def purple(str)
      " \033[0;35m " + str + " \033[00m "
    end

    def light_purple(str)
      " \033[1;35m " + str + " \033[00m "
    end

    def brown(str)
      " \033[0;33m " + str + " \033[00m "
    end

    def red(str)
      " \033[0;31m " + str + " \033[00m "
    end

    def light_red(str)
      " \033[1;31m " + str + " \033[00m "
    end

    def light_gray(str)
      " \033[0;37m " + str + " \033[00m "
    end

    def dark_gray(str)
      " \033[1;30m " + str + " \033[00m "
    end

    def white(str)
      " \033[1;37m " + str + " \033[00m "
    end

    def alternate(str)
      color = @@palette[@@next_color]
      @@next_color += 1
      @@next_color = 0 if @@next_color >= @@palette.size
      send(color,str)
    end

  end

  extend Log
end

H = Helpers if not defined? H
