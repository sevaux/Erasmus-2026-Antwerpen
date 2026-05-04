## Suggested usage in Julia:

```julia
include("tsp_tp_student.jl")
include("tsp_tp_tests.jl")

runtests_tp(:ex01)   # test only Exercise 0.1
runtests_tp(:ex32)   # test local search
runtests_tp(:all)    # run everything
```

## For teacher version:

```julia
include("tsp_tp_teacher.jl")
include("tsp_tp_tests.jl")
runtests_tp(:all)
```

## For visualization:

```julia
cities, D, sol = demo_instance(20)
p = plot_tour(cities, sol, title_str="Initial random tour: 
                $(round(tour_cost(sol,D),digits=2))")
display(p)

best_sol, best_cost, history = local_search(sol, D, max_iter=100)
display(compare_tours(cities, sol, best_sol, labels=("Initial: 
        $(round(tour_cost(sol,D),digits=2))", 
        "Local search: $(round(tour_cost(best_sol,D),digits=2))")))
```

---

# Math model

```julia
include("tsp_mip_subtour_elimination.jl")
```

## Manual mode:

```julia
cities, D, model, x, arcs, subtours = demo_manual(n=12, seed=1)

arcs, subtours = solve_again_after_adding_first_subtour!(model, x, 12)
display(plot_arcs(cities, arcs))
```

Repeat the last two lines until there is only one tour.

```julia
S = add_subtour_constraint_from_node!(model, x, arcs, 4)
println("Added subtour elimination constraint for S = ", S)

optimize!(model)

arcs = selected_arcs(x)
subtours = find_subtours(arcs, n)

display(plot_arcs(cities, arcs))
```

## Automatic mode:

```julia
cities, D, model, x, arcs, opt_value, subtours = demo_automatic(n=12, seed=1)
```
---

# Another methode based on the same math model

Interactive mode

```julia
include("interactive_tsp_subtour_elimination.jl")

cities, D = generate_tsp_instance(12; seed=1)
model, x, arcs, opt_value = interactive_subtour_elimination(D, cities)
```

Automatic version:

```julia
cities, D, model, x, arcs, opt_value = demo_automatic(n=12, seed=1)
```
