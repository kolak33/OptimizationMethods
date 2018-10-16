#Jakub Kolakowski nr albumu 221457

set MainProducts; # A, B
set SecondaryProducts; #C, D
set Products; #A, B, C, D
set Materials; # 1, 2, 3
set MaterialsProductionInfo; # Min, Max

#tabela z informacjami o surowcach, min/max produkcja
param material_prod_amount{m in Materials, i in MaterialsProductionInfo};
#koszt zakupu surowca
param material_buy_price{m in Materials};
#zysk ze sprzedazy produktu
param product_sell_price_main{p in MainProducts};
param product_sell_price_sec{p in SecondaryProducts};
#minimalnie ile surowcow potrzeba na kazdy material
param main_product_material_min_req{p in MainProducts, m in Materials};
#maksymalnie ile surowcow potrzeba na kazdy material
param main_product_material_max_req{p in MainProducts, m in Materials};
#stosunek dla prod C, D wzgledem odpadkow
param sec_product_material_ratio{p in SecondaryProducts, m in Materials};
#jaka czesc surowca zostaje odpadem
param waste_created_ratio{p in MainProducts, m in Materials};
#cena w $/kg ile kosztuje utylizacja kazdego z odpadow
param waste_utilization_cost{p in MainProducts, m in Materials};

#zmienna okreslajaca ile produktow glownych wyprodukowano (zawiera odpady)
var amount_produced_main{p in MainProducts} >= 0;

#zmienna okreslajaca ile produktow glownych wyprodukowano (juz bez odpadow)
var amount_produced_main_final{p in MainProducts} >= 0;
var amount_produced_secondary{s in SecondaryProducts} >= 0;

#ilosc uzytego surowca do produkcji kazdego z glownych produktow (1b)
var material_used_for_main_product{p in MainProducts, m in Materials};
#ilosc uzytego surowca do produkcji kazdego z C,D produktow (1b)
var material_used_for_sec_product{p in SecondaryProducts, m in Materials};

#ilosc kupionych materialow
var amount_material_bought{m in Materials} >= 0;

#ilosc powstalych odpadkow poszczegolnych surowcow podczas produkcji A i B
var waste_created_from_main{p in MainProducts, m in Materials} >= 0;

#ilosc uzytych odpadkow podczas produkcji C i D
var waste_used_for_sec{p in SecondaryProducts, m in Materials} >= 0;

#ilosc odpadkow zniszczona
var waste_destroyed{p in MainProducts, m in Materials} >= 0;
#ilosc ³¹cznie wszystkich odpadkow uzytych do produkcji C,D
#var waste_used_for_sec{p in SecondaryProducts} >= 0;

#minimalnie jakie ratio surowcow moze byc dla A,B
s.t. material_min_ratio_usage_main{p in MainProducts, m in Materials} :
material_used_for_main_product[p, m] >= main_product_material_min_req[p, m] * amount_produced_main[p];

#maksymalnie jakie ratio surowcow moze byc dla A,B
s.t. material_max_ratio_usage_main{p in MainProducts, m in Materials} :
material_used_for_main_product[p, m] <= main_product_material_max_req[p, m] * amount_produced_main[p];

#minimalnie ile surowcow musi byc kupione
s.t. material_min_bought{m in Materials} :
sum{p in MainProducts}(material_used_for_main_product[p, m]) +
+ sum{p in SecondaryProducts}(material_used_for_sec_product[p, m]) 
>= material_prod_amount[m, 'Mini'];

#maksymalnie ile moze byc kupione
s.t. material_max_bought{m in Materials} :
sum{p in MainProducts}(material_used_for_main_product[p, m]) +
+ sum{p in SecondaryProducts}(material_used_for_sec_product[p, m]) 
<= material_prod_amount[m, 'Maxi'];

#suma surowcow sklada sie na A,B(razem z odpadkami)
s.t. amount_produced_ratio{p in MainProducts} :
amount_produced_main[p] = sum{m in Materials}(material_used_for_main_product[p, m]);

#ile surowcow zostalo kupione (1a)
s.t. material_bought_min{m in Materials} :
amount_material_bought[m] = sum{p in MainProducts}(material_used_for_main_product[p, m]) 
+ sum{p in SecondaryProducts}(material_used_for_sec_product[p, m]);

#ilosc w kg wyprodukowanych A,B po usunieciu odpadkow
s.t. amount_produced_final_main{p in MainProducts} :
amount_produced_main_final[p] = 
sum{m in Materials} (material_used_for_main_product[p,m] * (1 - waste_created_ratio[p,m]));

