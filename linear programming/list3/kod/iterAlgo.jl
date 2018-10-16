#Jakub Kołakowski


using JuMP
using GLPKMathProgInterface # pakiet GLPK

function InitVariables()
 #=    m = 5
     n = 15
     JobCostC = [17 21 22 18 24 15 20 18 19 18 16 22 24 24 16;
 23 16 21 16 17 16 19 25 18 21 17 15 25 17 24;
 16 20 16 25 24 16 17 19 19 18 20 16 17 21 24;
 19 19 22 22 20 16 19 17 21 19 25 23 25 25 25;
 18 19 15 15 21 25 16 16 23 15 22 17 19 22 24]

 JobProcessingTimeP = [8 15 14 23 8 16 8 25 9 17 25 15 10 8 24;
 15 7 23 22 11 11 12 10 17 16 7 16 10 18 22;
 21 20 6 22 24 10 24 9 21 14 11 14 11 19 16;
 20 11 8 14 9 5 6 19 19 7 6 6 13 9 18;
 8 13 13 13 10 20 25 16 16 17 10 10 5 12 23]

 MachineMaxTimeT = [36; 34; 38; 27; 33]

 Jobs = Vector{Int64}(n)
 Jobs[1:n] = 1

 Machines = Vector{Int64}(m)
 Machines[1:m] = 1

 Graph = Matrix{Int64}(m, n)
 Graph[1:m, 1:n] = 1

 for i in 1:m
   for j in 1:n
     if(JobProcessingTimeP[i, j] > MachineMaxTimeT[i])
       Graph[i][j] = 0
     end
   end
 end
 =#

#return JobProcessingTimeP, JobCostC, Jobs, Machines, MachineMaxTimeT, Graph
end

function LP(JobProcessingTimeP::Matrix{Int64}, JobCostC::Matrix{Int64}, Jobs::Vector{Int64}, Machines::Vector{Int64},
            MachineMaxTimeT::Vector{Int64}, Graph::Matrix{Int64})
(m, n) = size(JobProcessingTimeP)

# m - liczba maszyn
# n - liczba zadan
# JobProcessingTimeP - macierz określająca czas potrzebny na wykonanie kazdej pracy j na maszynie i
# JobCostC - macierz okreslajaca koszt wykonania zadania j na maszynie i
# Jobs - wektor prac, ktore nie zostaly przypisane do finalnego rozwiazania
# Machines - wektor maszyn, ktore nie zostaly przypisane do finalnego rozwiazania
# MachineMaxTimeT - wektor maksymalnych czasow wykonywania zadan na danej maszynie
# Graph - macierz okreslejaca czy istnieje krawedz miedzy praca j a maszyna i
# x - macierz zmiennych okreslajacych jaka czesc zadania j przypisana jest maszynie i

model = Model(solver = GLPKSolverLP())

@variable(model, x[1:m, 1:n] >= 0)

@objective(model, Max, sum(x[i, j] * JobCostC[i, j] * Graph[i, j] for i = 1:m, j = 1:n))

epsilon = 0.000001;
for j in 1:n
 if(Jobs[j] == 1)
    @constraint(model, sum(x[i, j] * Graph[i, j] for i in 1:m) <= 1 + epsilon)
    @constraint(model, sum(x[i, j] * Graph[i, j] for i in 1:m) >= 1 - epsilon)
 end
end

for i in 1:m
 if(Machines[i] == 1)
    @constraint(model, sum(x[i, j] * JobProcessingTimeP[i, j] * Graph[i, j] for j in 1:n) <= MachineMaxTimeT[i])
 end
end

status = solve(model, suppress_warnings=true)
#println(getvalue(endTaskTime))
#println("koszt: ", getvalue(cost))
if status==:Optimal
    return status, getobjectivevalue(model), getvalue(x)
else
  println("status: ", status)
    return status, nothing, nothing
end
end

function IterativeAprrox(JobProcessingTimeP::Matrix{Int64}, JobCostC::Matrix{Int64}, Jobs::Vector{Int64}, Machines::Vector{Int64},
            MachineMaxTimeT::Vector{Int64}, Graph::Matrix{Int64})
#JobProcessingTimeP, JobCostC, Jobs, Machines, MachineMaxTimeT, Graph = InitVariables()
(m, n) = size(JobProcessingTimeP)
MachineMaxTimeCopy = copy(MachineMaxTimeT)

