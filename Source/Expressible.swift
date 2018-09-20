//
//  Expressible.swift
//  Expressible
//
//  Created by Artem Shimanski on 02.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

//MARK: - Grammar

extension Expressible {
	
	public func `in`(_ rhs: Expressible) -> Predictable { return ComparisonPredicate(lhs: self, rhs: rhs, operator: .in) }
	public func `as`<T>(_ type: T.Type, name: String) -> PropertyDescriptionConvertible { return CastExpression<T>(base: self, name: name) }
}

extension StringExpressible {
	public var caseInsensitive: Expressible {
		return CaseInsensitiveExpression(base: self)
		
	}
	public func like(_ rhs: StringExpressible) -> Predictable { return ComparisonPredicate(lhs: self, rhs: rhs, operator: .like) }
	public func beginsWith(_ rhs: StringExpressible) -> Predictable { return ComparisonPredicate(lhs: self, rhs: rhs, operator: .beginsWith) }
	public func endsWith(_ rhs: StringExpressible) -> Predictable { return ComparisonPredicate(lhs: self, rhs: rhs, operator: .endsWith) }
	public func contains(_ rhs: StringExpressible) -> Predictable { return ComparisonPredicate(lhs: self, rhs: rhs, operator: .contains) }
	public func matches(_ rhs: StringExpressible) -> Predictable { return ComparisonPredicate(lhs: self, rhs: rhs, operator: .matches) }
}

public func == (lhs: Expressible, rhs: Expressible?) -> Predictable { return ComparisonPredicate(lhs: lhs, rhs: rhs ?? Null(), operator: .equalTo)}
public func != (lhs: Expressible, rhs: Expressible?) -> Predictable { return ComparisonPredicate(lhs: lhs, rhs: rhs ?? Null(), operator: .notEqualTo)}
public func >= (lhs: Expressible, rhs: Expressible) -> Predictable { return ComparisonPredicate(lhs: lhs, rhs: rhs, operator: .greaterThanOrEqualTo)}
public func <= (lhs: Expressible, rhs: Expressible) -> Predictable { return ComparisonPredicate(lhs: lhs, rhs: rhs, operator: .lessThanOrEqualTo)}
public func > (lhs: Expressible, rhs: Expressible) -> Predictable { return ComparisonPredicate(lhs: lhs, rhs: rhs, operator: .greaterThan)}
public func < (lhs: Expressible, rhs: Expressible) -> Predictable { return ComparisonPredicate(lhs: lhs, rhs: rhs, operator: .lessThan)}

public func + (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "add:to:")}
public func - (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "from:subtract")}
public func * (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "multiply:by:")}
public func / (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "divide:by:")}
public func % (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "modulus:by:")}
public func & (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "bitwiseAnd:with:")}
public func | (lhs: NumericExpressible, rhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs, rhs], function: "bitwiseXor:with:")}
public prefix func ~ (lhs: NumericExpressible) -> NumericExpressible { return FunctionExpression(arguments: [lhs], function: "onesComplement:")}

public prefix func ! (lhs: Predictable) -> Predictable { return NotPredicate(base: lhs) }
public func && (lhs: Predictable, rhs: Predictable) -> Predictable { return CompoundPredicate(lhs: lhs, rhs: rhs, logicalType: .and)}
public func || (lhs: Predictable, rhs: Predictable) -> Predictable { return CompoundPredicate(lhs: lhs, rhs: rhs, logicalType: .or)}

extension Expressible {
	public var count: NumericExpressible { return FunctionExpression(arguments: [self], function: "count:") }
}

extension NumericExpressible {
	public var average: NumericExpressible { return FunctionExpression(arguments: [self], function: "average:") }
	public var sum: NumericExpressible { return FunctionExpression(arguments: [self], function: "sum:") }
	public var min: NumericExpressible { return FunctionExpression(arguments: [self], function: "min:") }
	public var max: NumericExpressible { return FunctionExpression(arguments: [self], function: "max:") }
	public var abs: NumericExpressible { return FunctionExpression(arguments: [self], function: "abs:") }
}

extension KeyPath: CollectionExpressible where Value: CollectionExpressible {}
extension KeyPath: StringExpressible where Value: StringExpressible {}
extension KeyPath: NumericExpressible where Value: NumericExpressible{}

