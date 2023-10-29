var documenterSearchIndex = {"docs":
[{"location":"#SupplyChainModeling","page":"SupplyChainModeling","title":"SupplyChainModeling","text":"","category":"section"},{"location":"#Installation","page":"SupplyChainModeling","title":"Installation","text":"","category":"section"},{"location":"","page":"SupplyChainModeling","title":"SupplyChainModeling","text":"SupplyChainModeling can be installed using the Julia package manager. From the Julia REPL, type ] to enter the Pkg REPL mode and run","category":"page"},{"location":"","page":"SupplyChainModeling","title":"SupplyChainModeling","text":"pkg> add SupplyChainModeling","category":"page"},{"location":"#API","page":"SupplyChainModeling","title":"API","text":"","category":"section"},{"location":"","page":"SupplyChainModeling","title":"SupplyChainModeling","text":"Modules = [SupplyChainModeling]\nOrder   = [:type, :function]","category":"page"},{"location":"#SupplyChainModeling.Customer","page":"SupplyChainModeling","title":"SupplyChainModeling.Customer","text":"A customer.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Demand","page":"SupplyChainModeling","title":"SupplyChainModeling.Demand","text":"The demand a customer has for a product.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Lane","page":"SupplyChainModeling","title":"SupplyChainModeling.Lane","text":"A transportation lane between two nodes of the supply chain.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Location","page":"SupplyChainModeling","title":"SupplyChainModeling.Location","text":"The geographical location of a node of the supply chain.  The location is defined by its latitude and longitude.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Node","page":"SupplyChainModeling","title":"SupplyChainModeling.Node","text":"A node of the supply chain.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Plant","page":"SupplyChainModeling","title":"SupplyChainModeling.Plant","text":"A plant.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Storage","page":"SupplyChainModeling","title":"SupplyChainModeling.Storage","text":"A storage location.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.Supplier","page":"SupplyChainModeling","title":"SupplyChainModeling.Supplier","text":"A supplier.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.SupplyChain","page":"SupplyChainModeling","title":"SupplyChainModeling.SupplyChain","text":"The supply chain.\n\n\n\n\n\n","category":"type"},{"location":"#SupplyChainModeling.add_customer!-Tuple{SupplyChain, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_customer!","text":"add_customer!(supply_chain, customer)\n\nAdds a customer to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_demand!-Tuple{Any, Any, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_demand!","text":"add_demand!(supply_chain, customer, product; demand::Array{Float64, 1}, service_level=1.0)\n\nAdds customer demand for a product. The demand is specified for each time period.\n\nThe keyword arguments are:\n\ndemand: the amount of product demanded for each time period.\nservice_level: indicates how many lost sales are allowed as a ratio of demand. No demand can be lost if the service level is 1.0 and all demand can be lost if the service level is 0.0. \n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_demand!-Tuple{SupplyChain, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_demand!","text":"add_demand!(supply_chain, demand)\n\nAdds demand to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_lane!-Tuple{SupplyChain, Lane}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_lane!","text":"add_lane!(supply_chain, lane)\n\nAdds a transportation lane to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_plant!-Tuple{SupplyChain, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_plant!","text":"add_plant!(supply_chain, plant)\n\nAdds a plant to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_product!-Tuple{Plant, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_product!","text":"add_product!(plant::Plant, product::Product; bill_of_material::Dict{Product, Float64}, unit_cost, maximum_throughput)\n\nIndicates that a plant can produce a product.\n\nThe keyword arguments are:\n\nbill_of_material: the amount of other product needed to produce one unit of the product. This dictionary can be empty if there are no other products needed.\nunit_cost: the cost of producing one unit of product.\nmaximum_throughput: the maximum amount of product that can be produced in a time period.\ntime: the production lead time.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_product!-Tuple{Supplier, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_product!","text":"add_product!(supplier::Supplier, product::Product; unit_cost::Float64, maximum_throughput::Float64)\n\nIndicates that a supplier can provide a product.\n\nThe keyword arguments are:\n\nunit_cost: the cost per unit of the product from this supplier.\nmaximum_throughput: the maximum number of units that can be provided in each time period.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_product!-Tuple{SupplyChain, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_product!","text":"add_product!(supply_chain, product)\n\nAdds a product to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_storage!-Tuple{SupplyChain, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_storage!","text":"add_storage!(supply_chain, storage)\n\nAdds a storage location to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.add_supplier!-Tuple{SupplyChain, Any}","page":"SupplyChainModeling","title":"SupplyChainModeling.add_supplier!","text":"add_supplier!(supply_chain, supplier)\n\nAdds a supplier to the supply chain.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.can_ship-Tuple{Lane, Int64}","page":"SupplyChainModeling","title":"SupplyChainModeling.can_ship","text":"can_ship(lane::Lane, time::Int)\n\nChecks if units can be send on the lane at a given time.\n\n\n\n\n\n","category":"method"},{"location":"#SupplyChainModeling.get_arrivals-Tuple{Product, Lane, Any, Int64}","page":"SupplyChainModeling","title":"SupplyChainModeling.get_arrivals","text":"get_arrivals(lane::Lane, destination, time::Int)\n\nGets the known arrivals.\n\n\n\n\n\n","category":"method"}]
}
