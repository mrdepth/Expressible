# Expressible
Expressible library helps you to fetch data from CoreData.

## Requirements
- iOS 10.0+
- Swift 4.1+

## Usage

### Sample 1
```swift
let result1 = try context.from(City.self).count()
```
			
Equivalent to:
```swift
let request = NSFetchRequest<NSNumber>(entityName: "City")
request.resultType = .countResultType
let result2 = try context.fetch(request).first?.intValue ?? 0
```

### Sample 2
```swift
let result1 = try context
  .from(City.self)
  .filter(\City.population > 1_000_000)
  .sort(by: \City.population, ascending: false)
  .sort(by: \City.name, ascending: true)
  .all()
```
			
Equivalent to:
```swift
let request = NSFetchRequest<City>(entityName: "City")
request.predicate = NSPredicate(format: "population > 1000000")
request.sortDescriptors = [NSSortDescriptor(key: "population", ascending: false), NSSortDescriptor(key: "name", ascending: true)]
let result2 = try context.fetch(request)
```

### Sample 3
```swift
let result1 = try context
  .from(City.self)
  .group(by: [(\City.province?.name).as(String.self, name: "province")])
  .having(\City.province?.country?.name == "Belarus")
  .select([
          (\City.province?.name).as(String.self, name: "province"),
          (\City.population).sum.as(Int.self, name: "population")
          ])
  .all()
```
			
Equivalent to:
```swift
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
```

### Sample 4
```swift
let result1 = try context
  .from(Country.self)
  .filter((\Country.provinces).subquery((\Province.cities).any(\City.population) > 10_000_000).count != 0)
  .all()
```
			
Equivalent to:
```swift
let request = NSFetchRequest<Country>(entityName: "Country")
request.predicate = NSPredicate(format: "SUBQUERY(provinces, $x, ANY $x.cities.population > 10000000).@count != 0")
let result2 = try context.fetch(request)
```
