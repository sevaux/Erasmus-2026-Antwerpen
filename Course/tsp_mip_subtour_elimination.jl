###############################################################
# TSP by Mathematical Programming with Subtour Elimination
#
# This file is designed for a teaching session.
# It contains:
#   1. Instance generation
#   2. Visualization helpers
#   3. TSP MIP model without subtour elimination constraints
#   4. Manual subtour elimination loop helpers
#   5. Automatic subtour elimination procedure
#
# Required Julia packages:
#   JuMP, HiGHS, Plots, Random
###############################################################

using Random
using JuMP
using HiGHS
using Plots

###############################################################
# PART 0 — Instance generation
###############################################################

"""
    generate_cities(n; seed=1)

Generate `n` random cities in the unit square [0,1] x [0,1].
"""
function generate_cities(n; seed=1)
    Random.seed!(seed)
    return rand(1:100,n, 2)
end

"""
    compute_distance_matrix(cities)

Compute the Euclidean distance matrix between all cities.
"""
function compute_distance_matrix(cities)
    n = size(cities, 1)
    D = zeros(n, n)

    for i in 1:n
        for j in 1:n
            D[i, j] = sqrt(sum((cities[i, :] .- cities[j, :]).^2))
        end
    end

    return D
end

###############################################################
# PART 1 — Visualization helpers
###############################################################

"""
    plot_arcs(cities, arcs; title_str="TSP solution")

Plot a solution represented as directed arcs `(i,j)`.
"""
function plot_arcs(cities, arcs; title_str="TSP solution")
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

"""
    plot_subtours(cities, subtours; title_str="Subtours")

Plot subtours represented as vectors of city indices.
"""
function plot_subtours(cities, subtours; title_str="Subtours")
    arcs = Tuple{Int, Int}[]

    for S in subtours
        for k in 1:length(S)
            i = S[k]
            j = S[k == length(S) ? 1 : k + 1]
            push!(arcs, (i, j))
        end
    end

    return plot_arcs(cities, arcs, title_str=title_str)
end

###############################################################
# PART 2 — Mathematical programming model
###############################################################

"""
    build_tsp_model(D)

Build the assignment formulation of the TSP without subtour elimination constraints.

Variables:
    x[i,j] = 1 if arc (i,j) is selected, 0 otherwise.

Constraints:
    - exactly one outgoing arc from each city
    - exactly one incoming arc to each city
    - no self-loop

This formulation is not sufficient to define a single Hamiltonian cycle.
It may produce several subtours.
"""
function build_tsp_model(D)
    n = size(D, 1)

    model = Model(HiGHS.Optimizer)
    set_silent(model)

    @variable(model, x[1:n, 1:n], Bin)

    @objective(model, Min, sum(D[i, j] * x[i, j] for i in 1:n, j in 1:n))

    @constraint(model, [i in 1:n], sum(x[i, j] for j in 1:n if j != i) == 1)
    @constraint(model, [j in 1:n], sum(x[i, j] for i in 1:n if i != j) == 1)
    @constraint(model, [i in 1:n], x[i, i] == 0)

    return model, x
end

###############################################################
# PART 3 — Extract and analyze solutions
###############################################################

"""
    selected_arcs(x)

Extract selected arcs from the binary decision variables.
"""
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

"""
    find_subtours(arcs, n)

Find all cycles in the current solution.
Because of the assignment constraints, each city has exactly one successor.
"""
function find_subtours(arcs, n)
    successor = Dict(i => j for (i, j) in arcs)
    unvisited = Set(1:n)
    subtours = Vector{Vector{Int}}()

    while !isempty(unvisited)
        start = first(unvisited)
        tour = Int[]
        current = start

        while current in unvisited
            push!(tour, current)
            delete!(unvisited, current)
            current = successor[current]
        end

        push!(subtours, tour)
    end

    return subtours
end

"""
    add_subtour_constraint!(model, x, S)

Add the subtour elimination constraint associated with subset S:

    sum_{i in S, j in S, i != j} x[i,j] <= |S| - 1
"""
function add_subtour_constraint!(model, x, S)
    @constraint(model, sum(x[i, j] for i in S, j in S if i != j) <= length(S) - 1)
end

function add_subtour_constraint_from_node!(model, x, arcs, node)
    n = size(x, 1)

    successor = Dict(i => j for (i, j) in arcs)

    if !haskey(successor, node)
        error("Node $node is not in the current solution arcs.")
    end

    S = Int[]
    current = node

    while !(current in S)
        push!(S, current)
        current = successor[current]
    end

    if length(S) == n
        error("Node $node belongs to the full tour. No subtour elimination constraint is needed.")
    end

    @constraint(model, sum(x[i, j] for i in S, j in S if i != j) <= length(S) - 1)

    return S
