require 'socket'

server = TCPServer.new('0.0.0.0', 80)

loop do
  client = server.accept
  request = client.readpartial(2048)

  method, path, version = request.lines[0].split

  puts "#{method} #{path} #{version}"

  response =
    if path == "/healthcheck"
      "HTTP/1.1 200 OK\r\nContent-Length: 2\r\n\r\nOK"
    else
      "HTTP/1.1 200 OK\r\nContent-Length: 38\r\n\r\nWell, hello there! This is version 1.0"
    end

  client.write(response)
  client.close
end
