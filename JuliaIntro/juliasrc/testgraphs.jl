# load packages
using Graphs, GraphPlot, SimpleWeightedGraphs, DelimitedFiles
# read graph
cocycles = readdlm("cocycles.csv", ',', Int)
gw = SimpleWeightedGraph(cocycles[:,1],cocycles[:,2], cocycles[:,3])
display(gw.weights)
# call Dijkstra
println("Run Dijkstra's algorithm from node 1");
ds = dijkstra_shortest_paths(gw,1, gw.weights);
# Results
println("Results:");
println("  Parents:   ",ds.parents)
println("  Distances: ",ds.dists)
gplot(Graph(gw), nodelabel=1:nv(gw), edgelabel=cocycles[:,3])