extension CollectionExpressible {
	public func any<R, V>(_ keyPath: KeyPath<R, V>) -> Expressible { return AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .any) }
	public func all<R, V>(_ keyPath: KeyPath<R, V>) -> Expressible { return AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .all) }
	public func contains(_ rhs: Expressible) -> Predictable { return ComparisonPredicate(lhs: rhs, rhs: self, operator: .in) }

	public func any<R, V: StringExpressible>(_ keyPath: KeyPath<R, V>) -> StringExpressible { return AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .any) }
	public func all<R, V: StringExpressible>(_ keyPath: KeyPath<R, V>) -> StringExpressible { return AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .all) }
	public func any<R, V: NumericExpressible>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .any) }
	public func all<R, V: NumericExpressible>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .all) }

	public func count<R, V>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return FunctionExpression(arguments: [AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .direct)], function: "count:") }
	
	public func average<R, V>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return FunctionExpression(arguments: [AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .direct)], function: "average:") }
	public func sum<R, V: NumericExpressible>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return FunctionExpression(arguments: [AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .direct)], function: "sum:") }
	public func min<R, V: NumericExpressible>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return FunctionExpression(arguments: [AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .direct)], function: "min:") }
	public func max<R, V: NumericExpressible>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return FunctionExpression(arguments: [AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .direct)], function: "max:") }
	public func abs<R, V: NumericExpressible>(_ keyPath: KeyPath<R, V>) -> NumericExpressible { return FunctionExpression(arguments: [AggregateExpression<V>(base: self, child: keyPath, comparisonModifier: .direct)], function: "abs:") }
	
	public func subquery(_ predicate: Predictable) -> CollectionExpressible { return SubqueryExpression(base: self, variable: "x", predicate: predicate) }
}


extension Int: NumericExpressible {}
extension UInt: NumericExpressible {}
extension Int16: NumericExpressible {}
extension UInt16: NumericExpressible {}
extension Int32: NumericExpressible {}
extension UInt32: NumericExpressible {}
extension Int64: NumericExpressible {}
extension UInt64: NumericExpressible {}
extension Double: NumericExpressible {}
extension Float: NumericExpressible {}
extension NSDecimalNumber: NumericExpressible {}
extension Decimal: NumericExpressible {}
extension String: StringExpressible {}
extension Substring: StringExpressible {}
extension Array: Expressible, CollectionExpressible where Element: Expressible {}
extension NSSet: CollectionExpressible {}
extension NSOrderedSet: CollectionExpressible {}
extension Date: Expressible {}
extension Data: Expressible {}
extension NSManagedObject: Expressible {}
extension Optional: StringExpressible where Wrapped: StringExpressible {}
extension Optional: Expressible where Wrapped: Expressible {}
extension Optional: CollectionExpressible where Wrapped: CollectionExpressible {}

extension Bool: Predictable {
	public func predicate(for operand: Operand) -> NSPredicate {
		return self ? NSPredicate(format: "TRUEPREDICATE") : NSPredicate(format: "FALSEPREDICATE")
	}
}

extension NSManagedObjectContext {
	public func from<T: NSManagedObject>(_ entity: T.Type) -> Request<T, T> {
		return Request(context: self, entity: self.entity(for: entity))
	}
	
	public func from<T: NSManagedObject>(_ entity: NSEntityDescription) -> Request<T, T> {
		return Request(context: self, entity: entity)
	}

}

public struct Request<Entity: NSManagedObject, Result: NSFetchRequestResult> {
	private let context: NSManagedObjectContext
	
	fileprivate init(context: NSManagedObjectContext, entity: NSEntityDescription) {
		fetchRequest = NSFetchRequest<Result>()
		fetchRequest.entity = entity
		self.context = context
	}
	
	fileprivate init<R: NSFetchRequestResult>(_ other: Request<Entity, R>) {
		context = other.context
		fetchRequest = other.fetchRequest as! NSFetchRequest<Result>
	}
	
	public let fetchRequest: NSFetchRequest<Result>
	
