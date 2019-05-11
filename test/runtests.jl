using IssueReporter
using Test, URIParser, GitHub

@testset "Basic features" begin
    @testset "Looking up an existing package returns a proper repo URI" begin
        @test IssueReporter.packageuri("DataFrames") |> URIParser.isvalid
    end
end

@testset "Interacting with the registry" begin
    @testset "The General registry is accessible" begin
        @test IssueReporter.generalregistrypath() |> Base.Filesystem.isdir
    end
end

@testset "Github integration" begin
    delete!(ENV, "GITHUB_ACCESS_TOKEN")

    @testset "An undefined token should return false" begin
        @test ! IssueReporter.tokenisdefined()
    end

    @testset "Attempting to access a token that is not set should error" begin
        @test_throws ErrorException IssueReporter.token()
    end

    #setup a mock token
    ENV["GITHUB_ACCESS_TOKEN"] = "1234"

    @testset "token is defined" begin
        @test IssueReporter.tokenisdefined()
    end

    @testset "A valid token is a non empty string and has the set value" begin
        token = IssueReporter.token()
        @test !isempty(token) && isa(token, String)
        @test token == "1234"
    end
end

@testset "Adding Github issues" begin
    delete!(ENV, "GITHUB_ACCESS_TOKEN")

    @testset "Successful authentication should return a GitHub.OAuth2 instance" begin
        @test isa(IssueReporter.githubauth(), GitHub.OAuth2)
    end

    @testset "Converting package name to Github id" begin
        @test IssueReporter.repoid("IssueReporter") == "essenciary/IssueReporter.jl"
    end

    # @testset "Submitting an issue should result in GitHub.Issue object" begin
    #     @test isa(
    #             IssueReporter.report("IssueReporter", "I found a bug", "Here is how you can reproduce the problem: ..."),
    #             GitHub.Issue
    #         )
    # end
end