//
//  AppDelegate.swift
//  Example
//
//  Created by Artem Shimanski on 02.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import Expressible

extension AppDelegate {
	func sample1() {
		do {
			let context = persistentContainer.viewContext
			let result1 = try context.from(City.self).count()
			
			//Equivalent to:
			let request = NSFetchRequest<NSNumber>(entityName: "City")
			request.resultType = .countResultType
			let result2 = try context.fetch(request).first?.intValue ?? 0
			
			assert(result1 == result2)
		}
		catch {
			print(error)
		}
	}
	
	func sample2() {
		do {
			let context = persistentContainer.viewContext
			let result1 = try context
				.from(City.self)
				.filter(\City.population > 1_000_000)
				.sort(by: \City.population, ascending: false)
				.sort(by: \City.name, ascending: true)
				.fetch()
			
			//Equivalent to:
			let request = NSFetchRequest<City>(entityName: "City")
			request.predicate = NSPredicate(format: "population > 1000000")
			request.sortDescriptors = [NSSortDescriptor(key: "population", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
			let result2 = try context.fetch(request)
			
			assert(result1 == result2)
		}
		catch {
			print(error)
		}
	}
	
	func sample3() {
		do {
			let context = persistentContainer.viewContext
			let result1 = try context
				.from(City.self)
				.group(by: [(\City.province?.name).as(String.self, name: "province")])
				.having(\City.province?.country?.name == "Belarus")
				.select([
					(\City.province?.name).as(String.self, name: "province"),
					(\City.population).sum.as(Int.self, name: "population")
					])
				.fetch()
			
			//Equivalent to:
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
			
			let result2 = try context.fetch(request)
			
			assert(result1 == result2)
		}
		catch {
			print(error)
		}
	}
	
	func sample4() {
		do {
			let context = persistentContainer.viewContext
			
			let result1 = try context
				.from(Country.self)
				.filter((\Country.provinces).subquery((\Province.cities).any(\City.population) > 10_000_000).count != 0)
				.fetch()

			
			//Equivalent to:
			let request = NSFetchRequest<Country>(entityName: "Country")
			request.predicate = NSPredicate(format: "SUBQUERY(provinces, $x, ANY $x.cities.population > 10000000).@count != 0")
			let result2 = try context.fetch(request)
			
			assert(result1 == result2)
		}
		catch {
			print(error)
		}
	}
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		sample1()
		sample2()
		sample3()
		sample4()
		// Override point for customization after application launch.
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
		// Saves changes in the application's managed object context before the application terminates.
		self.saveContext()
	}

	// MARK: - Core Data stack

	lazy var persistentContainer: NSPersistentContainer = {
	    /*
	     The persistent container for the application. This implementation
	     creates and returns a container, having loaded the store for the
	     application to it. This property is optional since there are legitimate
	     error conditions that could cause the creation of the store to fail.
	    */
	    let container = NSPersistentContainer(name: "Example")
		
		var needsSeed = true
		if let url = container.persistentStoreDescriptions.first?.url, FileManager.default.fileExists(atPath: url.path) {
			needsSeed = false
		}

	    container.loadPersistentStores(completionHandler: { (storeDescription, error) in
	        if let error = error as NSError? {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	             
	            /*
	             Typical reasons for an error here include:
	             * The parent directory does not exist, cannot be created, or disallows writing.
	             * The persistent store is not accessible, due to permissions or data protection when the device is locked.
	             * The device is out of space.
	             * The store could not be migrated to the current model version.
	             Check the error message to determine what the actual problem was.
	             */
	            fatalError("Unresolved error \(error), \(error.userInfo)")
	        }
	    })
		
		if needsSeed {
			seed(viewContext: container.viewContext)
		}

	    return container
	}()

	// MARK: - Core Data Saving support

	func saveContext () {
	    let context = persistentContainer.viewContext
	    if context.hasChanges {
	        do {
	            try context.save()
	        } catch {
	            // Replace this implementation with code to handle the error appropriately.
	            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	            let nserror = error as NSError
	            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
	        }
	    }
	}
	

}

extension AppDelegate {
	func seed(viewContext: NSManagedObjectContext) {
		let s = try! String(contentsOf: Bundle.main.url(forResource: "worldcities", withExtension: "csv")!)
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
	
	func columns(from csv: String) -> [String] {
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
