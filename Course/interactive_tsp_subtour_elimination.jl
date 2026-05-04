###############################################################
# Interactive TSP subtour elimination with JuMP + HiGHS
#
# This file is standalone.
# It solves the Traveling Salesman Problem using a MILP model.
# Subtour elimination constraints are added interactively.
#
# -------------------------------------------------------------
# Installation, once in Julia:
#
#     import Pkg
#     Pkg.add(["JuMP", "HiGHS", "Plots"])
#
# -------------------------------------------------------------
# Usage:
#
#     include("interactive_tsp_subtour_elimination.jl")
#
#     cities, D = generate_tsp_instance(12; seed=1)
#     model, x, arcs, opt_value = interactive_subtour_elimination(D, cities)
#
# The program will:
#   1. solve the assignment relaxation of the TSP,
#   2. display the current solution,
#   3. detect whether the solution is a valid TSP tour,
#   4. if not, ask you to enter one node in a subtour,
#   5. add the corresponding subtour elimination constraint,
#   6. solve again,
#   7. repeat until a valid optimal TSP tour is obtained.
###############################################################

using JuMP
using HiGHS
using Plots
using Random

###############################################################
# 1. Instance generation
###############################################################

function generate_tsp_instance(n::Int; seed::Int=1)
    Random.seed!(seed)
    cities = rand(1:100, n, 2)
    D = compute_distance_matrix(cities)
    return cities, D
end

function compute_distance_matrix(cities)
    n = size(cities, 1)
    D = zeros(n, n)

    for i in 1:n
        for j in i+1:n
            D[i,j] = D[j,i] = sqrt((cities[i, 1] - cities[j, 1])^2 +
                           (cities[i, 2] - cities[j, 2])^2)
        end
    end

    return D
end

###############################################################
# 2. MILP model without subtour elimination constraints
###############################################################

function build_tsp_assignment_model(D)
    n = size(D, 1)

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, x[1:n, 1:n], Bin)

    @objective(model, Min,
        sum(D[i, j] * x[i, j] for i in 1:n, j in 1:n)
    )

    # Each node has exactly one outgoing arc.
    @constraint(model, [i in 1:n],
        sum(x[i, j] for j in 1:n if j != i) == 1
    )

    # Each node has exactly one incoming arc.
    @constraint(model, [j in 1:n],
        sum(x[i, j] for i in 1:n if i != j) == 1
    )

    # No self-loop.
    @constraint(model, [i in 1:n], x[i, i] == 0)

    return model, x
end

###############################################################
# 3. Extract and analyze the current solution
###############################################################

function selected_arcs(x)
    n = size(x, 1)
    arcs = Tuple{Int, Int}[]

    for i in 1:n
        for j in 1:n
            if value(x[i, j]) > 0.5
                push!(arcs, (i, j))
            end
        end
    end

    return arcs
end

function find_subtours(arcs, n::Int)
    successor = Dict(i => j for (i, j) in arcs)
    unvisited = Set(1:n)
    subtours = Vector{Vector{Int}}()

    while !isempty(unvisited)
        start = first(unvisited)
        current = start
        tour = Int[]

        while current in unvisited
            push!(tour, current)
            delete!(unvisited, current)
            current = successor[current]
        end

        push!(subtours, tour)
    end

    return subtours
end

function subtour_containing_node(arcs, node::Int)
    successor = Dict(i => j for (i, j) in arcs)

    if !haskey(successor, node)
        error("Node $node is not present in the current solution.")
    end

    S = Int[]
    current = node

    while !(current in S)
        push!(S, current)
        current = successor[current]
    end

    return S
end

###############################################################
# 4. Add a subtour elimination constraint
###############################################################

function add_subtour_elimination_constraint!(model, x, S)
    @constraint(model,
        sum(x[i, j] for i in S, j in S if i != j) <= length(S) - 1
    )
end

function add_subtour_constraint_from_node!(model, x, arcs, node::Int)
    n = size(x, 1)
    S = subtour_containing_node(arcs, node)

    if length(S) == n
        println("Node $node belongs to the complete tour. No constraint is needed.")
        return S, false
    end

    add_subtour_elimination_constraint!(model, x, S)
    return S, true
end

###############################################################
# 5. Visualization
###############################################################

