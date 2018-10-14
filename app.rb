require 'sinatra/base'
require 'json'
require 'redis'

class App < Sinatra::Base
  before do
    headers['Access-Control-Allow-Methods'] = 'GET'
    headers['Access-Control-Allow-Origin'] = '*'
  end

  get '/pokemon' do
    pokemon_index.to_json
  end

  # Key can be a pokemon name or id
  get '/pokemon/:key' do
    if params[:key].match(/(\d+)/)
      target = pokemon_index.find { |pokemon| pokemon['id'] == params[:key].match(/(\d+)/)[1] }
      return pokemon_not_found(params[:key]) unless target
      cache_data("api/v2/pokemon/#{params[:key].match(/(\d+)/)[1]}/index.json")
    else
      target = pokemon_index.find { |pokemon| pokemon['name'] == params[:key] }
      return pokemon_not_found(params[:key]) unless target
      cache_data(File.join(target['url'].sub("/", ''), 'index.json'))
    end
  end

  get '/pokemon/sprites/:name/:file' do
    send_file(File.join('images/sprites/', params[:name], params[:file]), :disposition => 'inline')
  end

  private

  def pokemon_not_found(key)
    [404, {}, {error: "#{key} didn't match any Pokemon"}.to_json]
  end

  def pokemon_index
    @pokemon_index ||= generate_index
  end

  def generate_index
    # Could be handled better
    data = JSON.parse(cache_data('api/v2/pokemon/index.json'))
    data['results'].each do |pokemon|
      pokemon['id'] = pokemon['url'].match(/\/api\/v2\/pokemon\/(\d+)/)[1]
      pokemon['image'] = "http://127.0.0.1:9292/pokemon/sprites/#{pokemon['name']}/front_default.png"
    end
  end

  def cache_data(key)
    data = redis.get(key)

    unless data
      value = File.read(key)
      redis.set(key, value)
      data = value
    end

    data
  end

  def redis
    @redis ||= Redis.new
  end
end