#ilosc powstalych odpadkow przy produkcji A i B
s.t. waste_production{p in MainProducts, m in Materials} :
waste_created_from_main[p, m] = waste_created_ratio[p, m] * material_used_for_main_product[p,m];

#ilosc poszczegolnych odpadkow uzyta podczas produkcji C i D
#s.t. waste_used_max{p in SecondaryProducts, m in Materials} :
#waste_used_for_sec[p, m] <= waste_created_from_main[p, m];
s.t. waste_used_max1{m in Materials} :
waste_used_for_sec['C', m] <= waste_created_from_main['A', m];
s.t. waste_used_max2{m in Materials} :
waste_used_for_sec['D', m] <= waste_created_from_main['B', m];


#ratio surowcow do odpadkow dla C,D
s.t. ratio_waste_to_material{p in SecondaryProducts, m in Materials} :
material_used_for_sec_product[p, m] = sec_product_material_ratio[p, m] * sum{m2 in Materials}(waste_used_for_sec[p, m2]);

#ilosc wyprodukowanych C i D
s.t. produced_sec{p in SecondaryProducts} :
amount_produced_secondary[p] = sum{m in Materials}(material_used_for_sec_product[p, m])
+ sum{m in Materials}(waste_used_for_sec[p, m]);

#ilosc odpadkow nie zniszczona (1c)
s.t. waste_destroyed_array1{m in Materials} :
waste_destroyed['A', m] = waste_created_from_main['A', m] - waste_used_for_sec['C', m];
s.t. waste_destroyed_array2{m in Materials} :
waste_destroyed['B', m] = waste_created_from_main['B', m] - waste_used_for_sec['D', m];

maximize profit_from_products :
sum{p in MainProducts}(amount_produced_main_final[p] * product_sell_price_main[p]) +
sum{p in SecondaryProducts}(amount_produced_secondary[p] * product_sell_price_sec[p]) -
(sum{m in Materials}(amount_material_bought[m] * material_buy_price[m])) -
(sum{p in MainProducts, m in Materials}(waste_destroyed[p, m] * waste_utilization_cost[p, m]));

solve;

display profit_from_products;
display{m in Materials} amount_material_bought[m];

for {p in MainProducts, m in Materials: material_used_for_main_product[p,m] > 0.0}
printf"ilosc surowca %s dla produktu %s: %g\n", m, p, material_used_for_main_product[p, m];

for {p in SecondaryProducts, m in Materials: material_used_for_sec_product[p,m] > 0.0}
printf"ilosc surowca %s dla produktu %s: %g\n", m, p, material_used_for_sec_product[p, m];

for {p in SecondaryProducts, m in Materials: waste_used_for_sec[p,m] > 0.0}
printf"ilosc odpadow %s dla produktu %s: %g\n", m, p, waste_used_for_sec[p, m];

display waste_destroyed;
display waste_created_from_main;

display amount_produced_main_final;
display amount_produced_secondary;

data;

set MainProducts := A B;
set SecondaryProducts := C D;
set Products := A B C D;
set Materials := S1 S2 S3;
set MaterialsProductionInfo := Mini Maxi;

#tabela z informacjami o surowcach, min/max produkcja
param material_prod_amount : Mini Maxi :=
S1 2000 6000
S2 3000 5000
S3 4000 7000;

#koszt zakupu surowca
param material_buy_price :=
S1 2.1 S2 1.6 S3 1.0;

#zysk ze sprzedazy produktu
param product_sell_price_main :=
A 3.0 B 2.5;
param product_sell_price_sec :=
C 0.6 D 0.5;

#minimalnie ile surowcow potrzeba na kazdy material
param main_product_material_min_req : S1 S2 S3 :=
A 0.2 0.4 0
B 0.1 0 0;
#maksymalnie ile surowcow potrzeba na kazdy material
param main_product_material_max_req : S1 S2 S3 :=
A 1.0 1.0 0.1
B 1.0 1.0 0.3;
#stosunek dla prod C, D wzgledem odpadkow
param sec_product_material_ratio : S1 S2 S3 :=
C 0.25 0 0
D 0 0.4286 0;

#jaka czesc surowca zostaje odpadem
param waste_created_ratio : S1 S2 S3 :=
A 0.1 0.2 0.4
B 0.2 0.2 0.5;
#cena w $/kg ile kosztuje utylizacja kazdego z odpadow
param waste_utilization_cost : S1 S2 S3 :=
A 0.1 0.1 0.2
B 0.05 0.05 0.40;

end;




