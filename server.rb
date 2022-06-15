require "erubis"
require "sinatra"
require "sinatra/reloader" if development?
require "uri"
require "net/http"
require "json"
require "csv"

def url_builder(group_id, metric, period, limit, offset)
  new_uri = 'https://api.wiseoldman.net/groups/'
  new_uri << "#{group_id}"
  new_uri << "/gained?metric=#{metric}"
  new_uri << "&period=#{period}"
  new_uri << "&limit=#{limit}"
  new_uri << "&offset=#{offset}"
  URI(new_uri)
end

def json_to_csv(content)
  File.write("cache_response.json", content)
  json = JSON.parse(File.open("cache_response.json").read)
  headings = Array.new
  headings << "username"
  headings << "start"
  headings << "end"
  headings << "gained"

  csv_string = CSV.open("cache_response.txt", "wb") do |csv|
    csv << headings
    json.each do |hash|
      row = {}

      headings.each do |heading|
        row[heading] = nil
      end

      row["username"] = hash["player"]["username"]
      row["start"] = hash["start"]
      row["end"] = hash["end"]
      row["gained"] = hash["gained"]

      csv << row.values
    end
  end
  File.write("new_csv.txt", File.read('cache_response.txt'))
end

get '/' do
  @metrics_arr = ["Overall", "Attack", "Defense", "Hitpoints", "Ranged", "Prayer", "Magic",
                  "Cooking", "Woodcutting", "Fletching", "Fishing", "Firemaking", "Crafting",
                  "Smithing", "Mining", "Herblore", "Agility", "Thieving", "Slayer", "Farming",
                  "Runecrafting", "Hunter"]
  erb :main
end

post '/get_data' do
  uri = url_builder(params[:group_id], params[:metrics].to_s.downcase, params[:periods].to_s.downcase, params[:limit], params[:offset])

  request = Net::HTTP::Get.new(uri)
  request['Content-Type'] = 'application/json; utf-8'
  request['Accept'] = 'application/json'

  res = Net::HTTP.start(uri.hostname, uri.port, :use_ssl => true) {|http|
    http.request(request)
  }
  
  json_to_csv(res.body)
  
  redirect '/download'
end

get '/download' do
  headers['Content-Type'] = 'text/plain'
  File.open('new_csv.txt')
end