	public func fetchedResultsController(sectionName: PropertyDescriptionConvertible? = nil, cacheName: String? = nil) -> NSFetchedResultsController<Result> {
		return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionName?.name, cacheName: cacheName)
	}
	
	public func filter(_ predicate: Predictable ) -> Request {
		let p = predicate.predicate(for: .self)
		
		if let old = fetchRequest.predicate {
			fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [old, p])
		}
		else {
			fetchRequest.predicate = p
		}
		return self
	}
	
	public func sort<Root, Value>(by keyPath: KeyPath<Root, Value>, ascending: Bool) -> Request {
		var sort = fetchRequest.sortDescriptors ?? []
		sort.append(NSSortDescriptor(keyPath: keyPath, ascending: ascending))
		fetchRequest.sortDescriptors = sort
		return self
	}
	
	public func select(_ what: [PropertyDescriptionConvertible]) -> Request<Entity, NSDictionary> {
		fetchRequest.propertiesToFetch = what.map{$0.propertyDescription(for: .self, context: context)} + (fetchRequest.propertiesToFetch ?? [])
		fetchRequest.resultType = .dictionaryResultType
		return Request<Entity, NSDictionary>(self)
	}
	
	public func group(by expression: [PropertyDescriptionConvertible]) -> Request<Entity, NSDictionary> {
		fetchRequest.propertiesToGroupBy = expression.map{$0.propertyDescription(for: .self, context: context)} + (fetchRequest.propertiesToGroupBy ?? [])
		fetchRequest.resultType = .dictionaryResultType
		return Request<Entity, NSDictionary>(self)
	}
	
	public func having(_ predicate: Predictable ) -> Request {
		if let old = fetchRequest.havingPredicate {
			fetchRequest.havingPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [old, predicate.predicate(for: .self)])
		}
		else {
			fetchRequest.havingPredicate = predicate.predicate(for: .self)
		}
		return self
	}
	
	public func all() throws -> [Result] {
		return try context.fetch(fetchRequest)
	}
	
	public func first() throws -> Result? {
		fetchRequest.fetchLimit = 1
		return try context.fetch(fetchRequest).first
	}
	
	public func count() throws -> Int {
		fetchRequest.resultType = .countResultType
		return try context.fetch(fetchRequest as! NSFetchRequest<NSNumber>).first as? Int ?? 0
	}
	
	public func subrange(_ bounds: Range<Int>) throws -> [Result] {
		fetchRequest.fetchLimit = bounds.count
		fetchRequest.fetchOffset = bounds.lowerBound
		return try context.fetch(fetchRequest)
	}
	
	public func subrange(_ bounds: ClosedRange<Int>) throws -> [Result] {
		fetchRequest.fetchLimit = bounds.count
		fetchRequest.fetchOffset = bounds.lowerBound
		return try context.fetch(fetchRequest)
	}
}

//MARK: - Implementation

public enum Operand {
	case `self`
	case variable(String)
}

public protocol Expressible {
	func expression(for operand: Operand) -> NSExpression
	var comparisonModifier: NSComparisonPredicate.Modifier {get}
	var comparisonOptions: NSComparisonPredicate.Options {get}
}

public protocol StringExpressible: Expressible {}

public protocol PropertyDescriptionConvertible {
	func propertyDescription(for operand: Operand, context: NSManagedObjectContext) -> NSPropertyDescription
	var name: String {get}
}

public protocol CollectionExpressible: Expressible {}
public protocol NumericExpressible: Expressible {}


extension Expressible {
	public func expression(for operand: Operand) -> NSExpression { return NSExpression(forConstantValue: self) }
	public var comparisonModifier: NSComparisonPredicate.Modifier { return .direct }
	public var comparisonOptions: NSComparisonPredicate.Options { return [] }
}

fileprivate struct AggregateExpression<Value>: Expressible {
	var base: Expressible
	var child: Expressible
	var comparisonModifier: NSComparisonPredicate.Modifier
	
	func expression(for operand: Operand) -> NSExpression { return NSExpression(format: "%@.%@", base.expression(for: operand), child.expression(for: .self)) }
	var comparisonOptions: NSComparisonPredicate.Options { return base.comparisonOptions }
	var name: String { return expression(for: .self).keyPath }
}

extension AggregateExpression: StringExpressible where Value: StringExpressible {}
extension AggregateExpression: NumericExpressible where Value: NumericExpressible {}
extension AggregateExpression: CollectionExpressible where Value: CollectionExpressible {}

fileprivate struct CaseInsensitiveExpression: Expressible {
	var base: Expressible
	func expression(for operand: Operand) -> NSExpression { return base.expression(for: operand) }
	var comparisonModifier: NSComparisonPredicate.Modifier { return base.comparisonModifier }
	var comparisonOptions: NSComparisonPredicate.Options { return base.comparisonOptions.union([.caseInsensitive]) }
}

fileprivate struct FunctionExpression: NumericExpressible {
	var arguments: [Expressible]
	var function: String
	func expression(for operand: Operand) -> NSExpression { return NSExpression(forFunction: function, arguments: arguments.map{$0.expression(for: operand)}) }
	var comparisonOptions: NSComparisonPredicate.Options { return arguments[0].comparisonOptions }
}

