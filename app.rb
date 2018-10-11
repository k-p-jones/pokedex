require 'sinatra/base'
require 'json'

class App < Sinatra::Base
  get '/pokemon' do
    pokemon_index.to_json
  end

  # Key can be a pokemon name or id
  get '/pokemon/:key' do
    if params[:key].match(/(\d+)/)
      target = pokemon_index.find { |pokemon| pokemon['id'] == params[:key].match(/(\d+)/)[1] }
      return pokemon_not_found(params[:key]) unless target
      File.read("api/v2/pokemon/#{params[:key].match(/(\d+)/)[1]}/index.json")
    else
      target = pokemon_index.find { |pokemon| pokemon['name'] == params[:key] }
      return pokemon_not_found(params[:key]) unless target
      File.read(File.join(target['url'].sub("/", ''), 'index.json'))
    end
  end

  private

  def pokemon_not_found(key)
    [404, {}, {error: "#{key} didn't match any Pokemon"}.to_json]
  end

  def pokemon_index
    @pokemon_index ||= generate_index
  end

  def generate_index
    data = JSON.parse(File.read('api/v2/pokemon/index.json'))
    data['results'].each do |pokemon|
      pokemon['id'] = pokemon['url'].match(/\/api\/v2\/pokemon\/(\d+)/)[1]
    end
  end
end
