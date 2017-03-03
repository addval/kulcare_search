require 'sinatra'
require 'elasticsearch'
require 'json'
require 'byebug'

class KulcareSearch < Sinatra::Base
  set :bind, '0.0.0.0'

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

  private

  # Get Medicines
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

    client = Elasticsearch::Client.new
    results = client.search index: i, body: search_query
    results["hits"].to_json
  end

  # def medicines_sort_filter(sort_order, sort_by)
  #   sort_filter = []
  #   sort_by = 'name' if !sort_by || !%w(id, name).include?(sort_by.to_s)
  #   sort_order = 'asc' if !sort_order || !%w(asc, desc).include?(sort_order.to_s)

  #   case sort_by
  #   when 'id'
  #     sort_filter.push(id: { order: sort_order })
  #   when 'name'
  #     sort_filter.push(name: { order: sort_order })
  #   end
  #   sort_filter
  # end

  # Get Doctors
  def get_doctors(i, params)
    # Attribute filters
    must_filter = []
    must_filter.push(match: { id: params[:id] }) if params[:id]
    must_filter.push(match_phrase: { name: params[:name] }) if params[:name]
    must_filter.push(match: { speciality: params[:main_speciality] }) if params[:main_speciality]
    must_filter.push(match: { city: params[:city] }) if params[:city]
    must_filter.push(
      visiting_charges_filter(params[:visiting_charges_min], params[:visiting_charges_max])
    ) if params[:visiting_charges_min]
    must_filter.push(
      case_file_review_charges_filter(params[:case_file_review_fees_min], params[:case_file_review_fees_max])
    ) if params[:case_file_review_fees_min]
    must_filter.push(
      online_consult_charges_filter(params[:online_consultation_fees_min], params[:online_consultation_fees_max])
    ) if params[:online_consultation_fees_min]
    must_filter.push(
      term: { "consultation_profile.case_file_review_availability": params[:case_file_review_availability] }
    ) if params[:case_file_review_availability]
    must_filter.push(
      term: { "consultation_profile.online_consultation_availability": params[:online_consultation_availability] }
    ) if params[:online_consultation_availability]
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])

    # Query based on multiple conditions
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

  # Get Labs
  def get_labs(i, params)
    # Attribute filters
    must_filter = []
    must_filter.push(match: { id: params[:id] }) if params[:id]
    must_filter.push(match_phrase: { name: params[:name] }) if params[:name]
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])

    # Query based on multiple conditions
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
    must_filter.push(match: { id: params[:id] }) if params[:id]
    must_filter.push(match_phrase: { name: params[:name] }) if params[:name]
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Sort filters
    sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])

    # Query based on multiple conditions
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
  def sort_filter(sort_order, sort_by, geo_coordinates)
    sort_filter = []
    sort_by = 'name' if !sort_by || !%w(name visiting_charges geolocation).include?(sort_by.to_s)
    sort_order = 'asc' if !sort_order || !%w(asc, desc).include?(sort_order.to_s)

    case sort_by
    when 'visiting_charges'
      sort_filter.push(visiting_charges: {order: sort_order})
    when 'name'
      sort_filter.push(name: {order: sort_order})
    when 'geolocation'
      sort_filter.push({
        _geo_distance: {
          location_coordinates: geo_coordinates.split(',').map(&:to_i),
          order: sort_order,
          unit: "km"
        }
      })
    end
    sort_filter
  end

  # Create filter based on visiting charges
  def visiting_charges_filter(from_charge, to_charge)
    if !to_charge
      h = { match: { visiting_charges: from_charge }}
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

  # Create filter based on visiting charges
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

  # Create filter based on visiting charges
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