function plot_arcs(cities, arcs; title_str="Current TSP solution")
    xcoord = cities[:, 1]
    ycoord = cities[:, 2]

    p = scatter(
        xcoord,
        ycoord,
        label=false,
        title=title_str,
        aspect_ratio=:equal,
        legend=false
    )

    for (i, j) in arcs
        plot!(
            p,
            [xcoord[i], xcoord[j]],
            [ycoord[i], ycoord[j]],
            arrow=true,
            label=false
        )
    end

    for i in 1:length(xcoord)
        annotate!(p, xcoord[i], ycoord[i]-2, text(string(i), 8, :black))
    end

    return p
end

###############################################################
# 6. Interactive subtour elimination procedure
###############################################################

function interactive_subtour_elimination(D, cities)
    n = size(D, 1)
    model, x = build_tsp_assignment_model(D)

    iteration = 0

    while true
        iteration += 1

        println()
        println("================================================")
        println("Iteration $iteration")
        println("Solving current model...")
        println("================================================")

        optimize!(model)

        status = termination_status(model)
        if status != MOI.OPTIMAL
            error("The solver did not find an optimal solution. Status: $status")
        end

        arcs = selected_arcs(x)
        subtours = find_subtours(arcs, n)
        obj = objective_value(model)

        println("Objective value: ", obj)
        println("Selected arcs: ", arcs)
        println("Detected subtours:")
        for S in subtours
            println("  ", S)
        end

        display(plot_arcs(cities, arcs; title_str="Iteration $iteration"))

        if length(subtours) == 1 && length(subtours[1]) == n
            println()
            println("The current solution is a valid TSP tour.")
            println("Since all subtour elimination constraints added so far are valid,")
            println("this tour is optimal for the TSP.")
            println("Optimal value: ", obj)
            return model, x, arcs, obj
        end

        println()
        println("The current solution contains subtours.")
        println("Enter one node belonging to the subtour you want to eliminate.")
        println("For example, if you see subtour [2, 7, 5], you may enter 2, 7, or 5.")
        print("Node = ")

        input = readline()
        node = try
            parse(Int, input)
        catch
            println("Invalid input. Please enter an integer node index.")
            continue
        end

        if node < 1 || node > n
            println("Invalid node. Please enter an integer between 1 and $n.")
            continue
        end

        S, added = add_subtour_constraint_from_node!(model, x, arcs, node)

        if added
            println("Added subtour elimination constraint for S = ", S)
            println("Constraint: sum(x[i,j] for i,j in S, i != j) <= ", length(S) - 1)
        else
            println("No constraint was added.")
        end
    end
end

###############################################################
# 7. Optional automatic version for comparison
###############################################################

function automatic_subtour_elimination(D, cities; display_each_iteration::Bool=true)
    n = size(D, 1)
    model, x = build_tsp_assignment_model(D)
    iteration = 0

    while true
        iteration += 1
        optimize!(model)

        status = termination_status(model)
        if status != MOI.OPTIMAL
            error("The solver did not find an optimal solution. Status: $status")
        end

        arcs = selected_arcs(x)
        subtours = find_subtours(arcs, n)
        obj = objective_value(model)

        println()
        println("Iteration $iteration")
        println("Objective value: ", obj)
        println("Detected subtours: ", subtours)

        if display_each_iteration
            display(plot_arcs(cities, arcs; title_str="Automatic iteration $iteration"))
        end

        if length(subtours) == 1 && length(subtours[1]) == n
            println("Optimal TSP tour found.")
            return model, x, arcs, obj
        end

        for S in subtours
            if length(S) < n
                add_subtour_elimination_constraint!(model, x, S)
            end
        end
    end
end

###############################################################
# 8. Demo functions
###############################################################

function demo_interactive(; n::Int=12, seed::Int=1)
    cities, D = generate_tsp_instance(n; seed=seed)
    model, x, arcs, opt_value = interactive_subtour_elimination(D, cities)
    return cities, D, model, x, arcs, opt_value
end

function demo_automatic(; n::Int=12, seed::Int=1)
    cities, D = generate_tsp_instance(n; seed=seed)
    model, x, arcs, opt_value = automatic_subtour_elimination(D, cities)
    return cities, D, model, x, arcs, opt_value
end
