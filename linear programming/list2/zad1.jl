#Jakub Kołakowski


using JuMP
using GLPKMathProgInterface # pakiet GLPK

function DownloadFeaturesFromServers(Available::Matrix{Int64},
						AccessTime::Vector{Int64})
(m,n)=size(Available)
# m - liczba cech populacji
# n - liczba serverow z cechami
# Available - macierz mówiąca czy dana cecha i dostępna jest na serverze j
# AccessTime - wektor czasów dostępu na każdy z serverów

	model = Model(solver = GLPKSolverMIP()) # wybor solvera

	@variable(model, x[1:n]>=0, Int) # zmienne decyzyjne

	@objective(model,Min, vecdot(AccessTime,x))  # funkcja celu

for i = 1:m
  @constraint(model, sum(x[j] * Available[i, j] for j=1:n) == 1) # ogranizenia
end

println("MODEL:")
	print(model) # drukuj skonkretyzowany model

	status = solve(model, suppress_warnings=true) # rozwiaz model

	if status==:Optimal
		 return status, getobjectivevalue(model), getvalue(x)
	else
		return status, nothing,nothing
	end

end


#AccessTime = [ 3; 2; 6]
#Available = [1 0 1;
#     		0 1 1]

AccessTime = [ 3; 2; 3; 2; 1]
Available = [1 0 1 0 0;
     		0 0 1 0 1;
			1 0 0 1 0;
			0 1 0 1 0]

(status, fval, x)=DownloadFeaturesFromServers(Available,AccessTime)
if status==:Optimal
	 println("fval: ", fval)
 println("servers to connect: ", x)
else
   println("Status: ", status)
end
