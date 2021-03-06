# Graph 500
#
# Driver for this Julia implementation of the Graph 500 benchmarks.
#
# 2014.02.05    kiran.pamnany        Initial code


include("kronecker.jl")
include("makegraph.jl")
include("bfs_gpu.jl")
include("validate.jl")
include("output.jl")


function graph500(scale=14, edgefactor=16, num_bfs=64)
    println("Graph 500 (GPU Julia version)")

    println("Using Kronecker generator to build edge list...")
    v1, v2 = kronecker(scale, edgefactor)
    println("...done.")

    println("Building graph...")
    tic()
    G = makegraph(v1, v2)
	@show size(G), nnz(G)
    k1_time = toq()
    println("...done.")

	#preallocation 
	rows = G.colptr - 1
	cols = G.rowval - 1
	nodes = length(rows) - 1
	edges = length(cols)
	rows = map(Int32, rows)
	cols = map(Int32, cols)
	bfs_label = Array(Int32, nodes)

    # generate requested # of random search keys
    N = size(G, 1)
    search = randperm(N)
    search = search[1:num_bfs]

    k2_times = zeros(num_bfs)
    k2_nedges = zeros(num_bfs)
    indeg = hist([v1; v2], 1:N+1)[2]

    println("Running BFSs...")
    run_bfs = 1
	t1 = 0
	t2 = 0
    @time for k = 1:num_bfs
        # ensure degree of search key > 0
        #if length((G[:, search[k]]).nzind) == 0
            #println(@sprintf("(discarding %d)", search[k]))
         #   continue
        #end
		tic()
		parents = gen_parents(G, k, rows, cols, nodes, edges, bfs_label)
		k2_times[run_bfs] = toq()
		#ok, t1, t2 = gen_and_validate(G, k, v1, v2, rows, cols, nodes, edges, bfs_label, t1, t2) 
		ok = validate(parents, v1, v2, k)
		if ok <=0
			error("BFS failed to validate at key $k")
		end
        k2_nedges[run_bfs] = sum(indeg[parents .>= -1]) / 2
		#gen_label(G,k)
        #println(run_bfs)
        #println(search[k])
        #println(k2_times[run_bfs])
        #println(k2_nedges[run_bfs])
        run_bfs += 1
    end
    println("...done.\n")
    #splice!(k2_times, run_bfs:num_bfs)
    #splice!(k2_nedges, run_bfs:num_bfs)
    run_bfs -= 1
	#println("Time for generating tree and level =  $(t1)")
#	println("Time for validation  = $(t2)")
	@show sum(k2_times)
    TEPS = k2_nedges ./ k2_times
    N = length(TEPS)
    tmp = 1.0./TEPS
    hmean = N/sum(tmp)
    @printf("harmonic_mean_TEPS: %20.17e\n", hmean)
   # println("Output:")
    #output(scale, edgefactor, run_bfs, k1_time, k2_times, k2_nedges)
end

