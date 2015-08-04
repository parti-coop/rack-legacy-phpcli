require 'rack/legacy'
require 'rack/request'
require 'childprocess'

class Rack::Legacy::PhpCli < Rack::Legacy::Cgi
  # Like Rack::Legacy::Cgi.new except allows an additional argument
  # of which executable to use to run the PHP code.
  #
  #  use Rack::Legacy::PhpCli, 'public', 'php5-cgi'
  def initialize(app, public_dir=FileUtils.pwd, php_exe='php-cgi')
    super app, public_dir
    @php_exe = php_exe
  end

  # Returns the path with the public_dir pre-pended and with the
  # paths expanded (so we can check for security issues)
  def full_path(path)
    ::File.expand_path ::File.join(@public_dir, path)
  end

  # Override to check for php extension. Still checks if
  # file is in public path and it is a file like superclass.
  def valid?(path)
    sp = path_parts(path)[0]

    # Must have a php extension or be a directory
    return false unless
      (::File.file?(sp) && sp =~ /\.php$/) ||
      ::File.directory?(sp)

    # Must be in public directory for security
    sp.start_with? ::File.expand_path(@public_dir)
  end

  # Monkeys with the arguments so that it actually runs PHP's cgi
  # program with the path as an argument to that program.
  def run(env, path)
    script, info = *path_parts(path)
    if ::File.directory? script
      # If directory then assume index.php
      script = ::File.join script, 'index.php';
      # Ensure it ends in / which some PHP scripts depend on
      path = "#{path}/" unless path =~ /\/$/
    end
    env['SCRIPT_FILENAME'] = script
    env['SCRIPT_NAME'] = strip_public script
    env['PATH_INFO'] = info

    if env['CUSTOM_REQUEST_URI'].nil?
      env['REQUEST_URI'] = strip_public path
      env['REQUEST_URI'] += '?' + env['QUERY_STRING'] if
        env.has_key?('QUERY_STRING') && !env['QUERY_STRING'].empty?
    else
      env['REQUEST_URI'] = env['CUSTOM_REQUEST_URI']
    end

    # Setup CGI process
    cgi = ChildProcess.build @php_exe, "-d", "cgi.force_redirect=0"
    cgi.duplex = true
    cgi.cwd = File.dirname path

    # Arrange CGI processes IO
    cgi_out, cgi.io.stdout = IO.pipe
    cgi.io.stderr = $stderr

    # Config CGI environment
    cgi.environment['DOCUMENT_ROOT'] = @public_dir
    cgi.environment['SERVER_SOFTWARE'] = 'Rack Legacy'
    env.each do |key, value|
      cgi.environment[key] = value if
        value.respond_to?(:to_str) && key =~ /^[A-Z_]+$/
    end

    # Start running CGI
    cgi.start

    # Delegate IO to CGI process
    cgi.io.stdin.write env['rack.input'].read if env['rack.input']
    cgi.io.stdout.close

    # Extract headers from output
    headers = {}
    until cgi_out.eof? || (line = cgi_out.readline.chomp) == ''
      if line =~ /\s*\:\s*/
        key, value = line.split /\s*\:\s*/, 2
        if headers.has_key? key
          headers[key] += "\n" + value
        else
          headers[key] = value
        end
      end
    end

    # Extract status from sub-process, default to 200
    status = (headers.delete('Status') || 200).to_i

    # Throw error if process crashed.
    # NOTE: Process could still be running and crash later. This just
    #       ensure we response correctly if it immmediately crashes
    raise Rack::Legacy::ExecutionError if cgi.crashed?

    # Send status, headers and remaining IO back to rack
    [status, headers, cgi_out]
  end

  private

  def strip_public(path)
    path.sub ::File.expand_path(@public_dir), ''
  end

  # Given a full path will separate the script part from the
  # path_info part. Returns an array. The first element is the
  # script. The second element is the path info.
  def path_parts(path)
    return [path, nil] unless path =~ /.php/
    script, info = *path.split('.php', 2)
    script += '.php'
    [script, info]
  end

  # Given a full path will extract just the info part. So
  #
  #   /index.php/foo/bar
  #
  # will return /foo/bar, but
  #
  #   /index.php
  #
  # will return an empty string.
  def info_path(path)
    path.split('.php', 2)[1].to_s
  end
end
