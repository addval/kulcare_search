require 'sinatra'
require 'elasticsearch'
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
    # Attribute Filters
    must_filter = []
    must_filter.push(match: { id: params[:id] }) if params[:id]
    must_filter.push(match_phrase: { name: params[:name] }) if params[:name]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by])

    search_query =  {
                      query: {
                        filtered: {
                          filter: {
                            bool: {
                              must: must_filter
                            }
                          }
                        }
                      },
                      sort: sort_filter,
                      from: page,
                      size: perpage
                    }

    client = Elasticsearch::Client.new log: true
    results = client.search index: i, body: search_query
    results["hits"].to_json
  end

  def sort_filter(sort_order, sort_by)
    sort_filter = []
    sort_by = 'name' if !sort_by || !%w(id, name).include?(sort_by.to_s)
    sort_order = 'asc' if !sort_order || !%w(asc, desc).include?(sort_order.to_s)

    case sort_by
    when 'id'
      sort_filter.push(id: { order: sort_order })
    when 'name'
      sort_filter.push(name: { order: sort_order })
    end
    sort_filter
  end
end
