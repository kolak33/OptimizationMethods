#Jakub Kołakowski


using JuMP
using GLPKMathProgInterface # pakiet GLPK

function PrintPermutation(A::Matrix{Float64}, endTaskTime::Matrix{Float64}, taskDuration::Matrix{Int64})
    (m, n) = size(taskDuration)

for k in 1:m
    for i in 1:n
        zeros = 0;
        found = false;
        for j in 1:n
            if found == false && A[i, j] == 0
                zeros = zeros + 1;
            else
                found = true;
            end
        end

        perm = zeros + 1

            if k == 1
                emptyProc = 0
            else
                if i > 1
                emptyProc = endTask[k, i] - endTask[k, i-1] - taskDuration[k, perm]
            else # i == 1
                emptyProc = endTask[k, i] - taskDuration[k, perm]
                end
            end

            for x in 1:emptyProc
                print('x')
            end

            time = taskDuration[k, perm]
            #println("time: ", time)
            for x in 1:time
                print(perm)
            end


    end
    println()
end
end

function FindProgramPermutation(ProgramExecTime::Matrix{Int64})
(m, n) = size(ProgramExecTime)

# m - liczba procesorow
# n - liczba zadan
# ProgramExecTime - macierz określająca czas potrzebny na wykonanie kazdego z zadan na kazdym z procesorow
# permutation - macierz okreslajaca permutacje
# endTaskTime - macierz okreslajaca czas zakonczenia zadania na kazdej z maszyn

model = Model(solver = GLPKSolverMIP())

@variable(model, permutation[1:n, 1:n] >= 0, Int)
@variable(model, endTaskTime[1:m, 1:n] >= 0, Int)

@variable(model, cost >= 0, Int)


for i in 1:n
    @constraint(model, sum(permutation[i, j] for j in 1:n) == 1)
    @constraint(model, sum(permutation[j, i] for j in 1:n) == 1)
end

@constraint(model, sum(permutation[1, j] * ProgramExecTime[1, j] for j in 1:n) == endTaskTime[1, 1])
for i in 2:n
    @constraint(model, endTaskTime[1, i-1] + sum(permutation[i, j] * ProgramExecTime[1, j] for j in 1:n) == endTaskTime[1, i])
end

for p in 2:m
    @constraint(model, endTaskTime[p - 1, 1] + sum(permutation[1, j] * ProgramExecTime[p, j] for j in 1:n) == endTaskTime[p, 1])
    for i in 2:n
        @constraint(model, endTaskTime[p - 1, i] + sum(permutation[i, j] * ProgramExecTime[p, j] for j in 1:n) <= endTaskTime[p, i])
        @constraint(model, endTaskTime[p, i - 1] + sum(permutation[i, j] * ProgramExecTime[p, j] for j in 1:n) <= endTaskTime[p, i])
    end
end

for p in 1:m
    @constraint(model, endTaskTime[p, n] <= cost)
end

status = solve(model, suppress_warnings=true)
println(getvalue(endTaskTime))
println("koszt: ", getvalue(cost))
if status==:Optimal
    return status, getobjectivevalue(model), getvalue(permutation), getvalue(endTaskTime)
else
    return status, nothing, nothing, nothing
end

end

B = [3 2 2 3;
     3 3 3 3;
     1 2 4 1]

C = [3 3 4 2 3 2;
     3 3 1 2 2 2;
     4 3 2 3 1 3]

(status, fval, x, endTask) = FindProgramPermutation(B)
if(status ==:Optimal)
    PrintPermutation(x, endTask, B)
else
    println("status: ", status)
end
