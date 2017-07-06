require 'sinatra'
require 'sinatra/cross_origin'
require 'elasticsearch'
require 'json'
# require 'byebug'

configure { set :server, :puma }


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

  # Health Problems Search
  get '/health_problems_development' do
    content_type :json
    get_health_problems('health_problems_development', params)
  end

  get '/health_problems_staging' do
    content_type :json
    get_health_problems('health_problems_staging', params)
  end

  get '/health_problems' do
    content_type :json
    get_health_problems('health_problems_production', params)
  end

  # Basic Lab Tests Search
  get '/basic_lab_tests_development' do
    content_type :json
    get_basic_lab_tests('basic_lab_tests_development', params)
  end

  get '/basic_lab_tests_staging' do
    content_type :json
    get_basic_lab_tests('basic_lab_tests_staging', params)
  end

  get '/basic_lab_tests' do
    content_type :json
    get_basic_lab_tests('basic_lab_tests_production', params)
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

  # Hospitals Search
  get '/hospitals_development' do
    content_type :json
    get_hospitals('hospitals_development', params)
  end

  get '/hospitals_staging' do
    content_type :json
    get_hospitals('hospitals_staging', params)
  end

  get '/hospitals' do
    content_type :json
    get_hospitals('hospitals_production', params)
  end

  # Basic Hospital Facilities Search
  get '/basic_facilities_development' do
    content_type :json
    get_basic_hospitals_data('basic_facilities_development', params)
  end

  get '/basic_facilities_staging' do
    content_type :json
    get_basic_hospitals_data('basic_facilities_staging', params)
  end

  get '/basic_facilities' do
    content_type :json
    get_basic_hospitals_data('basic_facilities_production', params)
  end

  # Basic Hospital Specializations Search
  get '/basic_specializations_development' do
    content_type :json
    get_basic_hospitals_data('basic_specializations_development', params)
  end

  get '/basic_specializations_staging' do
    content_type :json
    get_basic_hospitals_data('basic_specializations_staging', params)
  end

  get '/basic_specializations' do
    content_type :json
    get_basic_hospitals_data('basic_specializations_production', params)
  end

  # Basic Hospital Accreditations Search
  get '/basic_accreditations_development' do
    content_type :json
    get_basic_hospitals_data('basic_accreditations_development', params)
  end

  get '/basic_accreditations_staging' do
    content_type :json
    get_basic_hospitals_data('basic_accreditations_staging', params)
  end

  get '/basic_accreditations' do
    content_type :json
    get_basic_hospitals_data('basic_accreditations_production', params)
  end

  # Jobs Search
  get '/jobs_development' do
    content_type :json
    get_jobs('jobs_development', params)
  end

  get '/jobs_staging' do
    content_type :json
    get_jobs('jobs_staging', params)
  end

  get '/jobs' do
    content_type :json
    get_jobs('jobs_production', params)
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
                        bool: {
                          must: must_filter
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

  # Get Health Problems
  def get_health_problems(i, params)
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
    sort_filter = health_problems_sort_filter(params[:sort_order], params[:sort_by])

    # Elasticsearch DSL Query
    search_query =  {
                      query: {
                        bool: {
                          must: must_filter
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

  # Health Problems sort filter
  def health_problems_sort_filter(sort_order, sort_by)
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

  # Get basic lab tests
  def get_basic_lab_tests(i, params)
    # Attribute Filters
    must_filter = []

    if params[:featured]
      params[:id] = '1545,1068,1698,387,784,1017,1073'
    end

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
    sort_filter = basic_lab_tests_sort_filter(params[:sort_order], params[:sort_by])

    # Elasticsearch DSL Query
    search_query =  {
                      query: {
                        bool: {
                          must: must_filter
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

  # Basic Lab Tests sort filter
  def basic_lab_tests_sort_filter(sort_order, sort_by)
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

    # Search by name only
    must_filter.push(match_phrase_prefix: { name: params[:only_name] }) if params[:only_name]

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

    # Doctor Availability Filters
    if params[:open_now] or params[:open_on_days]
      utc_timings_must_filter = []

      # Open Now Filter
      if params[:open_now] and params[:open_now] == "true"
        utc_timings_must_filter += open_now_filter
        current_day = Time.now.utc.strftime('%a')
        params[:open_on_days] = current_day
      end

      # Open on days filter
      if params[:open_on_days]
        open_on_days = params[:open_on_days].split(",")
        utc_timings_must_filter.push(terms: { "utc_timings.day_of_week": open_on_days })
      end

      utc_timings_filter = {
        nested: {
          path: "utc_timings",
          query: {
            bool: {
              must: utc_timings_must_filter
            }
          }
        }
      }

      must_filter.push utc_timings_filter
    end

    # Online Consultation Availability Filters - Next Available Online
    if params[:next_available_online] and params[:next_available_online] == "true"
      current_day = Time.now.utc.strftime('%a')
      current_hour = Time.now.utc.strftime('%H').to_i

      current_hour = 00 if current_hour == 23
      start_hour = current_hour + 1

      next_hour = start_hour
      next_hour = 00 if next_hour == 23
      next_hour = next_hour + 1

      slots = []
      slots[0] = Time.parse('2000-01-01 ' + start_hour.to_s + ':00:00 +0000').utc.iso8601
      slots[1] = Time.parse('2000-01-01 ' + start_hour.to_s + ':30:00 +0000').utc.iso8601
      slots[2] = Time.parse('2000-01-01 ' + next_hour.to_s + ':00:00 +0000').utc.iso8601
      slots[3] = Time.parse('2000-01-01 ' + next_hour.to_s + ':30:00 +0000').utc.iso8601

      days = []
      4.times do |count|
        if (count == 0 and start_hour == 0) or (count == 2 and next_hour == 0)
          case current_day
          when "Mon"
            current_day = "Tue"
          when "Tue"
            current_day = "Wed"
          when "Wed"
            current_day = "Thu"
          when "Thu"
            current_day = "Fri"
          when "Fri"
            current_day = "Sat"
          when "Sat"
            current_day = "Sun"
          when "Sun"
            current_day = "Mon"
          end
        end
        days[count] = current_day

        nested_filter = {
          nested: {
            path: "online_utc_consultation_schedules",
            query: {
              bool: {
                must: available_now_filter(days[count], slots[count])
              }
            }
          }
        }

        should_filter.push nested_filter
      end
    end

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
                        bool: {
                          must: [
                            {
                              bool: {
                                must: must_filter
                              }
                            },
                            {
                              bool: {
                                should: should_filter
                              }
                            }
                          ]
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

    # Search by basic_lab_test_id
    if params[:basic_lab_test_id]
      nested_filter = {
        nested: {
          path: "lab_tests",
          query: {
            bool: {
              must: basic_lab_test_filter(params[:basic_lab_test_id])
            }
          }
        }
      }
      must_filter.push(nested_filter)
      sort_filter = lab_sort_by_test_price_filter(params[:sort_order], params[:basic_lab_test_id])
    else
      # Sort filters
      sort_filter = sort_filter(params[:sort_order], params[:sort_by], params[:geo_coordinates])
    end

    # Geo Location Search
    must_filter.push(geolocation_filter(params[:geo_coordinates], params[:geo_radius])) if params[:geo_coordinates]

    # Page filters
    perpage = params[:perpage] ? params[:perpage].to_i : 10
    page = params[:page] ? ((params[:page].to_i - 1) * perpage.to_i) : 0

    # Elasticsearch DSL Query
    search_query =  {
                      query: {
                        bool: {
                          must: must_filter
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
                        bool: {
                          must: must_filter
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

  # Get Hospitals
  def get_hospitals(i, params)
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

    # Search by name (autocomplete)
    must_filter.push(match_phrase_prefix: { name: params[:name] }) if params[:name]

    # Search by single or multiple specializations (comma separated)
    if params[:main_specialization]
      if params[:main_specialization].include? ','
        main_specializations = params[:main_specialization].split(",").map { |s| s.to_s }
        main_specializations.each do |spc|
          should_filter.push(match_phrase_prefix: { specialization: spc })
        end
      else
        must_filter.push(match_phrase_prefix: { specialization: params[:main_specialization] })
      end
    end

    # Hospital Availability Filters
    if params[:open_now] or params[:open_on_days]
      utc_timings_must_filter = []

      # Open Now Filter
      if params[:open_now] and params[:open_now] == "true"
        utc_timings_must_filter += open_now_filter
        current_day = Time.now.utc.strftime('%a')
        params[:open_on_days] = current_day
      end

      # Open on days filter
      if params[:open_on_days]
        open_on_days = params[:open_on_days].split(",")
        utc_timings_must_filter.push(terms: { "utc_timings.day_of_week": open_on_days })
      end

      utc_timings_filter = {
        nested: {
          path: "utc_timings",
          query: {
            bool: {
              must: utc_timings_must_filter
            }
          }
        }
      }

      must_filter.push utc_timings_filter
    end

    # Search by city
    must_filter.push(match: { city: params[:city] }) if params[:city]

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
                        bool: {
                          must: must_filter
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

  # Get Basic Hospitals Data
  def get_basic_hospitals_data(i, params)
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
    sort_filter = basic_hospitals_data_sort_filter(params[:sort_order], params[:sort_by])

    # Elasticsearch DSL Query
    search_query =  {
                      query: {
                        bool: {
                          must: must_filter
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

  # Get Jobs
  def get_jobs(i, params)
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
    sort_filter = jobs_sort_filter(params[:sort_order], params[:sort_by])

    # Elasticsearch DSL Query
    search_query =  {
                      query: {
                        bool: {
                          must: must_filter
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

  def lab_sort_by_test_price_filter(sort_order, basic_lab_test_id)
    sort_filter = []
    sort_order = 'asc' if !sort_order || !%w(asc, desc).include?(sort_order.to_s)

    sort_filter.push({
      "lab_tests.price": {
        "order": sort_order,
        "nested_path": "lab_tests",
        "nested_filter": {
          "term": {
            "lab_tests.basic_lab_test_id": basic_lab_test_id
          }
        }
      }
    })
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

  # Open Now filter
  def open_now_filter
    current_time = Time.parse('2000-01-01 ' + Time.now.strftime('%H:%M:ss')).utc.iso8601

    [
      {
        range: {
          "utc_timings.start_time": { "lte": current_time }
        }
      },
      {
        range: {
          "utc_timings.end_time": { "gte": current_time }
        }
      }
    ]
  end

  # Available Now filter
  def available_now_filter(day, slot)
    available_on_days = day.split(",")

    [
      {
        terms: {
          "online_utc_consultation_schedules.day_of_week": available_on_days
        }
      },
      {
        range: {
          "online_utc_consultation_schedules.start_time": { "lte": slot }
        }
      },
      {
        range: {
          "online_utc_consultation_schedules.end_time": { "gte": slot }
        }
      }
    ]
  end

  def basic_lab_test_filter(basic_lab_test_id)
    { term: { "lab_tests.basic_lab_test_id": basic_lab_test_id } }
  end

  def basic_hospitals_data_sort_filter(sort_order, sort_by)
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

  # Jobs sort filter
  def jobs_sort_filter(sort_order, sort_by)
    sort_filter = []
    # Default: sort by created_at ASC
    sort_by = 'created_at' if !sort_by || !%w(id, created_at).include?(sort_by.to_s)
    sort_order = 'desc' if !sort_order || !%w(asc, desc).include?(sort_order.to_s)

    case sort_by
    when 'id'
      sort_filter.push(id: { order: sort_order })
    when 'created_at'
      sort_filter.push(created_at: { order: sort_order })
    end
    sort_filter
  end
end
