# Julia file for instructors (solutions)

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
    return rand(n, 2) # return n random 2D points in [0,1]×[0,1]
end

# ✏️ Exercise 0.2 — Distance matrix

function compute_distance_matrix(cities)
    n = size(cities, 1)
    D = zeros(n, n)
    
    for i in 1:n
        for j in 1:n
            D[i,j] = sqrt(sum((cities[i,:] .- cities[j,:]).^2))
        end
    end
    
    return D
end

"""
  computeDistanceMatrix(cities)

Compute the Euclidian distance between points whose coordinates are in `cities`

Returns the distance matrix `D`
"""
function compute_distance_matrix2(cities)
  n = size(cities,1) # number of points
  D = zeros(n,n) # declare distance matrix
  for i=1:n-1
    for j=i+1:n
      # for each couple (i,j) calculate the euclidian distance
      D[i,j] = D[j,i] = sqrt((cities[i,1]-cities[j,1])^2 + (cities[i,2]-cities[j,2])^2)
    end
  end
  return D # return the distance matrix
end

# 🧩 Part 1 — Solution Representation
# ✏️ Exercise 1.1 — Random solution
# 👉 A solution is a permutation

function random_solution(n)
    return shuffle(1:n)
end

# ✏️ Exercise 1.2 — Cost function

function tour_cost(sol, D)
    n = length(sol)
    cost = 0.0
    
    for i in 1:n-1
        cost += D[sol[i], sol[i+1]]
    end
    
    cost += D[sol[n], sol[1]]
    
    return cost
end


# 🧩 Part 2 — Neighborhoods
# ✏️ Exercise 2.1 — Swap move

function swap(sol, i, j)
    new_sol = copy(sol)
    new_sol[i], new_sol[j] = new_sol[j], new_sol[i]
    return new_sol
end

# ✏️ Exercise 2.2 — Random neighbor

function random_neighbor(sol)
    n = length(sol)
    i, j = rand(1:n, 2)
    return swap(sol, i, j)
end

# 🧩 Part 3 — Local Search
# ✏️ Exercise 3.1 — First-improvement

function local_search(sol, D, max_iter=1000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    n = length(sol)
    
    for iter in 1:max_iter
        improved = false
        
        for i in 1:n
            for j in i+1:n
                neighbor = swap(current, i, j)
                c = tour_cost(neighbor, D)
                
                if c < current_cost
                    current = neighbor
                    current_cost = c
                    improved = true
                    break
                end
            end
            if improved
                break
            end
        end
        
        if !improved
            break
        end
    end
    
    return current, current_cost
end

# 🧩 Part 4 — Simulated Annealing
# Introduce Simulated Annealing

# ✏️ Exercise 4.1 — Acceptance rule

function accept(delta, T)
    if delta < 0
        return true
    else
        return rand() < exp(-delta / T)
    end
end

# ✏️ Exercise 4.2 — Simulated annealing

function simulated_annealing(sol, D;
    T=1.0, alpha=0.995, max_iter=10000)

    current = copy(sol)
    current_cost = tour_cost(current, D)
    
    best = copy(current)
    best_cost = current_cost
    
    for iter in 1:max_iter
        neighbor = random_neighbor(current)
        c = tour_cost(neighbor, D)
        
        delta = c - current_cost
        
        if accept(delta, T)
            current = neighbor
            current_cost = c
            
            if c < best_cost
                best = neighbor
                best_cost = c
            end
        end
        
        T *= alpha
    end
    
    return best, best_cost
end

# 🧩 Part 5 — Multiple Neighborhoods (VNS idea)
# Introduce:
#
# Variable Neighborhood Search
#
# ✏️ Exercise 5.1 — Insert move

function insert_move(sol, i, j)
    new_sol = copy(sol)
    city = new_sol[i]
    deleteat!(new_sol, i)
    insert!(new_sol, j, city)
    return new_sol
end

# ✏️ Exercise 5.2 — VNS loop

function VNS(sol, D, max_iter=1000)
    current = copy(sol)
    current_cost = tour_cost(current, D)
    n = length(sol)
    
    for iter in 1:max_iter
        k = rand(1:2)
        
        if k == 1
            i, j = rand(1:n, 2)
            neighbor = swap(current, i, j)
        else
            i, j = rand(1:n, 2)
            neighbor = insert_move(current, i, j)
        end
        
        c = tour_cost(neighbor, D)
        
        if c < current_cost
            current = neighbor
            current_cost = c
        end
    end
    
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
