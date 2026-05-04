# Julia file for students

# 🧪 TP: From Random Search to Metaheuristics (Julia)
# 📦 General Organization
# Format: one julia (.jl) file
# 
# Each section:
# 
# 🔹 Instructions (students)
# 
# ✏️ TODO blocks
# 
# ✅ Solution (can be hidden or given later)
# 


# 🧩 Part 0 — Setup
# 🔹 Goal
# Load data and define a simple instance.
# 
# ✏️ Exercise 0.1 — Generate cities

using Random

function generate_cities(n)
    # TODO: return n random 2D points in [0,1]×[0,1]
end

# ✏️ Exercise 0.2 — Distance matrix

function compute_distance_matrix(cities)
    n = size(cities, 1)
    D = zeros(n, n)
    
    # TODO: fill D[i,j] with Euclidean distance
    
    return D
end

# 🧩 Part 1 — Solution Representation
# ✏️ Exercise 1.1 — Random solution
# 👉 A solution is a permutation

function random_solution(n)
    # TODO: return a random permutation of 1:n
end

# ✏️ Exercise 1.2 — Cost function

function tour_cost(sol, D)
    n = length(sol)
    cost = 0.0
    
    # TODO: compute total distance (cycle!)
    
    return cost
end

# 🧩 Part 2 — Neighborhoods
# ✏️ Exercise 2.1 — Swap move

function swap(sol, i, j)
    # TODO: return a new solution with positions i and j swapped
end


# ✏️ Exercise 2.2 — Random neighbor

function random_neighbor(sol)
    n = length(sol)
    
    # TODO: pick two random indices and swap
    
end

# 🧩 Part 3 — Local Search
# ✏️ Exercise 3.1 — First-improvement

function local_search(sol, D, max_iter=1000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    
    # TODO: loop and improve solution
    
    return current, current_cost
end

# 🧩 Part 4 — Simulated Annealing
# Introduce Simulated Annealing

# ✏️ Exercise 4.1 — Acceptance rule

function accept(delta, T)
    # TODO:
    # if delta < 0 → accept
    # else accept with probability exp(-delta / T)
end

# ✏️ Exercise 4.2 — Simulated annealing

function simulated_annealing(sol, D;
    T=1.0, alpha=0.995, max_iter=10000)

    current = copy(sol)
    current_cost = tour_cost(current, D)
    
    best = copy(current)
    best_cost = current_cost
    
    # TODO: main loop
    
    return best, best_cost
end

# 🧩 Part 5 — Multiple Neighborhoods (VNS idea)
# Introduce:
#
# Variable Neighborhood Search
#
# ✏️ Exercise 5.1 — Insert move

function insert_move(sol, i, j)
    # TODO: remove element at i and insert at j
end

# ✏️ Exercise 5.2 — VNS loop

function VNS(sol, D, max_iter=1000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    
    # TODO:
    # alternate neighborhoods:
    # - swap
    # - insert
    
    return current, current_cost
end

# 🧪 Final Experiment
# ✏️ Exercise 6 — Compare methods

n = 50
cities = generate_cities(n)
D = compute_distance_matrix(cities)

sol = random_solution(n)

println("Initial: ", tour_cost(sol, D))

ls_sol, ls_cost = local_search(sol, D)
println("Local Search: ", ls_cost)

sa_sol, sa_cost = simulated_annealing(sol, D)
println("Simulated Annealing: ", sa_cost)

vns_sol, vns_cost = VNS(sol, D)
println("VNS: ", vns_cost)


