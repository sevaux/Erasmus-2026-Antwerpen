using DataFrames, CSV, Statistics
# download the file from https://www.kaggle.com/datasets/sudalairajkumar/daily-temperature-of-major-cities
@time df = DataFrame(CSV.File("city_temperature.csv"))
temperatures = df.AvgTemperature

"""
    toCelsius(x)

Convert x from Fahrenheit to Celsius.

# Example
```julia-repl
julia> toCelsius(77)
25.0
```
"""
function toCelsius(x)
    y = (x-32)*5/9
    return y
end

# show the help in the REPL ?toCelsius
toCelsius(mean(temperatures))

using PlotlyJS

unique(df[df.City .== "Paris",:].Year)
list_years = [1995, 2005, 2015]
Tavg = [mean(filter(x -> x.City == "Paris" && x.Year == year && x.Month == month, df)[:,"AvgTemperature"]) for year in list_years, month in 1:12]
    list_traces = AbstractTrace[]
    for i in eachindex(list_years)
        trace = scatter(x=[1:12;], y=Tavg[i,:], name=list_years[i])
        push!(list_traces, trace)
    end
plot(list_traces)
