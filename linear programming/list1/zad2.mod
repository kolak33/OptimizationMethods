#Jakub Kolakowski nr albumu 221457

set City;
set Type;

#odleglosc z jednego miasta do innego
param dist{src in City, dest in City};
#nadmiar kamperow w danym miescie dla danego typu
param excess{i in City, t in Type};
#niedobór kamperow w danym miescie dla danego typu
param insuff{i in City, t in Type};

var do_transport{src in City, dest in City, t in Type} >= 0;

#z 1 miasta przekazujemy caly nadmiar do innych
s.t. equal_transport {src in City, t in Type} :
sum{dest in City}(do_transport[src, dest, t]) = excess[src, t];

#PROBA VIP -> ST, moze przyjsc wiecej VIPów, ktore licza sie jako standardy,
#wiec suma po standardach moze byc mniejsza niz ich niedomiar, bo VIPy to nadrobia
s.t. VIP_to_st{dest in City} :
sum{src in City}(do_transport[src, dest, 'st']) <= insuff[dest, 'st'];

#musi przyjechac tyle kamperow co jest deficytow
s.t. equal_insufficiency{dest in City} :
sum{src in City, t in Type}(do_transport[src, dest, t]) = insuff[dest, 'st'] + insuff[dest, 'VIP'];

#minimalizacja kosztu transportu
minimize transport_cost : sum{src in City, dest in City}( do_transport[src, dest, 'st'] * dist[src, dest] + 1.15 * do_transport[src, dest, 'VIP'] * dist[src, dest]);

solve;

display transport_cost;
for {src in City, dest in City, t in Type: do_transport[src, dest, t] > 0}
printf "z %s do %s %d %s kamperów.\n", src, dest, do_transport[src, dest, t], t;

end;
