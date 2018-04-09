#Jakub Kolakowski nr albumu 221457

param n;
set I := {1..n};
set J := {1..n};

param A{i in I, j in J} := 
( 1 / (i + j - 1));
param B{i in I} := sum {j in J}
( 1 / (i + j - 1));
param optimal_x{i in I} := 1;

var X{i in I} >= 0;

s.t. matrix_calc {i in I} :
	B[i] = sum{j in J} (A[i, j] * X[j]);

minimize x_calculated : sum{i in I}(X[i]);

solve;

 display{i in I} X[i], optimal_x[i];
 printf "blad wynosi = %g\n", (sum{i in I}(sqrt((optimal_x[i] - X[i]) * (optimal_x[i] - X[i])))) / (sum{i in I}(sqrt((optimal_x[i]) * (optimal_x[i]))));

end;

