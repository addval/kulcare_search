require 'sinatra'
require 'rest_client'
require 'byebug'

class KulcareSearch < Sinatra::Base
  set :bind, '0.0.0.0'

  get '/' do
    'Welcome to Kulcare Search'
  end

  get '/medicines_development' do
    get_medicines('development', params)
  end

  get '/medicines_staging' do
    get_medicines('staging', params)
  end

  get '/medicines' do
    get_medicines('production', params)
  end

  private

  def get_medicines(env, params)
    case env
    when 'development'
      medicines_index = 'medicines_development'
    when 'staging'
      medicines_index = 'medicines_staging'
    when 'production'
      medicines_index = 'medicines_production'
    end
    url = "http://localhost:9200/#{medicines_index}/_search"

    if params[:name]
      data = '{"query": {  "match": {  "name": "' + params[:name] + '"  }  }  }'
    else
      data = nil
    end
    RestClient.post url, data
  end
end
