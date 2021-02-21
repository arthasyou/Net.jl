module ANIMAL_ROUTER

using HTTP
# modified Animal struct to associate with specific user
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

# **simplified** "service" functions
function createAnimal(req::HTTP.Request, animal)
    animal.id = getNextId()
    ANIMALS[animal.id] = animal
    return animal
end

function getAnimal(req::HTTP.Request)
    animalId = HTTP.URIs.splitpath(req.target)[5] # /api/zoo/v1/animals/10, get 10
    return ANIMALS[animalId]
end

function updateAnimal(req::HTTP.Request, animal)
    ANIMALS[animal.id] = animal
    return animal
end

function deleteAnimal(req::HTTP.Request)
    animalId = HTTP.URIs.splitpath(req.target)[5] # /api/zoo/v1/animals/10, get 10
    delete!(ANIMALS, animal.id)
    return ""
end

end  # module ANIMAL_ROUTER