end

###############################################################
# PART 4 — Manual subtour elimination
###############################################################

"""
    solve_relaxed_assignment(D; verbose=true)

Solve the TSP assignment formulation without subtour elimination constraints.
Return the model, the variables, selected arcs and detected subtours.
"""
function solve_relaxed_assignment(D; verbose=true)
    n = size(D, 1)
    model, x = build_tsp_model(D)

    optimize!(model)

    arcs = selected_arcs(x)
    subtours = find_subtours(arcs, n)

    if verbose
        println("Objective value = ", objective_value(model))
        println("Number of subtours = ", length(subtours))
        println("Subtours = ", subtours)
    end

    return model, x, arcs, subtours
end

"""
    solve_again_after_adding_first_subtour!(model, x, n; verbose=true)

Pedagogical helper:
    1. detect subtours in the current solution,
    2. add the first violated subtour constraint,
    3. solve again.

This function can be called repeatedly in class.
"""
function solve_again_after_adding_first_subtour!(model, x, n; verbose=true)
    arcs = selected_arcs(x)
    subtours = find_subtours(arcs, n)

    if length(subtours) == 1
        println("The current solution is already a complete TSP tour.")
        return arcs, subtours
    end

    # Choose the first strict subtour.
    S = first(S for S in subtours if length(S) < n)

    if verbose
        println("Adding subtour elimination constraint for S = ", S)
    end

    add_subtour_constraint!(model, x, S)
    optimize!(model)

    arcs = selected_arcs(x)
    subtours = find_subtours(arcs, n)

    if verbose
        println("New objective value = ", objective_value(model))
        println("Number of subtours = ", length(subtours))
        println("Subtours = ", subtours)
    end

    return arcs, subtours
end

###############################################################
# PART 5 — Automatic subtour elimination loop
###############################################################

"""
    solve_tsp_with_subtour_elimination(D; verbose=true)

Solve the TSP by iteratively adding subtour elimination constraints.
At each iteration:
    1. solve the current MIP,
    2. detect subtours,
    3. if there is more than one subtour, add the associated constraints,
    4. repeat.
"""
function solve_tsp_with_subtour_elimination(D; verbose=true)
    n = size(D, 1)
    model, x = build_tsp_model(D)

    iteration = 0

    while true
        iteration += 1
        optimize!(model)

        arcs = selected_arcs(x)
        subtours = find_subtours(arcs, n)

        if verbose
            println("Iteration ", iteration)
            println("Objective value = ", objective_value(model))
            println("Number of subtours = ", length(subtours))
            println("Subtours = ", subtours)
            println()
        end

        if length(subtours) == 1
            return model, x, arcs, objective_value(model), subtours
        end

        for S in subtours
            if length(S) < n
                add_subtour_constraint!(model, x, S)
            end
        end
    end
end

###############################################################
# PART 6 — Demonstrations
###############################################################

"""
    demo_manual(; n=12, seed=1)

Run the first step of the manual subtour elimination procedure.
Then the teacher can repeatedly call:

    arcs, subtours = solve_again_after_adding_first_subtour!(model, x, n)
    display(plot_arcs(cities, arcs))
"""
function demo_manual(; n=12, seed=1)
    cities = generate_cities(n; seed=seed)
    D = compute_distance_matrix(cities)

    model, x, arcs, subtours = solve_relaxed_assignment(D)

    display(plot_arcs(cities, arcs, title_str="Initial assignment solution"))

    return cities, D, model, x, arcs, subtours
end

"""
    demo_automatic(; n=12, seed=1)

Solve the TSP automatically with iterative subtour elimination and display the final tour.
"""
function demo_automatic(; n=12, seed=1)
    cities = generate_cities(n; seed=seed)
    D = compute_distance_matrix(cities)

    model, x, arcs, opt_value, subtours = solve_tsp_with_subtour_elimination(D)

    println("Optimal TSP value = ", opt_value)
    display(plot_arcs(cities, arcs, title_str="Optimal TSP tour"))

    return cities, D, model, x, arcs, opt_value, subtours
end

###############################################################
# PART 7 — Optional direct execution
###############################################################

# Uncomment one of the following lines if you want the demo to run
# automatically when executing this file.

# demo_manual(n=12, seed=1)
# demo_automatic(n=12, seed=1)

