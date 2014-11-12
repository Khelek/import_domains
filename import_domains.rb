#!/usr/bin/env ruby
require 'faraday'
require 'optparse'
require 'json'
require 'nokogiri'


def log_res(conn, path, res)
  url = conn.url_prefix
  puts "ERROR with response: url: #{url}, path: #{path}"
  puts
  puts "headers: #{res.headers},"
  puts
  puts "status: #{res.status},"
  puts
  puts "body: #{res.body}"
end

def request(conn, type, path)
  res = conn.send(type) do |req|
    req.url path
    #req.body = "grant_type=password&username=#{options[:name]}&password=#{options[:password]}&scope=.%2B%3A%2Fdns-master%2F.%2B&client_id=#{client_id}&client_secret=#{client_secret}"
    yield(req)
  end

  unless res.status == 200
    log_res(conn, path, res)
 #   raise
  end

  res
end

options = {}

OptionParser.new do |opts|
  opts.on("-n","--name NAME","Username for login(for example 12345/NIC-REG)") do |name|
    options[:name] = name
  end

  opts.on('-p', '--password PASSWORD', 'Password for login(for example 123456)') do |pass|
    options[:password] = pass
  end

  opts.on('-d', '--domains DOMAINS', 'Domains list(for example "domain.ru,domain2.ru")') do |domains|
    domains = domains.split(%r{,\s*})
    options[:domains] = domains
  end

  opts.on('-i', '--client_id CLIENTID', 'Id your application in nic.ru') do |id|
    options[:client_id] = id
  end

  opts.on('-s', '--client_secret SECRET', 'Secret key your application in nic.ru') do |key|
    options[:client_secret] = key
  end

  opts.parse!
end


if options[:domains].nil? || options[:domains].empty?
  puts "ERROR: domains size must be greater or equal of 1"
  abort
end

client_id = options[:client_id]
client_secret = options[:client_secret]

url = 'https://api.nic.ru/'
conn = Faraday.new(:url => url) do |faraday|
  faraday.request  :url_encoded             # form-encode POST params
  faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
end

res = request(conn, :post, '/oauth/token') do |req|
  req.body = "grant_type=password&username=#{options[:name]}&password=#{options[:password]}&scope=.%2B%3A%2Fdns-master%2F.%2B&client_id=#{client_id}&client_secret=#{client_secret}"
end

unless res.status == 200
  abort
end

json = JSON.parse(res.body)
access_token = json["access_token"]
token_type = json["token_type"]

puts "Expires in #{json["expires_in"]} seconds"
puts
puts "Token: #{token_type} #{access_token}"
puts

options[:domains].each do |domain|
  res = request(conn, :put, "/dns-master/zones/primary/#{domain.upcase}") do |req|
    req.headers['Authorization'] = "#{token_type} #{access_token}"
  end

  puts
  if res.status == 200
    xml = Nokogiri::XML(res.body)
    status = xml.xpath("//response/status").first
    status = status.text if status
    data = xml.xpath("//response/data").first
    data = data.to_xml if data

    puts "DOMAIN #{domain} ADDED."
    puts "Adding status: #{status},"
    puts "data: #{data}"
  else
    puts "DOMAIN #{domain} NOT ADDED."
  end
  puts
end

puts "PROCCESS DONE!"

