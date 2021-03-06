require 'sinatra'
require "sinatra/reloader"
require_relative "sir_model_api_adapter"
require_relative "rest_countries_api_adapter"
require_relative "coronavirus_tracker_api_adapter"
require "pry"

get "/v1/sir_model" do
    sir_model_api_adapter = SirModelApiAdapter.new
    rest_countries_api_adapter = RestCountriesApiAdapter.new("https://restcountries.eu/rest/v2/name/", params["country"])
    coronavirus_tracker_api_adapter = CoronavirusTrackerApiAdapter.new("https://coronavirus-tracker-api.herokuapp.com/v2/", rest_countries_api_adapter.country_code)

    resistant = coronavirus_tracker_api_adapter.recovered + coronavirus_tracker_api_adapter.deaths
    susceptible = rest_countries_api_adapter.country_population - resistant - coronavirus_tracker_api_adapter.confirmed

    model = sir_model_api_adapter.build_model(
        eons: params["eons"].to_i,
        infected: coronavirus_tracker_api_adapter.confirmed,
        susceptible: susceptible,
        resistant: resistant,
        rate_si: params["rateSi"].to_f,
        rate_ir: params["rateIr"].to_f,
        population: rest_countries_api_adapter.country_population
    )   

    content_type :json
    # https://nifty-fermi-3c4ae9.netlify.com/
    # todo: this is bad!  we want to whitelist, not just let everything in
    # make sure to fix it l8r!
    headers 'Access-Control-Allow-Origin' => '*'
    { country: params["country"], population: rest_countries_api_adapter.country_population, points: model["results"] }.to_json

end