//
//  Expressible_Tests.swift
//  Expressible-Tests
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import XCTest
import CoreData

class Expressible_Tests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testCount() {
		let context = persistentContainer.viewContext
		let result1 = try! context.from(City.self).count()
		
		let request = NSFetchRequest<NSNumber>(entityName: "City")
		request.resultType = .countResultType
		let result2 = try! context.fetch(request).first?.intValue ?? 0
		XCTAssertEqual(result1, result2)
    }
	
	func testBasic() {
		let context = persistentContainer.viewContext
		let result1 = try! context
			.from(City.self)
			.filter(\City.population > 1_000_000)
			.sort(by: \City.population, ascending: false)
			.sort(by: \City.name, ascending: true)
			.fetch()
		
		let request = NSFetchRequest<City>(entityName: "City")
		request.predicate = NSPredicate(format: "population > 1000000")
		request.sortDescriptors = [NSSortDescriptor(key: "population", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
		let result2 = try! context.fetch(request)
		
		XCTAssertEqual(result1, result2)
	}

	func testSelect1() {
		let context = persistentContainer.viewContext
		let result1 = try! context
			.from(City.self)
			.group(by: [(\City.province?.name).as(String.self, name: "province")])
			.having(\City.province?.country?.name == "Belarus")
			.select([
				(\City.province?.name).as(String.self, name: "province"),
				(\City.population).sum.as(Int.self, name: "population")
				])
			.fetch()
		
		let request = NSFetchRequest<NSDictionary>(entityName: "City")
		request.havingPredicate = NSPredicate(format: "province.country.name == %@", "Belarus")
		request.resultType = .dictionaryResultType
		
		let province = NSExpressionDescription()
		province.expression = NSExpression(format: "province.name")
		province.expressionResultType = .stringAttributeType
		province.name = "province"
		
		let population = NSExpressionDescription()
		population.expression = NSExpression(format: "sum:(population)")
		population.expressionResultType = .integer32AttributeType
		population.name = "population"
		
		request.propertiesToFetch = [province, population]
		request.propertiesToGroupBy = [province]
		
		let result2 = try! context.fetch(request)
		
		XCTAssertEqual(result1, result2)
	}
	
	func testSelect2() {
		let context = persistentContainer.viewContext
		let result1 = try! context
			.from(City.self)
			.group(by: [(\City.province?.name).as(String.self, name: "province")])
			.having(\City.province?.country?.name == "Belarus")
			.select(
				(\City.population).sum.as(Int.self, name: "population")
				)
			.first()
		
		let request = NSFetchRequest<NSDictionary>(entityName: "City")
		request.havingPredicate = NSPredicate(format: "province.country.name == %@", "Belarus")
		request.resultType = .dictionaryResultType
		
		let province = NSExpressionDescription()
		province.expression = NSExpression(format: "province.name")
		province.expressionResultType = .stringAttributeType
		province.name = "province"

		let population = NSExpressionDescription()
		population.expression = NSExpression(format: "sum:(population)")
		population.expressionResultType = .integer32AttributeType
		population.name = "population"
		
		request.propertiesToFetch = [population]
		request.propertiesToGroupBy = [province]
		
		let result2 = try! context.fetch(request).first?["population"] as? Int
		
		XCTAssertEqual(result1, result2)
	}

	func testSelect3() {
		let context = persistentContainer.viewContext
		let result1 = try! context
			.from(City.self)
			.group(by: [(\City.province?.name).as(String.self, name: "province")])
			.having(\City.province?.country?.name == "Belarus")
			.select((
				(\City.province?.name),
				(\City.population).sum.as(Int.self, name: "population")
			))
			.fetch()
		
		let request = NSFetchRequest<NSDictionary>(entityName: "City")
		request.havingPredicate = NSPredicate(format: "province.country.name == %@", "Belarus")
		request.resultType = .dictionaryResultType
		
		let province = NSExpressionDescription()
		province.expression = NSExpression(format: "province.name")
		province.expressionResultType = .stringAttributeType
		province.name = "province"
		
		let population = NSExpressionDescription()
		population.expression = NSExpression(format: "sum:(population)")
		population.expressionResultType = .integer32AttributeType
		population.name = "population"
		
		request.propertiesToFetch = [province, population]
		request.propertiesToGroupBy = [province]
		
		let result2 = try! context.fetch(request).map {
			($0["province"] as? String, $0["population"] as? Int)
		}
		
		XCTAssertTrue(zip(result1, result2).allSatisfy({$0.0 == $1.0 && $0.1 == $1.1}))
	}
	
	func testSubrange() {
		let context = persistentContainer.viewContext
		let result1 = try! context
			.from(City.self)
			.sort(by: \City.population, ascending: false)
			.sort(by: \City.name, ascending: true)
			.subrange(10..<20)
			.fetch()
		
		let request = NSFetchRequest<City>(entityName: "City")
		request.sortDescriptors = [NSSortDescriptor(key: "population", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
		request.fetchOffset = 10
		request.fetchLimit = 10
		let result2 = try! context.fetch(request)
		
		XCTAssertEqual(result1, result2)
	}
	
	func testSubquery() {
		let context = persistentContainer.viewContext
		
		let result1 = try! context
			.from(Country.self)
			.filter((\Country.provinces).subquery((\Province.cities).any(\City.population) > 10_000_000).count != 0)
			.fetch()
		
		
		let request = NSFetchRequest<Country>(entityName: "Country")
		request.predicate = NSPredicate(format: "SUBQUERY(provinces, $x, ANY $x.cities.population > 10000000).@count != 0")
		let result2 = try! context.fetch(request)
		
		XCTAssertEqual(result1, result2)
	}
	
	func testIn() {
		let context = persistentContainer.viewContext

		let result1 = try! context
			.from(Country.self)
			.filter((\Country.name).in(["Belarus", "United States of America"]))
			.fetch()

		let result2 = try! context
			.from(Country.self)
			.filter((\Country.name).in(Set(["Belarus", "United States of America"])))
			.fetch()

		let result3 = try! context
			.from(Country.self)
			.filter((\Country.name).in(Set(["Belarus", "United States of America"]) as NSSet))
			.fetch()

		
		let request = NSFetchRequest<Country>(entityName: "Country")
		request.predicate = NSPredicate(format: "name in %@", ["Belarus", "United States of America"])
		let result4 = try! context.fetch(request)
		
		XCTAssertEqual(result1, result2)
		XCTAssertEqual(result1, result3)
		XCTAssertEqual(result1, result4)
	}

	func testSelf() {
		let context = persistentContainer.viewContext
		
		let country = try! context.from(Country.self).first()
		
		let result1 = try! context
			.from(Country.self)
			.filter(Self == country)
			.select([Self.as(NSManagedObjectID.self, name: "self")])
			.first()
		
		let request = NSFetchRequest<NSDictionary>(entityName: "Country")
		request.predicate = NSPredicate(format: "self == %@", country!)
		request.resultType = .dictionaryResultType
		
		let p1 = NSExpressionDescription()
		p1.expression = NSExpression(format: "self")
		p1.expressionResultType = .objectIDAttributeType
		p1.name = "self"

		
		request.propertiesToFetch = [p1]
		let result2 = try! context.fetch(request).first
		
		XCTAssertEqual(result1, result2)
	}
	
	func testFRC() {
		let context = persistentContainer.viewContext
		let result1 = context
			.from(Province.self)
			.sort(by: \Province.country?.name, ascending: true)
			.sort(by: \Province.name, ascending: true)
			.fetchedResultsController(sectionName: \Province.country?.name)
		
		let request = NSFetchRequest<Province>(entityName: "Province")
		request.sortDescriptors = [NSSortDescriptor(key: "country.name", ascending: true), NSSortDescriptor(key: "name", ascending: true)]
		let result2 = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "country.name", cacheName: nil)

		XCTAssertEqual(result1.fetchRequest, result2.fetchRequest)
		XCTAssertEqual(result1.sectionNameKeyPath, result2.sectionNameKeyPath)
	}

	func testDelete() {
		let country = Country(context: persistentContainer.viewContext)
		country.name = "Test"
		let provinces = ["TestProvince1", "TestProvince2", "TestProvince3"].map { provinceName -> Province in
			let province = Province(context: persistentContainer.viewContext)
			province.name = provinceName
			province.country = country
			for cityName in ["TestCity1", "TestCity2", "TestCity3"] {
				let city = City(context: persistentContainer.viewContext)
				city.province = province
				city.name = "\(provinceName)_\(cityName)"
			}
			return province
		}
		
		try! persistentContainer.viewContext.save()
		
		try! persistentContainer.viewContext
			.from(City.self)
			.filter(\City.province?.country == country)
			.delete()
		
		try! persistentContainer.viewContext.save()

		let result1 = try! persistentContainer.viewContext
			.from(City.self)
			.filter(\City.province?.country == country)
			.count()

		XCTAssertEqual(result1, 0)
		
		try! persistentContainer.viewContext
			.from(Country.self)
			.filter(\Country.name == "Test")
			.delete()
		
		XCTAssertEqual(country.isDeleted, true)
		XCTAssertTrue(provinces.allSatisfy({$0.isDeleted == true}))
		
		try! persistentContainer.viewContext.save()

		XCTAssertEqual(country.isFault, true)
		XCTAssertTrue(provinces.allSatisfy({$0.isFault == true}))
	}
	
	func testUpdate() {
		let country = Country(context: persistentContainer.viewContext)
		country.name = "TestUpdate"

		let province = Province(context: persistentContainer.viewContext)
		province.name = "TestUpdate_Province1"
		province.country = country
		
		let cities = [("City1", 100), ("City2", 200), ("City1", 300)].map { i -> City in
			let city = City(context: persistentContainer.viewContext)
			city.province = province
			city.name = "\(province.name!)_\(i.0)"
			city.population = Int32(i.1)
			return city
		}

		try! persistentContainer.viewContext.save()

		try! persistentContainer.viewContext
			.from(City.self)
			.filter((\City.name).beginsWith("TestUpdate"))
			.update(\City.population, to: 1000)
			.perform()
		
		XCTAssertEqual(cities.map{$0.population}, [1000, 1000, 1000])
	}
	
	static var persistentContainer: NSPersistentContainer = {
		let model = NSManagedObjectModel(contentsOf: Bundle(for: Expressible_Tests.self).url(forResource: "Example", withExtension: "momd")!)!
		let container = NSPersistentContainer(name: "Example", managedObjectModel: model)
		
		if let url = container.persistentStoreDescriptions.first?.url, FileManager.default.fileExists(atPath: url.path) {
			try? FileManager.default.removeItem(at: url)
		}
		
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		
		seed(viewContext: container.viewContext)
		return container
	}()
	
	lazy var persistentContainer: NSPersistentContainer = {
		return Expressible_Tests.persistentContainer
	}()
	
	func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
	static func seed(viewContext: NSManagedObjectContext) {
		
		let s = try! String(contentsOf: Bundle(for: Expressible_Tests.self).url(forResource: "worldcities", withExtension: "csv")!)
		var columnsMap: [String: Int]?
		var countries = [String: Country]()
		var provinces = [String: Province]()
		
		for row in s.components(separatedBy: "\r\n") {
			guard !row.isEmpty else {continue}
			let columns = self.columns(from: row)
			assert(columns.count == 9)
			if columnsMap == nil {
				columnsMap = Dictionary(uniqueKeysWithValues: columns.enumerated().map{($0.1, $0.0)})
			}
			else {
				let provinceName = columns[columnsMap!["province"]!]
				let city = City(context: viewContext)
				city.name = columns[columnsMap!["city"]!]
				city.population = ((columns[columnsMap!["pop"]!]) as NSString).intValue
				if let province = provinces[provinceName] {
					city.province = province
				}
				else {
					let countryName = columns[columnsMap!["country"]!]
					let province = Province(context: viewContext)
					provinces[provinceName] = province
					city.province = province
					province.name = provinceName
					if let country = countries[countryName] {
						province.country = country
					}
					else {
						let country = Country(context: viewContext)
						countries[countryName] = country
						country.name = countryName
						province.country = country
					}
				}
			}
		}
		try? viewContext.save()
	}
	
	static func columns(from csv: String) -> [String] {
		var result = [String]()
		var i = csv.startIndex
		
		while i != csv.endIndex {
			if csv[i] == "," {
				i = csv.index(after: i)
				if i == csv.endIndex {
					result.append("")
					break
				}
			}
			
			if csv[i] == "\"" {
				i = csv.index(after: i)
				let r = csv[i...].range(of: "\"")!
				result.append(String(csv[i..<r.lowerBound]))
				i = r.upperBound
			}
			else {
				let r = csv[i...].range(of: ",")
				result.append(String(csv[i..<(r?.lowerBound ?? csv.endIndex)]))
				i = r?.lowerBound ?? csv.endIndex
			}
			
		}
		return result
	}
}
