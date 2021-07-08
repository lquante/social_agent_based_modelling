# primitive test script for job submission
using DrWatson
@quickactivate "Social Agent Based Modelling"
using CSV
using Random
using DataFrames
df = DataFrame(rand(10,10),:auto)
CSV.write("Test.csv", df)
