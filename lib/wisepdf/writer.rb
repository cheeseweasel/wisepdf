module Wisepdf
  class Writer
    require 'posix-spawn'
    include POSIX::Spawn

    def initialize(wkhtmltopdf = nil, options = {})
      self.wkhtmltopdf = wkhtmltopdf unless wkhtmltopdf.nil?
      self.options = options
    end

    def to_pdf(string, options={})
      invoke = self.command(options).join(' ')
      self.log(invoke) unless Wisepdf::Configuration.production?

      pid, pin, pout, err = popen4(invoke)
      pin.write string
      pin.close
      ::Process.wait(pid)

      result = pout.read

      raise Wisepdf::WriteError if result.to_s.strip.empty?

      return result
    end

    def wkhtmltopdf
      @wkhtmltopdf || self.wkhtmltopdf = Wisepdf::Configuration.wkhtmltopdf
    end

    def wkhtmltopdf=(value)
      raise Wisepdf::NoExecutableError.new(value) if value.blank? || !File.exists?(value)
      @wkhtmltopdf = value
    end

    def options
      @options ||= Wisepdf::Parser.parse(Wisepdf::Configuration.options.dup)
      @options
    end

    def options=(value)
      self.options.merge!(Wisepdf::Parser.parse(value))
    end

  protected

    def command(options = {})
      options = Wisepdf::Parser.parse(options)

      args = [self.wkhtmltopdf]
      args += self.options.merge(options).to_a.flatten.compact
      args << '--quiet'

      args << '-'
      args << '-'

      args.map {|arg| %Q{"#{arg.gsub('"', '\"')}"}}
    end

    def log(command)
      puts "*"*15
      puts command
      puts "*"*15
    end
  end
end
