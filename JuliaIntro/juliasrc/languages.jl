using PlotlyJS, CSV, DataFrames # loading packages]
df = DataFrame(CSV.File("languages.csv")) # reading file
#plot(bar(df,y=:Languages, x=:Perf, orientation='h'))
plot(bar(sort(df,[:Perf],rev=true),y=:Languages, x=:Perf,orientation='h'),Layout(xaxis=attr(showticklabels=false)))