fileprivate struct CastExpression<T>: Expressible, PropertyDescriptionConvertible {
	var base: Expressible
	var name: String
	func expression(for operand: Operand) -> NSExpression { return base.expression(for: operand) }
	var comparisonModifier: NSComparisonPredicate.Modifier { return base.comparisonModifier }
	var comparisonOptions: NSComparisonPredicate.Options { return base.comparisonOptions }
	
	func propertyDescription(for operand: Operand, context: NSManagedObjectContext) -> NSPropertyDescription {
		let expressionDescription = NSExpressionDescription()
		expressionDescription.name = name
		expressionDescription.expression = expression(for: operand)
		switch T.self {
		case is Int16.Type:
			expressionDescription.expressionResultType = .integer16AttributeType
		case is Int32.Type, is Int.Type:
			expressionDescription.expressionResultType = .integer32AttributeType
		case is Int64.Type:
			expressionDescription.expressionResultType = .integer64AttributeType
		case is Decimal.Type:
			expressionDescription.expressionResultType = .decimalAttributeType
		case is Double.Type:
			expressionDescription.expressionResultType = .doubleAttributeType
		case is Float.Type:
			expressionDescription.expressionResultType = .floatAttributeType
		case is String.Type:
			expressionDescription.expressionResultType = .stringAttributeType
		case is Bool.Type:
			expressionDescription.expressionResultType = .booleanAttributeType
		case is Date.Type:
			expressionDescription.expressionResultType = .dateAttributeType
		case is Data.Type:
			expressionDescription.expressionResultType = .binaryDataAttributeType
		case is NSManagedObjectID.Type:
			expressionDescription.expressionResultType = .objectIDAttributeType
		case is URL.Type:
			if #available(iOS 11.0, *) {
				expressionDescription.expressionResultType = .URIAttributeType
			} else {
				expressionDescription.expressionResultType = .transformableAttributeType
			}
		case is UUID.Type:
			if #available(iOS 11.0, *) {
				expressionDescription.expressionResultType = .UUIDAttributeType
			} else {
				expressionDescription.expressionResultType = .transformableAttributeType
			}
		default:
			expressionDescription.expressionResultType = .transformableAttributeType
		}
		return expressionDescription
	}
}

fileprivate struct Null: Expressible {
	func expression(for operand: Operand) -> NSExpression { return NSExpression(forConstantValue: nil) }
}

public let `Self`: Expressible = EvaluatedObject()

fileprivate struct EvaluatedObject: Expressible {
	func expression(for operand: Operand) -> NSExpression { return NSExpression.expressionForEvaluatedObject() }
}

fileprivate struct SubqueryExpression: CollectionExpressible {
	var base: Expressible
	var variable: String
	var predicate: Predictable
	
	func expression(for operand: Operand) -> NSExpression {
		return NSExpression(forSubquery: base.expression(for: operand), usingIteratorVariable: variable, predicate: predicate.predicate(for: .variable(variable)))
	}
}

public protocol Predictable {
	func predicate(for operand: Operand) -> NSPredicate
}

fileprivate struct ComparisonPredicate: Predictable {
	var lhs: Expressible
	var rhs: Expressible
	var `operator`: NSComparisonPredicate.Operator
	
	func predicate(for operand: Operand) -> NSPredicate {
		return NSComparisonPredicate(leftExpression: lhs.expression(for: operand), rightExpression: rhs.expression(for: operand), modifier: lhs.comparisonModifier, type: self.operator, options: lhs.comparisonOptions.union(rhs.comparisonOptions))
	}
}

fileprivate struct NotPredicate: Predictable {
	var base: Predictable
	func predicate(for operand: Operand) -> NSPredicate { return NSCompoundPredicate(notPredicateWithSubpredicate: base.predicate(for: operand)) }
}

fileprivate struct CompoundPredicate: Predictable {
	var lhs: Predictable
	var rhs: Predictable
	var logicalType: NSCompoundPredicate.LogicalType
	func predicate(for operand: Operand) -> NSPredicate { return NSCompoundPredicate(type: logicalType, subpredicates: [lhs.predicate(for: operand), rhs.predicate(for: operand)]) }
}

extension KeyPath: Expressible {
	public func expression(for operand: Operand) -> NSExpression {
		switch operand {
		case .self:
			return NSExpression(forKeyPath: self)
		case let .variable(v):
			return NSExpression(format: "$\(v).%@", NSExpression(forKeyPath: self))
		}
	}
	var name: String { return expression(for: .self).keyPath }
}

extension KeyPath: PropertyDescriptionConvertible where Root: NSManagedObject {
	public func propertyDescription(for operand: Operand, context: NSManagedObjectContext) -> NSPropertyDescription {
		return context.entity(for: Root.self).propertiesByName[expression(for: operand).keyPath]!
	}
	
	public var name: String {
		return expression(for: .self).keyPath
	}
}

extension NSManagedObjectContext {
	fileprivate func entity<T: NSManagedObject>(for type: T.Type) -> NSEntityDescription {
		let coordinator = sequence(first: self, next: {$0.parent}).lazy.map{$0.persistentStoreCoordinator}.first {$0 != nil}
		guard let model = coordinator??.managedObjectModel else {return T.entity()}
		let className = NSStringFromClass(type)
		return model.entities.first(where: {$0.managedObjectClassName == className}) ?? T.entity()
	}
}