epsilon = 0.0001;
FinalGraph = Matrix{Int64}(m, n)
FinalGraph[1:m, 1:n] = 0

while(sum(Jobs[j] for j = 1:n) > 0)
 (status, fval, x) = LP(JobProcessingTimeP, JobCostC, Jobs, Machines, MachineMaxTimeT, Graph)
	# jezeli istnieje krawedz w G, dla ktorej x_ij = 0, usun ja z grafu
 deleted = false
  for i in 1:m
    for j in 1:n
      if(Graph[i, j] == 1 && x[i, j] <= epsilon) # == 0
       Graph[i, j] = 0
       deleted = true
      end
    end
  end

	#jezeli istnieje krawedz w G, dla ktorej x_ij = 1, usun ja z grafu
		for i in 1:m
				for j in 1:n
					if(deleted == false && Graph[i, j] == 1 && (x[i, j] <= 1 + epsilon) && (x[i, j] >= 1 - epsilon)) # == 1
							FinalGraph[i, j] = 1
							Jobs[j] = 0
							MachineMaxTimeT[i] = MachineMaxTimeT[i] - JobProcessingTimeP[i, j]
							deleted = true
       Graph[i, j] = 0
					end
				end
			end

#deleted = false
if(deleted == false)
		for i in 1:m
				#jezeli maszyna jest w grafie i jest uzywana, ale stopien wierzcholka == 1
				if(deleted == false && sum(Graph[i, j] * Machines[i] for j = 1:n) == 1)
						Machines[i] = 0
						deleted = true
				end

				if(deleted == false && sum(Graph[i, j] * Machines[i] for j = 1:n) == 2 &&
					  sum(x[i, j] * Jobs[j] for j = 1:n) >= 1 - epsilon) # >= 1
							Machines[i] = 0
							deleted = true
				end
		end
end

end #end while

#finalCost = sum(FinalGraph[i, j] * JobCostC[i, j] for i=1:m, j=1:n)
timeRatio = sum(MachineMaxTimeCopy[i] - MachineMaxTimeT[i] for i in 1:m) / sum(MachineMaxTimeCopy[i] for i=1:m)
#print(sum(MachineMaxTimeCopy[i] - MachineMaxTimeT[i] for i in 1:m) / sum(MachineMaxTimeCopy[i] for i=1:m), " ")
#print(finalCost, " ")

return timeRatio
#for i = 1: m
 #println("maxTime: ", MachineMaxTimeCopy[i])
 #println("curTime: ", sum(FinalGraph[i, j] * JobProcessingTimeP[i, j] for j = 1:n))
#end
end #end function

function Experiment()

numFiles = 12
filePrefix = "gap"
overAllTimeRatio = 0;
for z = 1:numFiles
  fileName = filePrefix * string(z) * ".txt"
  print(z, " ")
  f = open(fileName, "r")
  line = readline(f)
  numTests = parse(Int64, line)

  for i in 1:numTests
   line = readline(f)
   m, n = split(line, " ")
   m = parse(Int64, m)
   n = parse(Int64, n)

   JobCostC = Matrix{Int64}(m, n)
   JobProcessingTimeP = Matrix{Int64}(m, n)
   MachineMaxTimeT = Vector{Int64}(m)

    for j in 1:m
     line = readline(f);
      splitted = split(line, " ")
      for k in 1:n
       JobCostC[j, k] = parse(Int64, splitted[k])
      end
    end

    for j in 1:m
     line = readline(f);
      splitted = split(line, " ")
      for k in 1:n
       JobProcessingTimeP[j, k] = parse(splitted[k])
      end
    end

  line = readline(f);
  splitted = split(line, " ")
  for k in 1:m
   MachineMaxTimeT[k] = parse(splitted[k])
  end

  Jobs = Vector{Int64}(n)
  Jobs[1:n] = 1

  Machines = Vector{Int64}(m)
  Machines[1:m] = 1

  Graph = Matrix{Int64}(m, n)
  Graph[1:m, 1:n] = 1

  for i in 1:m
    for j in 1:n
      if(JobProcessingTimeP[i, j] > MachineMaxTimeT[i])
        Graph[i][j] = 0
      end
    end
  end

  timeRatio = IterativeAprrox(JobProcessingTimeP, JobCostC, Jobs, Machines, MachineMaxTimeT, Graph)
  overAllTimeRatio += timeRatio
  end
  println()
  close(f)

end

println("overAllTimeRatio: ", overAllTimeRatio / 60)
end #end funcion

Experiment()
