require 'sinatra'
require 'sinatra/cross_origin'
require 'elasticsearch'
require 'json'
require 'byebug'

class KulcareSearch < Sinatra::Base
  set :bind, '0.0.0.0'

  # CORS Configuration
  configure do
    enable :cross_origin
  end

  before do
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  # Default home page
  get '/' do
    'Welcome to Kulcare Search !'
  end

  # Medicines Search
  get '/medicines_development' do
    content_type :json
    get_medicines('medicines_development', params)
  end

  get '/medicines_staging' do
    content_type :json
    get_medicines('medicines_staging', params)
  end

  get '/medicines' do
    content_type :json
    get_medicines('medicines_production', params)
  end

  # Doctors Search
  get '/doctors_development' do
    content_type :json
    get_doctors('doctors_development', params)
  end

  get '/doctors_staging' do
    content_type :json
    get_doctors('doctors_staging', params)
  end

  get '/doctors' do
    content_type :json
    get_doctors('doctors_production', params)
  end

  # Labs Search
  get '/labs_development' do
    content_type :json
    get_labs('labs_development', params)
  end

  get '/labs_staging' do
    content_type :json
    get_labs('labs_staging', params)
  end

  get '/labs' do
    content_type :json
    get_labs('labs_production', params)
  end

  # Pharmacies Search
  get '/pharmacies_development' do
    content_type :json
    get_pharmacies('pharmacies_development', params)
  end

  get '/pharmacies_staging' do
    content_type :json
    get_pharmacies('pharmacies_staging', params)
  end

  get '/pharmacies' do
    content_type :json
    get_pharmacies('pharmacies_production', params)
  end

  # CORS Configuration
  options "*" do
    response.headers["Allow"] = "GET,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    response.headers["Access-Control-Allow-Origin"] = "*"
    200
  end

  private

  # Get Medicines
  def get_medicines(i, params)
    # Attribute Filters
    must_filter = []

    # Search by single or multiple ids (comma separated)
    if params[:id]
      if params[:id].include? ','
        ids = params[:id].split(",").map { |s| s.to_i }
        must_filter.push({ terms: { id: ids }})
      else
        must_filter.push({term: { id: params[:id] }})
      end
    end

    # Search by name (autocomplete)
    must_filter.push(match_phrase_prefix: { name: params[:name] }) if params[:name]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = medicines_sort_filter(params[:sort_order], params[:sort_by])

    # Elasticsearch DSL Query
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

    client = Elasticsearch::Client.new
    results = client.search index: i, body: search_query
    results["hits"].to_json
  end

  # Medicines sort filter
  def medicines_sort_filter(sort_order, sort_by)
    sort_filter = []
    # Default: sort by name ASC
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

  # Get Doctors
  def get_doctors(i, params)
    # Attribute filters
    must_filter = []
    should_filter = []

    # Search by single or multiple ids (comma separated)
    if params[:id]
      if params[:id].include? ','
        ids = params[:id].split(",").map { |s| s.to_i }
        must_filter.push({ terms: { id: ids }})
      else
        must_filter.push({term: { id: params[:id] }})
      end
    end

    # Search by public URL
    must_filter.push(term: { url: params[:url] }) if params[:url]

    # Search by name (autocomplete) or speciality
    must_filter.push(multi_match:
                      {
                        query: params[:name],
                        type: "phrase_prefix",
                        fields: ["name", "speciality"]
                      }
                    ) if params[:name]

    # Search by gender
    must_filter.push(match_phrase: { gender: params[:gender] }) if params[:gender]

    # Search by single or multiple specialities (comma separated)
    if params[:main_speciality]
      if params[:main_speciality].include? ','
        main_specialities = params[:main_speciality].split(",").map { |s| s.to_s }
        main_specialities.each do |spc|
          should_filter.push(match_phrase_prefix: { speciality: spc })
        end
      else
        must_filter.push(match_phrase_prefix: { speciality: params[:main_speciality] })
      end
    end

    # Search by city
    must_filter.push(match: { city: params[:city] }) if params[:city]

    # Search by visiting charges range
    must_filter.push(
      visiting_charges_filter(params[:visiting_charges_min], params[:visiting_charges_max])
    ) if params[:visiting_charges_min] or params[:visiting_charges_max]

    # Search by case file review fees range and availability
    must_filter.push(
      case_file_review_charges_filter(params[:case_file_review_fees_min], params[:case_file_review_fees_max])
    ) if params[:case_file_review_fees_min]
    must_filter.push(
      term: { "consultation_profile.case_file_review_availability": params[:case_file_review_availability] }
    ) if params[:case_file_review_availability]

    # Search by online consultation fees range and availability
    must_filter.push(
      online_consult_charges_filter(params[:online_consultation_fees_min], params[:online_consultation_fees_max])
    ) if params[:online_consultation_fees_min]
    must_filter.push(
      term: { "consultation_profile.online_consultation_availability": params[:online_consultation_availability] }
    ) if params[:online_consultation_availability]

    # Geo Location Search
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])

    # Elasticsearch DSL Query
    search_query =  {
                      query: {
                        filtered: {
                          filter: {
                            bool: {
                              must: must_filter,
                              should: should_filter
                            }
                          }
                        }
                      },
                      sort: sort_filter,
                      from: page,
                      size: perpage
                    }

    client = Elasticsearch::Client.new
    results = client.search index: i, body: search_query
    results["hits"].to_json
  end

  # Get Labs
  def get_labs(i, params)
    # Attribute filters
    must_filter = []

    # Search by single or multiple ids (comma separated)
    if params[:id]
      if params[:id].include? ','
        ids = params[:id].split(",").map { |s| s.to_i }
        must_filter.push({ terms: { id: ids }})
      else
        must_filter.push({term: { id: params[:id] }})
      end
    end

    # Search by public URL
    must_filter.push(term: { url: params[:url] }) if params[:url]

    # Search by name (autocomplete)
    must_filter.push(match_phrase_prefix: { name: params[:name] }) if params[:name]

    # Geo Location Search
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])

    # Elasticsearch DSL Query
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

    client = Elasticsearch::Client.new
    results = client.search index: i, body: search_query
    results["hits"].to_json
  end

  # Get Pharmacies
  def get_pharmacies(i, params)
    # Attribute filters
    must_filter = []

    # Search by single or multiple ids (comma separated)
    if params[:id]
      if params[:id].include? ','
        ids = params[:id].split(",").map { |s| s.to_i }
        must_filter.push({ terms: { id: ids }})
      else
        must_filter.push({term: { id: params[:id] }})
      end
    end

    # Search by public URL
    must_filter.push(term: { url: params[:url] }) if params[:url]

    # Search by name (autocomplete)
    must_filter.push(match_phrase_prefix: { name: params[:name] }) if params[:name]

    # Geo Location Search
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Search by home delivery status
    must_filter.push(term: { home_delivery_status: params[:home_delivery_status] }) if params[:home_delivery_status]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])

    # Elasticsearch DSL Query
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

    client = Elasticsearch::Client.new
    results = client.search index: i, body: search_query
    results["hits"].to_json
  end


  # Filters
  # -----------------------------------
  # Sort filter for provider search
  def sort_filter(sort_order, sort_by, geo_coordinates)
    sort_filter = []
    # Default: sort by name ASC
    sort_by = 'name' if !sort_by || !%w(name visiting_charges geolocation case_file_review_fees online_consultation_fees).include?(sort_by.to_s)
    sort_order = 'asc' if !sort_order || !%w(asc, desc).include?(sort_order.to_s)

    case sort_by
    when 'visiting_charges'
      sort_filter.push(visiting_charges: {order: sort_order})
    when 'name'
      sort_filter.push(name: {order: sort_order})
    when 'geolocation'
      gc = geo_coordinates.split(',').map(&:to_f)
      sort_filter.push({
        _geo_distance: {
          location_coordinates: {
            lat: gc[0],
            lon: gc[1]
          },
          order: sort_order,
          unit: "km"
        }
      })
    when 'case_file_review_fees'
      sort_filter.push("consultation_profile.case_file_review_fees": {order: sort_order})
    when 'online_consultation_fees'
      sort_filter.push("consultation_profile.online_consultation_fees": {order: sort_order})
    end
    sort_filter
  end

  # Filter based on visiting charges
  def visiting_charges_filter(from_charge, to_charge)
    if from_charge and !to_charge
      h = {
        range: {
          visiting_charges: {
            gte: from_charge
          }
        }
      }
    elsif !from_charge and to_charge
      h = {
        range: {
          visiting_charges: {
            lte: to_charge
          }
        }
      }
    else
      h = {
        range: {
          visiting_charges: {
            gte: from_charge,
            lte: to_charge
          }
        }
      }
    end
    return h
  end

  # Filter based on case file review fees
  def case_file_review_charges_filter(from_charge, to_charge)
    if !to_charge
      h = { match: { "consultation_profile.case_file_review_fees": from_charge }}
    else
      h = {
        range: {
          "consultation_profile.case_file_review_fees": {
            gte: from_charge,
            lte: to_charge
          }
        }
      }
    end
    return h
  end

  # Filter based on online consultation fees
  def online_consult_charges_filter(from_charge, to_charge)
    if !to_charge
      h = { match: { "consultation_profile.online_consultation_fees": from_charge }}
    else
      h = {
        range: {
          "consultation_profile.online_consultation_fees": {
            gte: from_charge,
            lte: to_charge
          }
        }
      }
    end
    return h
  end

  # Filter based on Geo Coordinates and Geo Radius
  def geolocation_filter(geo_coordinates, geo_radius)
    geo_radius = "100" if !geo_radius
    h = {
      geo_distance: {
        distance: (geo_radius.to_s + "km"),
        location_coordinates: geo_coordinates.to_s
      }
    }
    h
  end

end
