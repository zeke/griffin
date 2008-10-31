# Requires the following gems: xml-simple and ruby-growl (http://segment7.net/projects/ruby/growl/)

require 'net/http'
require 'rubygems'
require 'xmlsimple'
require 'ruby-growl'
require 'time'

@@config = {:username => 'zeke', :password => 'secret', :frequency => 1}

def call_twitter(method, arg_options={})
  options = { :auth => true }.merge(arg_options)

  path    = "/statuses/#{method.to_s}.xml"
  headers = { "User-Agent" => @@config[:username] }

  begin
    response = Net::HTTP.start('twitter.com', 80) do |http|
        req = Net::HTTP::Get.new(path, headers)
        req.basic_auth(@@config[:username], @@config[:password]) if options[:auth]
        http.request(req)
    end

    response.body
  rescue Exception
    return nil
  end
end

g = Growl.new "127.0.0.1", "squawk", ["squawk Notification"]
last_fetch = Time.now

while true do
  puts "checkin' it out"
  xml = call_twitter(:friends_timeline)
  unless xml.nil?
    doc = XmlSimple.xml_in(xml)
    raise doc.to_yaml
    doc['status'].reverse.each do |status|
      if status['user']
        g.notify "squawk Notification", status['user'][0]['name'].to_s, status['text'].to_s if Time.parse(status['created_at'].to_s) > last_fetch
      end
    end
  
    last_fetch = Time.now
  end
  sleep @@config[:frequency] * 60
end