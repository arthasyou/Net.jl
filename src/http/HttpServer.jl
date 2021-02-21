using HTTP
using JSON2
# CORS headers that show what kinds of complex requests are allowed to API
headers = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Headers" => "*",
    "Access-Control-Allow-Methods" => "POST, GET, OPTIONS"
]

#=
JSONHandler minimizes code by automatically converting the request body
to JSON to pass to the other service functions automatically. JSONHandler
recieves the body of the response from the other service funtions and sends
back a success response code
=#
function JSONHandler(req::HTTP.Request)
    # first check if there's any request body
    body = IOBuffer(HTTP.payload(req))
    if eof(body)
        # no request body
        response_body = handle(ANIMAL_ROUTER, req)
    else
        # there's a body, so pass it on to the handler we dispatch to
        response_body = handle(ANIMAL_ROUTER, req)
    end
    return HTTP.Response(200, JSON2.write(response_body))
end

#= CorsHandler: handles preflight request with the OPTIONS flag
If a request was recieved with the correct headers, then a response will be
sent back with a 200 code, if the correct headers were not specified in the request,
then a CORS error will be recieved on the client side

Since each request passes throught the CORS Handler, then if the request is
not a preflight request, it will simply go to the JSONHandler to be passed to the
correct service function =#
function CorsHandler(req)
    if HTTP.hasheader(req, "OPTIONS")
        return HTTP.Response(200, headers = headers)
    else
        return JSONHandler(req)
    end
end

mutable struct Animal
    id::Int
    userId::Base.UUID
    type::String
    name::String
end

# use a plain `Dict` as a "data store"
const ANIMALS = Dict{Int, Animal}()
const NEXT_ID = Ref(0)
function getNextId()
    id = NEXT_ID[]
    NEXT_ID[] += 1
    return id
end

# "service" functions to actually do the work
function createAnimal(req::HTTP.Request)
    animal = JSON2.read(IOBuffer(HTTP.payload(req)), Animal)
    animal.id = getNextId()
    ANIMALS[animal.id] = animal
    return HTTP.Response(200, JSON2.write(animal))
end

function getAnimal(req::HTTP.Request)
    return HTTP.Response(200, "ok")
end

function updateAnimal(req::HTTP.Request)
    animal = JSON2.read(IOBuffer(HTTP.payload(req)), Animal)
    ANIMALS[animal.id] = animal
    return HTTP.Response(200, JSON2.write(animal))
end

function deleteAnimal(req::HTTP.Request)
    animalId = HTTP.URIs.splitpath(req.target)[5] # /api/zoo/v1/animals/10, get 10
    delete!(ANIMALS, parse(Int, animal.id))
    return HTTP.Response(200)
end

# define REST endpoints to dispatch to "service" functions
const ANIMAL_ROUTER = HTTP.Router()

HTTP.@register(ANIMAL_ROUTER, "POST", "/api/zoo/v1/animals", createAnimal)
# note the use of `*` to capture the path segment "variable" animal id
HTTP.@register(ANIMAL_ROUTER, "GET", "/api/zoo/v1/animals", getAnimal)
HTTP.@register(ANIMAL_ROUTER, "PUT", "/api/zoo/v1/animals", updateAnimal)
HTTP.@register(ANIMAL_ROUTER, "DELETE", "/api/zoo/v1/animals/*", deleteAnimal)


HTTP.serve(CorsHandler, "0.0.0.0", 8080)
