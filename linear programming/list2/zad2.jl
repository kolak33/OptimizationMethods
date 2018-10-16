#Jakub Kołakowski


using JuMP
using GLPKMathProgInterface # pakiet GLPK

function ChooseProgramsToCalculateFunctions(ProgramMemory::Matrix{Int64},
						ProgramExecTime::Matrix{Int64},
						FuncToCompute::Vector{Int64},
						MaxMemory::Int64)
(m,n)=size(ProgramMemory)
# m - liczba mozliwych funkcji do obliczenia
# n - liczba podprogramów obliczajacych kazda z funkcji
# ProgramMemory - macierz określająca zużycie pamieci każdego z programów
# ProgramExecTime - macierz określająca czas potrzebny na wykonanie kazdego z programow
# FuncToCompute - wektor mówiący które funkcje chcemy obliczyć
# MaxMemory - maksymalna dostepna ilosc pamieci na obliczenie wszystkich zadanych funkcji

	model = Model(solver = GLPKSolverMIP()) # wybor solvera

	@variable(model, x[1:m, 1:n]>=0, Int) # zmienne decyzyjne

	@objective(model,Min, vecdot(ProgramExecTime,x))  # funkcja celu

# wybrane podprogramy nie moga przekroczyc mozliwej dostepnej pamieci
  @constraint(model, sum(x[i, j] * ProgramMemory[i, j] for i=1:m, j=1:n) <= MaxMemory) # ogranizenia

# wybieramy podprogramy tylko dla wybranych funkcji
for i=1:m
	@constraint(model, sum(x[i, j] for j=1:n) == FuncToCompute[i]) # ogranizenia
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


ProgramMemory = [5 6 4;
     			1 2 3;
				10 5 16]
ProgramExecTime = [11 2 15;
				  3 4 5;
				  5 10 4]
FuncToCompute = [1; 0; 1]
MaxMemory = 10

(status, fval, x)=ChooseProgramsToCalculateFunctions(ProgramMemory, ProgramExecTime, FuncToCompute, MaxMemory)
if status==:Optimal
	 println("fval: ", fval)
 println("choose programs: ", x)
else
   println("Status: ", status)
end
