=begin rdoc
=Alien Ruby RFID Library 
==alienconnection.rb	

A simple class to handle the basics of socket communication with RFID readers from Alien Technology Corporation.

Copyright 2008, Alien Technology Corporation. All rights reserved.
=end

require 'socket'
require 'timeout'

# Handles socket communication w/an Alien RFID Reader.
class AlienConnection

	attr_accessor :raise_errors

	def initialize
		@connected = false
		@raise_errors = true
	end
	
	# Returns the connected status of this AlienReader.
	def connected
		return @connected
	end


	# Read from the open socket until a null character is found.
	# Strips off the trailing \r\n from the response
	def receive(opts={})
		timeout = opts.fetch(:timeout, 40).to_i
		wait_for_null = opts.fetch(:wait_for_null, true)

		s = ""
		
		# Wait for data to become available on the socket
		res = select([@sock], nil, nil, timeout)
		if (res == nil)
			raise "Timeout waiting for reader response." if @raise_errors
		end
		
		if (wait_for_null)
			# Some readers don't put a null on the end of the 'call back later' message. 
			# Check for 'later' to know when to punt on the read.
			begin
				Timeout.timeout(timeout) {
					char = @sock.recv(1)
					while (char != "\0")
						s << char
						char = @sock.recv(1)
					end
				}
			rescue Timeout::Error
				raise "Timeout waiting for reader response." if @raise_errors
			end
			
			s.strip!

			if s.include? "Error"
				raise s if @raise_errors
			end
			
			# If this is a response to a Quit command, the reader will close the socket. 
			# If there is an active connection, the reader will reject our attempt to connect.
			# Either way, we're not connected anymore...
			if (s.include? "Goodbye!")
				close(false)
			end
			
			return s
		else
			# Simply try to read up to 1 kB and return it
			return @sock.recv(1024)
		end
	end


	# Send a message over an open socket (Alien terse msg format to suppress prompts on reply)
	def send (msg="")
		if @connected
			@sock.write "\1#{msg}\r\n" # leading \1 for terse reply
		end
	end


	# Send a message over an open socket and wait for a reply
	def sendreceive(msg="", opts={})
		timeout = opts.fetch(:timeout, 40)
		wait_for_null = opts.fetch(:wait_for_null, true)
		
		begin
			if @connected
				send(msg)
				receive(:timeout=>timeout, :wait_for_null=>wait_for_null)
			else
				raise "Not connected to reader."
			end
		rescue
			err = "Error in alienconnection:\nTried to send:\"#{msg}\"\nand got:\n\"" + $! +"\""
			raise err
		end
	end


	# Try to open a socket connection to the reader. 
	def connect(ipaddress='localhost', port=23)
		@connected = false
		
		#connect to a reader and grab the welcome message...
		begin
			Timeout.timeout(3) {
				@sock = TCPSocket.new(ipaddress, port)
			}
			
			s = receive() #Grab the welcome message
			if s.include?("later.")  #Reader is busy. Please call back later.
				raise "Trouble Connecting to #{ipaddress}. (Someone else is talking to the reader.)"
			end
			@connected = true
		rescue RuntimeError
			raise
		rescue Timeout::Error, Errno::ETIMEDOUT
			raise "Trouble Connecting to #{ipaddress}. (No reader at this IP?)"
		rescue Errno::ECONNREFUSED
			raise "Trouble Connecting to #{ipaddress}. (Connection refused.)"	
		end
		
		return @connected
	end


	private
	# Login to the reader on an open socket connection. Call connect first.
	def login (username="alien", password="password")
		if @connected
			begin
				@sock.write "#{username}\r\n"
				receive()
				@sock.write "#{password}\r\n"
				s = receive()
				
				if s.include? "Error:"
					err_msg = s.scan(/(Error: )(.*)/).flatten[1]
					close()
					raise "Trouble logging in. " << err_msg
					@connected = false
				end
			rescue
				raise
			end
		end

		return @connected
	end
	
	public
	# Execute both the connect and login methods in one call.
	def open(ipaddress="localhost", port=23, username="alien", password="password")
		connect(ipaddress,port)
		
		if @connected
			login(username,password)
		end
		
		return @connected
	end
	

	# Close the socket.
	def close(send_quit=true)
		if @connected
			if send_quit
				@sock.write("quit\r\n")
				sleep 1
			end
			@sock.close()
		end
		
		@connected = false
		return true
	end

end #class AlienConnection
