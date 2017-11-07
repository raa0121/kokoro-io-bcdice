$LOAD_PATH << File.dirname(__FILE__) + '/BCDice/src'

require 'cgiDiceBot.rb'

require 'sinatra'
require 'openssl'
require 'net/http'
require 'dotenv/load'

get '/' do
  'BCDice'
end

post '/' do
  json = JSON.parse request.body.read, symbolize_names: true
  exit if ENV['KOKOROIO_CALLBACK_SECRET'] == json[:callback_secret]
  content = json[:raw_content]
  channel_id = json[:channel][:id]
  bot = CgiDiceBot.new
  text, gameType = content.split(/[\s　]+/)
  gameList = JSON.parse(File.open('gameList.json','r').read)
  gameType ||= ''
  gameType = gameList.fetch(gameType, '')
  result = bot.roll(text, gameType).first.strip || ''
  url = URI.parse('%sapi/v1/bot/channels/%s/messages' % [ENV['KOKOROIO_BASE_URL'], channel_id])
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  req = Net::HTTP::Post.new url.request_uri
  req['X-Access-Token'] = ENV['KOKOROIO_ACCESS_TOKEN']
  req['Content-Type'] = 'application/x-www-form-urlencode'
  req.set_form_data({message: result})
  res = http.request(req)
end
