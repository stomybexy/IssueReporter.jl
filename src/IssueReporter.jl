module IssueReporter

using Pkg, GitHub, URIParser, Documenter, DocStringExtensions


function generalregistrypath()::String
    for path in DEPOT_PATH 
        depot = joinpath(path, "registries", "General")
        if isdir(depot)
            return depot
        end
    end

    ""
end

function generalregistry()::Base.ValueIterator{Dict{String,Any}}
    registrypath = generalregistrypath()
    if !isempty(registrypath)
        (joinpath(registrypath, "Registry.toml") |> Pkg.TOML.parsefile)["packages"] |> values
    else
        Dict{String,Any}() |> values
    end

end

function searchregistry(pkgname::String)::Dict{String,Any}
    for item in generalregistry()
        item["name"] == pkgname && return item
    end

    Dict{String,Any}()
end

"""
 
$(SIGNATURES)

Takes the name of a registered Julia package and returns the associated repo git URL. 
 
# Examples 
```julia-repl 
julia> IssueReporter.packageuri("IssueReporter") 
"git://github.com/essenciary/IssueReporter.jl.git" 
``` 
"""
function packageuri(pkgname::String)::String
    package = searchregistry(pkgname)
    isempty(package) && return ""
    get(joinpath(generalregistrypath(), package["path"], "Package.toml") |> Pkg.TOML.parsefile, "repo", "")
end

function loadtoken()
    if ! haskey(ENV, "GITHUB_ACCESS_TOKEN")
        secretpath = joinpath(@__DIR__, "secrets.jl")
        if(isfile(secretpath)) 
            include(secretpath)
        end
    end
end

"""
 
$(SIGNATURES) 
 
Checks if the required GitHub authentication token is defined. 
"""
function tokenisdefined()::Bool
    return haskey(ENV, "GITHUB_ACCESS_TOKEN") 
end

"""
$(SIGNATURES)

Returns the configured GitHub authentication token, if defined -- or throws an error otherwise.
"""
function token()
    tokenisdefined() && return ENV["GITHUB_ACCESS_TOKEN"]
    error("""ENV["GITHUB_ACCESS_TOKEN"] is not set -- 
    please make sure it's passed as a command line argument or defined in the `secrets.jl` file.""")
end

"""
$(SIGNATURES)

Performs GitHub authentication and returns the OAuth2 object, required by further GitHub API calls.
"""
function githubauth()
    loadtoken()
    token() |> GitHub.authenticate
end

"""
 
$(SIGNATURES) 
 
Converts a registered Julia package name to the corresponding GitHub "username/repo_name" string. 
 
# Examples 
```jldoctest 
julia> using IssueReporter; IssueReporter.repoid("IssueReporter") 
"essenciary/IssueReporter.jl" 
``` 
"""
function repoid(pkgname::String)::String
    pkgurl = packageuri(pkgname) |> URIParser.parse_url
    repoinfo = endswith(pkgurl.path, ".git") ? 
                replace(pkgurl.path, r".git$" => "") :
                pkgurl.path
    repoinfo[2:end]
end

"""
$(SIGNATURES)

Creates a new GitHub issue with the title `title` and the content `body` onto the repo corresponding to the registered package called `pack-age_name`.
"""
function report(pkgname::String, title::String, body::String)
    GitHub.create_issue(repoid(pkgname), auth = githubauth(), params = Dict(:title => title, :body => body))
end

end # module
