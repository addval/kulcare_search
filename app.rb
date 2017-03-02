require 'sinatra'
require 'rest_client'
require 'byebug'

class KulcareSearch < Sinatra::Base
  set :bind, '0.0.0.0'

  get '/' do
    'Welcome to Kulcare Search'
  end

  get '/medicines_development' do
    get_medicines('medicines_development', params)
  end

  get '/medicines_staging' do
    get_medicines('medicines_staging', params)
  end

  get '/medicines' do
    get_medicines('medicines_production', params)
  end

  private

  def get_medicines(i, params)
    url = "http://localhost:9200/#{i}/_search"

    if params[:name]
      data = '{
                "query": {
                  "match": {
                    "name": "' + params[:name] + '"
                  }
                }
              }'
    else
      data = nil
    end
    RestClient.post url, data
  end
end
