//
//  Expressible.swift
//  Expressible
//
//  Created by Artem Shimanski on 2/17/20.
//  Copyright © 2020 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData

public enum Operand {
    case `self`
    case variable(String)
}

public struct Expressions {
    public static func constant<Value>(_ value: Value) -> ConstantExpression<Value> {
        ConstantExpression(constant: value)
    }
}

prefix operator /

extension KeyPath {
    public static prefix func / (_ keyPath: KeyPath) -> KeyPathExpression<Root, Value> {
        KeyPathExpression(keyPath: keyPath)
    }
}

extension KeyPath where Root == Value {
    public static prefix func / (_ keyPath: KeyPath) -> SelfExpression<Root> {
        SelfExpression()
    }
}


public protocol PredicateProtocol {
    func predicate(for operand: Operand) -> NSPredicate
}

extension PredicateProtocol {
    public func predicate() -> NSPredicate {
        return predicate(for: .`self`)
    }
}

public protocol ExpressionProtocol {
    associatedtype Value
    func expression(for operand: Operand) -> NSExpression
    var comparisonModifier: NSComparisonPredicate.Modifier {get}
    var comparisonOptions: NSComparisonPredicate.Options {get}
}

extension ExpressionProtocol {
    public var comparisonModifier: NSComparisonPredicate.Modifier { return .direct }
    public var comparisonOptions: NSComparisonPredicate.Options { return [] }
    
    public func `in`<T: ExpressionProtocol>(_ rhs: T) -> CollectionCompare<Self, T> where T.Value: CollectionType {
        CollectionCompare(lhs: self, rhs: rhs, operator: .in)
    }

    public func `in`<T: CollectionType>(_ rhs: T) -> CollectionCompare<Self, ConstantExpression<T>> {
        CollectionCompare(lhs: self, rhs: Expressions.constant(rhs), operator: .in)
    }

    public func `as`<T>(_ type: T.Type = T.self, name: String) -> CastExpression<Self, T> {
        CastExpression(base: self, name: name)
    }

}

public struct ConstantPredicate: PredicateProtocol {
    public var value: Bool
    public func predicate(for operand: Operand) -> NSPredicate {
        value ? NSPredicate(format: "TRUEPREDICATE") : NSPredicate(format: "FALSEPREDICATE")
    }
}

public struct AndPredicate: PredicateProtocol {
    public var lhs: PredicateProtocol
    public var rhs: PredicateProtocol
    
    public func predicate(for operand: Operand) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [lhs.predicate(for: operand), rhs.predicate(for: operand)])
    }
}

public struct OrPredicate: PredicateProtocol {
    public var lhs: PredicateProtocol
    public var rhs: PredicateProtocol
    
    public func predicate(for operand: Operand) -> NSPredicate {
        NSCompoundPredicate(orPredicateWithSubpredicates: [lhs.predicate(for: operand), rhs.predicate(for: operand)])
    }

}

public struct NotPredicate: PredicateProtocol {
    public var argument: PredicateProtocol
    
    public func predicate(for operand: Operand) -> NSPredicate {
        NSCompoundPredicate(notPredicateWithSubpredicate: argument.predicate(for: operand))
    }
}

public struct Compare<Lhs: ExpressionProtocol, Rhs: ExpressionProtocol>: PredicateProtocol where Lhs.Value == Rhs.Value, Lhs.Value: ComparableType {
    public var lhs: Lhs
    public var rhs: Rhs
    public var `operator`: NSComparisonPredicate.Operator
    public var comparisonModifier: NSComparisonPredicate.Modifier { lhs.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { lhs.comparisonOptions.union(rhs.comparisonOptions) }

    public func predicate(for operand: Operand) -> NSPredicate {
        NSComparisonPredicate(leftExpression: lhs.expression(for: operand),
                              rightExpression: rhs.expression(for: operand),
                              modifier: comparisonModifier,
                              type: self.operator,
                              options: comparisonOptions)
    }
}

public struct CompareOptional<Lhs: ExpressionProtocol, Rhs: ExpressionProtocol>: PredicateProtocol where Lhs.Value? == Rhs.Value, Lhs.Value: ComparableType {
    public var lhs: Lhs
    public var rhs: Rhs
    public var `operator`: NSComparisonPredicate.Operator
    public var comparisonModifier: NSComparisonPredicate.Modifier { lhs.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { lhs.comparisonOptions.union(rhs.comparisonOptions) }

    public func predicate(for operand: Operand) -> NSPredicate {
        NSComparisonPredicate(leftExpression: lhs.expression(for: operand),
                              rightExpression: rhs.expression(for: operand),
                              modifier: comparisonModifier,
                              type: self.operator,
                              options: comparisonOptions)
    }
}

public struct CollectionCompare<Lhs: ExpressionProtocol, Rhs: ExpressionProtocol>: PredicateProtocol {
    public var lhs: Lhs
    public var rhs: Rhs
    public var `operator`: NSComparisonPredicate.Operator
    public var comparisonModifier: NSComparisonPredicate.Modifier { lhs.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { lhs.comparisonOptions.union(rhs.comparisonOptions) }

    public func predicate(for operand: Operand) -> NSPredicate {
        NSComparisonPredicate(leftExpression: lhs.expression(for: operand),
                              rightExpression: rhs.expression(for: operand),
                              modifier: comparisonModifier,
                              type: self.operator,
                              options: comparisonOptions)
    }

}
public struct ConstantExpression<Value>: ExpressionProtocol {
    public var constant: Value?
    
    public func expression(for operand: Operand) -> NSExpression {
        return NSExpression(forConstantValue: constant)
    }
}

public struct KeyPathExpression<Root, Value>: ExpressionProtocol {
    public var keyPath: KeyPath<Root, Value>
    public func expression(for operand: Operand) -> NSExpression {
        switch operand {
        case .self:
            return NSExpression(forKeyPath: keyPath)
        case let .variable(v):
            return NSExpression(format: "$\(v).%@", NSExpression(forKeyPath: keyPath))
        }
    }
}

public struct AggregateExpression<Base: ExpressionProtocol, Child: ExpressionProtocol, Value>: ExpressionProtocol where Child.Value == Value {
    public var base: Base
    public var child: Child
    public var comparisonModifier: NSComparisonPredicate.Modifier
    public var comparisonOptions: NSComparisonPredicate.Options { base.comparisonOptions }
    
    public func expression(for operand: Operand) -> NSExpression {
        NSExpression(format: "%@.%@", base.expression(for: operand), child.expression(for: .self))
    }
}

public struct BinaryFunctionExpression<Lhs: ExpressionProtocol, Rhs: ExpressionProtocol, Value>: ExpressionProtocol where Lhs.Value == Value, Rhs.Value == Value {
    public var lhs: Lhs
    public var rhs: Rhs
    public var function: String
    public var comparisonModifier: NSComparisonPredicate.Modifier { lhs.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { lhs.comparisonOptions.union(rhs.comparisonOptions) }
    
    public func expression(for operand: Operand) -> NSExpression {
        return NSExpression(forFunction: function, arguments: [lhs.expression(for: operand), lhs.expression(for: operand)])
    }

}

public struct UnaryFunctionExpression<T: ExpressionProtocol, Value>: ExpressionProtocol {
    public var argument: T
    public var function: String
    public var comparisonModifier: NSComparisonPredicate.Modifier { .direct }
    public var comparisonOptions: NSComparisonPredicate.Options { argument.comparisonOptions }

    public func expression(for operand: Operand) -> NSExpression {
        return NSExpression(forFunction: function, arguments: [argument.expression(for: operand)])
    }
}

public struct SelfExpression<Value>: ExpressionProtocol {
    public func expression(for operand: Operand) -> NSExpression {
        return NSExpression.expressionForEvaluatedObject()
    }
}

public protocol ComparableType {}
extension String: ComparableType {}
extension NSString: ComparableType {}
extension Int: ComparableType {}
extension Int32: ComparableType {}
extension Int64: ComparableType {}
extension UInt: ComparableType {}
extension UInt32: ComparableType {}
extension UInt64: ComparableType {}
extension Bool: ComparableType {}
extension Float: ComparableType {}
extension Double: ComparableType {}
extension NSNumber: ComparableType {}
extension Optional: ComparableType where Wrapped: ComparableType {}
extension NSManagedObject: ComparableType {}
extension NSManagedObjectID: ComparableType{}

extension ExpressionProtocol where Value: ComparableType {
    public static func < <T: ExpressionProtocol> (lhs: Self, rhs: T) -> Compare<Self, T> where T.Value == Value {
        Compare(lhs: lhs, rhs: rhs, operator: .lessThan)
    }
    public static func <= <T: ExpressionProtocol> (lhs: Self, rhs: T) -> Compare<Self, T> where T.Value == Value {
        Compare(lhs: lhs, rhs: rhs, operator: .lessThanOrEqualTo)
    }
    public static func > <T: ExpressionProtocol> (lhs: Self, rhs: T) -> Compare<Self, T> where T.Value == Value {
        Compare(lhs: lhs, rhs: rhs, operator: .greaterThan)
    }
    public static func >= <T: ExpressionProtocol> (lhs: Self, rhs: T) -> Compare<Self, T> where T.Value == Value {
        Compare(lhs: lhs, rhs: rhs, operator: .greaterThanOrEqualTo)
    }
    public static func == <T: ExpressionProtocol> (lhs: Self, rhs: T) -> Compare<Self, T> where T.Value == Value {
        Compare(lhs: lhs, rhs: rhs, operator: .equalTo)
    }
    public static func != <T: ExpressionProtocol> (lhs: Self, rhs: T) -> Compare<Self, T> where T.Value == Value {
        Compare(lhs: lhs, rhs: rhs, operator: .notEqualTo)
    }

    public static func < (lhs: Self, rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        Compare(lhs: lhs, rhs: Expressions.constant(rhs), operator: .lessThan)
    }
    public static func <= (lhs: Self, rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        Compare(lhs: lhs, rhs: Expressions.constant(rhs), operator: .lessThanOrEqualTo)
    }
    public static func > (lhs: Self, rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        Compare(lhs: lhs, rhs: Expressions.constant(rhs), operator: .greaterThan)
    }
    public static func >= (lhs: Self, rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        Compare(lhs: lhs, rhs: Expressions.constant(rhs), operator: .greaterThanOrEqualTo)
    }
    public static func == (lhs: Self, rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        Compare(lhs: lhs, rhs: Expressions.constant(rhs), operator: .equalTo)
    }
    public static func == (lhs: Self, rhs: Value?) -> CompareOptional<Self, ConstantExpression<Value?>> {
        CompareOptional(lhs: lhs, rhs: Expressions.constant(rhs), operator: .equalTo)
    }
    public static func != (lhs: Self, rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        Compare(lhs: lhs, rhs: Expressions.constant(rhs), operator: .notEqualTo)
    }
}

public protocol NumberConvertible {}

extension Int: NumberConvertible {}
extension Int32: NumberConvertible {}
extension Int64: NumberConvertible {}
extension UInt: NumberConvertible {}
extension UInt32: NumberConvertible {}
extension UInt64: NumberConvertible {}
extension Float: NumberConvertible {}
extension Double: NumberConvertible {}
extension NSNumber: NumberConvertible {}

extension ExpressionProtocol where Value: NumberConvertible {
    public static func +<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "add:to:")
    }
    public static func -<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "from:subtract:")
    }
    public static func *<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "multiply:by:")
    }
    public static func /<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "divide:by:")
    }
    public static func %<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "modulus:by:")
    }
    public static func &<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "bitwiseAnd:with:")
    }
    public static func |<T: ExpressionProtocol> (lhs: Self, rhs: T) -> BinaryFunctionExpression<Self, T, Value> where T.Value == Value {
        BinaryFunctionExpression(lhs: lhs, rhs: rhs, function: "bitwiseXor:with:")
    }
    public static prefix func ~ (lhs: Self) -> UnaryFunctionExpression<Self, Value> {
        UnaryFunctionExpression(argument: lhs, function: "onesComplement:")
    }
    
    public static func + (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "add:to:")
    }
    public static func - (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "from:subtract:")
    }
    public static func * (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "multiply:by:")
    }
    public static func / (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "divide:by:")
    }
    public static func % (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "modulus:by:")
    }
    public static func & (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "bitwiseAnd:with:")
    }
    public static func | (lhs: Self, rhs: Value) -> BinaryFunctionExpression<Self, ConstantExpression<Value>, Value> {
        BinaryFunctionExpression(lhs: lhs, rhs: Expressions.constant(rhs), function: "bitwiseXor:with:")
    }
    
    public var average: UnaryFunctionExpression<Self, Double> {
        UnaryFunctionExpression(argument: self, function: "average:")
    }
    public var sum: UnaryFunctionExpression<Self, Value> {
        UnaryFunctionExpression(argument: self, function: "sum:")
    }
    public var min: UnaryFunctionExpression<Self, Value> {
        UnaryFunctionExpression(argument: self, function: "min:")
    }
    public var max: UnaryFunctionExpression<Self, Value> {
        UnaryFunctionExpression(argument: self, function: "max:")
    }
    public var abs: UnaryFunctionExpression<Self, Value> {
        UnaryFunctionExpression(argument: self, function: "abs:")
    }

}

public protocol CollectionType {
    associatedtype Element
}
extension Array: CollectionType {}
extension Set: CollectionType {}
extension NSSet: CollectionType {}
extension NSOrderedSet: CollectionType {}
extension Optional: CollectionType where Wrapped: CollectionType {
    public typealias Element = Wrapped.Element
}

public protocol StringType: ComparableType {}
extension String: StringType {}
extension NSString: StringType {}
extension Optional: StringType where Wrapped: StringType {}

extension ExpressionProtocol where Value: StringType {
    public func like<T: ExpressionProtocol>(_ rhs: T) -> Compare<Self, T> where T.Value == Value {
        return Compare(lhs: self, rhs: rhs, operator: .like)
    }
    public func beginsWith<T: ExpressionProtocol>(_ rhs: T) -> Compare<Self, T> where T.Value == Value {
        return Compare(lhs: self, rhs: rhs, operator: .beginsWith)
    }
    public func endsWith<T: ExpressionProtocol>(_ rhs: T) -> Compare<Self, T> where T.Value == Value {
        return Compare(lhs: self, rhs: rhs, operator: .endsWith)
    }
    public func contains<T: ExpressionProtocol>(_ rhs: T) -> Compare<Self, T> where T.Value == Value {
        return Compare(lhs: self, rhs: rhs, operator: .contains)
    }
    public func matches<T: ExpressionProtocol>(_ rhs: T) -> Compare<Self, T> where T.Value == Value {
        return Compare(lhs: self, rhs: rhs, operator: .matches)
    }

    public func like(_ rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        like(Expressions.constant(rhs))
    }
    public func beginsWith(_ rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        beginsWith(Expressions.constant(rhs))
    }
    public func endsWith(_ rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        endsWith(Expressions.constant(rhs))
    }
    public func contains(_ rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        contains(Expressions.constant(rhs))
    }
    public func matches(_ rhs: Value) -> Compare<Self, ConstantExpression<Value>> {
        matches(Expressions.constant(rhs))
    }

    public var caseInsensitive: CaseInsensitiveExpression<Self> {
        return CaseInsensitiveExpression(base: self)
    }
}

extension ExpressionProtocol where Value: CollectionType {
    public func any<R, V>(_ keyPath: KeyPath<R, V>) -> AggregateExpression<Self, KeyPathExpression<R, V>, V> {
        AggregateExpression(base: self, child: /keyPath, comparisonModifier: .any)
    }
    public func all<R, V>(_ keyPath: KeyPath<R, V>) -> AggregateExpression<Self, KeyPathExpression<R, V>, V> {
        AggregateExpression(base: self, child: /keyPath, comparisonModifier: .all)
    }
    
    public func contains<T: ExpressionProtocol>(_ rhs: T) -> CollectionCompare<Self, T> where T.Value == Value.Element {
        CollectionCompare(lhs: self, rhs: rhs, operator: .contains)
    }
    public func contains(_ rhs: Value.Element) -> CollectionCompare<Self, ConstantExpression<Value.Element>> {
        contains(Expressions.constant(rhs))
    }
    
    public func count<R, V>(_ keyPath: KeyPath<R, V>) -> UnaryFunctionExpression<AggregateExpression<Self, KeyPathExpression<R, V>, V>, Int> {
        UnaryFunctionExpression(argument: AggregateExpression(base: self, child: /keyPath, comparisonModifier: .direct), function: "count:")
    }
    public func average<R, V>(_ keyPath: KeyPath<R, V>) -> UnaryFunctionExpression<AggregateExpression<Self, KeyPathExpression<R, V>, V>, Double> {
        UnaryFunctionExpression(argument: AggregateExpression(base: self, child: /keyPath, comparisonModifier: .direct), function: "average:")
    }
    public func sum<R, V>(_ keyPath: KeyPath<R, V>) -> UnaryFunctionExpression<AggregateExpression<Self, KeyPathExpression<R, V>, V>, Double> {
        UnaryFunctionExpression(argument: AggregateExpression(base: self, child: /keyPath, comparisonModifier: .direct), function: "sum:")
    }
    public func min<R, V>(_ keyPath: KeyPath<R, V>) -> UnaryFunctionExpression<AggregateExpression<Self, KeyPathExpression<R, V>, V>, Double> {
        UnaryFunctionExpression(argument: AggregateExpression(base: self, child: /keyPath, comparisonModifier: .direct), function: "min:")
    }
    public func max<R, V>(_ keyPath: KeyPath<R, V>) -> UnaryFunctionExpression<AggregateExpression<Self, KeyPathExpression<R, V>, V>, Double> {
        UnaryFunctionExpression(argument: AggregateExpression(base: self, child: /keyPath, comparisonModifier: .direct), function: "max:")
    }
    public func abs<R, V>(_ keyPath: KeyPath<R, V>) -> UnaryFunctionExpression<AggregateExpression<Self, KeyPathExpression<R, V>, V>, Double> {
        UnaryFunctionExpression(argument: AggregateExpression(base: self, child: /keyPath, comparisonModifier: .direct), function: "abs:")
    }

    public func subquery(_ predicate: PredicateProtocol) -> SubqueryExpression<Self, Value> {
        SubqueryExpression(base: self, variable: "x", predicate: predicate)
    }

}

extension ExpressionProtocol {
    public var count: UnaryFunctionExpression<Self, Int> {
        UnaryFunctionExpression(argument: self, function: "count:")
    }
}

public func && (lhs: PredicateProtocol, rhs: PredicateProtocol) -> PredicateProtocol {
    return AndPredicate(lhs: lhs, rhs: rhs)
}

public func || (lhs: PredicateProtocol, rhs: PredicateProtocol) -> PredicateProtocol {
    return OrPredicate(lhs: lhs, rhs: rhs)
}

public prefix func ! (lhs: PredicateProtocol) -> PredicateProtocol {
    return NotPredicate(argument: lhs)
}

public struct CaseInsensitiveExpression<Base: ExpressionProtocol>: ExpressionProtocol where Base.Value: StringType {
    public typealias Value = String
    public var base: Base
    public var comparisonModifier: NSComparisonPredicate.Modifier { base.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { base.comparisonOptions.union([.caseInsensitive]) }

    public func expression(for operand: Operand) -> NSExpression {
        base.expression(for: operand)
    }
}

public struct SubqueryExpression<Base: ExpressionProtocol, Value: CollectionType>: ExpressionProtocol where Base.Value == Value {
    public var base: Base
    public var variable: String
    public var predicate: PredicateProtocol
    public var comparisonModifier: NSComparisonPredicate.Modifier { base.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { base.comparisonOptions }

    public func expression(for operand: Operand) -> NSExpression {
        NSExpression(forSubquery: base.expression(for: operand),
                     usingIteratorVariable: variable,
                     predicate: predicate.predicate(for: .variable(variable)))
    }

}

public struct CastExpression<Base: ExpressionProtocol, Value>: ExpressionProtocol, PropertyDescriptionConvertible {
    public var base: Base
    public var name: String
    public var comparisonModifier: NSComparisonPredicate.Modifier { base.comparisonModifier }
    public var comparisonOptions: NSComparisonPredicate.Options { base.comparisonOptions }

    public func expression(for operand: Operand) -> NSExpression {
        base.expression(for: operand)
    }

    public func propertyDescription(for operand: Operand, context: NSManagedObjectContext) -> NSPropertyDescription {
        let expressionDescription = NSExpressionDescription()
        expressionDescription.name = name
        expressionDescription.expression = expression(for: operand)
        
        switch Value.self {
        case is Int16.Type, is Int16?.Type:
            expressionDescription.expressionResultType = .integer16AttributeType
        case is Int32.Type, is Int.Type, is Int32?.Type, is Int?.Type:
            expressionDescription.expressionResultType = .integer32AttributeType
        case is Int64.Type, is Int64?.Type:
            expressionDescription.expressionResultType = .integer64AttributeType
        case is Decimal.Type, is Decimal?.Type:
            expressionDescription.expressionResultType = .decimalAttributeType
        case is Double.Type, is Double?.Type:
            expressionDescription.expressionResultType = .doubleAttributeType
        case is Float.Type, is Float?.Type:
            expressionDescription.expressionResultType = .floatAttributeType
        case is String.Type, is String?.Type:
            expressionDescription.expressionResultType = .stringAttributeType
        case is Bool.Type, is Bool?.Type:
            expressionDescription.expressionResultType = .booleanAttributeType
        case is Date.Type, is Date?.Type:
            expressionDescription.expressionResultType = .dateAttributeType
        case is Data.Type, is Data?.Type:
            expressionDescription.expressionResultType = .binaryDataAttributeType
        case is NSManagedObjectID.Type, is NSManagedObjectID?.Type:
            expressionDescription.expressionResultType = .objectIDAttributeType
        case is URL.Type, is URL?.Type:
            if #available(iOS 11.0, *) {
                expressionDescription.expressionResultType = .URIAttributeType
            } else {
                expressionDescription.expressionResultType = .transformableAttributeType
            }
        case is UUID.Type, is UUID?.Type:
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

public protocol PropertyDescriptionConvertibleBase {
    func propertyDescription(for operand: Operand, context: NSManagedObjectContext) -> NSPropertyDescription
    var name: String {get}
}

public protocol PropertyDescriptionConvertible: PropertyDescriptionConvertibleBase {
    associatedtype Value
}

extension KeyPathExpression: PropertyDescriptionConvertibleBase, PropertyDescriptionConvertible where Root: NSManagedObject {

    public func propertyDescription(for operand: Operand, context: NSManagedObjectContext) -> NSPropertyDescription {
        context.entity(for: Root.self).propertiesByName[expression(for: operand).keyPath] ??
            self.as(Value.self, name: name).propertyDescription(for: operand, context: context)
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


extension NSManagedObjectContext {
    public func from<T: NSManagedObject>(_ entity: T.Type) -> Request<T, T, T> {
        return Request(context: self, entity: self.entity(for: entity))
    }
    
    public func from<T: NSManagedObject>(_ entity: NSEntityDescription) -> Request<T, T, T> {
        return Request(context: self, entity: entity)
    }

}

public struct Request<Entity: NSManagedObject, Result, FetchRequestResult: NSFetchRequestResult> {
    private let context: NSManagedObjectContext
    private let transform: ((FetchRequestResult) -> Result)?
    
    private var predicate: PredicateProtocol?
    private var sortDescriptors: [NSSortDescriptor]?
    private var propertiesToFetch: [PropertyDescriptionConvertibleBase]?
    private var propertiesToGroupBy: [PropertyDescriptionConvertibleBase]?
    private var havingPredicate: PredicateProtocol?
    private var entity: NSEntityDescription
    private var resultType: NSFetchRequestResultType
    private var range: Range<Int>?
    
    fileprivate init(context: NSManagedObjectContext, entity: NSEntityDescription) {
        self.entity = entity
        resultType = .managedObjectResultType
        transform = nil
        self.context = context
    }
    
    fileprivate init<R, F: NSFetchRequestResult>(_ other: Request<Entity, R, F>, transform: ((FetchRequestResult) -> Result)? = nil) {
        context = other.context
        self.transform = transform
        predicate = other.predicate
        sortDescriptors = other.sortDescriptors
        propertiesToFetch = other.propertiesToFetch
        propertiesToGroupBy = other.propertiesToGroupBy
        havingPredicate = other.havingPredicate
        entity = other.entity
        resultType = other.resultType
        range = other.range
    }
    
    public var fetchRequest: NSFetchRequest<FetchRequestResult> {
        let request = NSFetchRequest<FetchRequestResult>()
        request.entity = entity
        request.resultType = resultType
        request.predicate = predicate?.predicate(for: .self)
        request.havingPredicate = havingPredicate?.predicate(for: .self)
        request.sortDescriptors = sortDescriptors
        request.propertiesToFetch = propertiesToFetch?.map{$0.propertyDescription(for: .self, context: context)}
        request.propertiesToGroupBy = propertiesToGroupBy?.map{$0.propertyDescription(for: .self, context: context)}
        if let range = range {
            request.fetchOffset = range.lowerBound
            request.fetchLimit = range.upperBound - range.lowerBound
        }
        return request
    }
    
    public func fetchedResultsController(sectionName: PropertyDescriptionConvertibleBase? = nil, cacheName: String? = nil) -> NSFetchedResultsController<FetchRequestResult> {
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: sectionName?.name, cacheName: cacheName)
    }
    
    public func filter(_ predicate: PredicateProtocol ) -> Request {
        var request = self
        request.predicate = self.predicate.map{$0 && predicate} ?? predicate
        return request
    }
    
    public func sort<Root, Value>(by keyPath: KeyPath<Root, Value>, ascending: Bool) -> Request {
        var request = self
        request.sortDescriptors = (request.sortDescriptors ?? []) + [NSSortDescriptor(keyPath: keyPath, ascending: ascending)]
        return request
    }
    
    public func select(_ what: [PropertyDescriptionConvertibleBase]) -> Request<Entity, NSDictionary, NSDictionary> {
        var request = Request<Entity, NSDictionary, NSDictionary>(self)
        request.propertiesToFetch = (request.propertiesToFetch ?? []) + what
        request.resultType = .dictionaryResultType
        return request
    }

    public func select<A: PropertyDescriptionConvertible>(_ what: (A)) -> Request<Entity, (A.Value?), NSDictionary> {
        let name = what.name
        var request = Request<Entity, (A.Value?), NSDictionary>(self) { $0[name] as? A.Value }
        request.propertiesToFetch = (propertiesToFetch ?? []) + [what]
        request.resultType = .dictionaryResultType
        return request
    }

    public func select<
        A: PropertyDescriptionConvertible,
        B: PropertyDescriptionConvertible>
        (_ what: (A, B)) -> Request<Entity, (A.Value?, B.Value?), NSDictionary> {
            
        let a = what.0.name
        let b = what.1.name
        var request = Request<Entity, (A.Value?, B.Value?), NSDictionary>(self) { ($0[a] as? A.Value,
                                                                                       $0[b] as? B.Value) }
        
        request.propertiesToFetch = [what.0, what.1] + (propertiesToFetch ?? [])
        request.resultType = .dictionaryResultType
        return request
    }

    public func select<
        A: PropertyDescriptionConvertible,
        B: PropertyDescriptionConvertible,
        C: PropertyDescriptionConvertible>
        (_ what: (A, B, C)) -> Request<Entity, (A.Value?, B.Value?, C.Value?), NSDictionary> {
        
        let a = what.0.name
        let b = what.1.name
        let c = what.2.name
        var request = Request<Entity, (A.Value?, B.Value?, C.Value?), NSDictionary>(self) { ($0[a] as? A.Value,
                                                                                                   $0[b] as? B.Value,
                                                                                                   $0[c] as? C.Value) }
        
        request.propertiesToFetch = [what.0, what.1, what.2] + (propertiesToFetch ?? [])
        request.resultType = .dictionaryResultType
        return request
    }

    public func select<
        A: PropertyDescriptionConvertible,
        B: PropertyDescriptionConvertible,
        C: PropertyDescriptionConvertible,
        D: PropertyDescriptionConvertible>
        (_ what: (A, B, C, D)) -> Request<Entity, (A.Value?, B.Value?, C.Value?, D.Value?), NSDictionary> {
        
        let a = what.0.name
        let b = what.1.name
        let c = what.2.name
        let d = what.3.name
        var request = Request<Entity, (A.Value?, B.Value?, C.Value?, D.Value?), NSDictionary>(self) { ($0[a] as? A.Value,
                                                                                                               $0[b] as? B.Value,
                                                                                                               $0[c] as? C.Value,
                                                                                                               $0[d] as? D.Value) }
        request.propertiesToFetch = [what.0, what.1, what.2, what.3] + (propertiesToFetch ?? [])
        request.resultType = .dictionaryResultType
        return request
    }

    public func select<
        A: PropertyDescriptionConvertible,
        B: PropertyDescriptionConvertible,
        C: PropertyDescriptionConvertible,
        D: PropertyDescriptionConvertible,
        E: PropertyDescriptionConvertible>
        (_ what: (A, B, C, D, E)) -> Request<Entity, (A.Value?, B.Value?, C.Value?, D.Value?, E.Value?), NSDictionary> {
        
        let a = what.0.name
        let b = what.1.name
        let c = what.2.name
        let d = what.3.name
        let e = what.4.name
        var request = Request<Entity, (A.Value?, B.Value?, C.Value?, D.Value?, E.Value?), NSDictionary>(self) { ($0[a] as? A.Value,
                                                                                                                           $0[b] as? B.Value,
                                                                                                                           $0[c] as? C.Value,
                                                                                                                           $0[d] as? D.Value,
                                                                                                                           $0[e] as? E.Value) }
        request.propertiesToFetch = [what.0, what.1, what.2, what.3, what.4] + (propertiesToFetch ?? [])
        request.resultType = .dictionaryResultType
        return request
    }

    public func select<
        A: PropertyDescriptionConvertible,
        B: PropertyDescriptionConvertible,
        C: PropertyDescriptionConvertible,
        D: PropertyDescriptionConvertible,
        E: PropertyDescriptionConvertible,
        F: PropertyDescriptionConvertible>
        (_ what: (A, B, C, D, E, F)) -> Request<Entity, (A.Value?, B.Value?, C.Value?, D.Value?, E.Value?, F.Value?), NSDictionary> {
        
        let a = what.0.name
        let b = what.1.name
        let c = what.2.name
        let d = what.3.name
        let e = what.4.name
        let f = what.5.name
        var request = Request<Entity, (A.Value?, B.Value?, C.Value?, D.Value?, E.Value?, F.Value?), NSDictionary>(self) { ($0[a] as? A.Value,
                                                                                                                                       $0[b] as? B.Value,
                                                                                                                                       $0[c] as? C.Value,
                                                                                                                                       $0[d] as? D.Value,
                                                                                                                                       $0[e] as? E.Value,
                                                                                                                                       $0[f] as? F.Value) }
        request.propertiesToFetch = [what.0, what.1, what.2, what.3, what.4, what.5] + (propertiesToFetch ?? [])
        request.resultType = .dictionaryResultType
        return request
    }
    
    public func group(by expression: [PropertyDescriptionConvertibleBase]) -> Request<Entity, NSDictionary, NSDictionary> {
        var request = Request<Entity, NSDictionary, NSDictionary>(self)
        request.propertiesToGroupBy = (propertiesToGroupBy ?? []) + expression
        request.resultType = .dictionaryResultType
        return request
    }
    
    public func having(_ predicate: PredicateProtocol ) -> Request<Entity, NSDictionary, NSDictionary> {
        var request = Request<Entity, NSDictionary, NSDictionary>(self)
        request.havingPredicate = havingPredicate.map{$0 && predicate} ?? predicate
        request.resultType = .dictionaryResultType
        return request
    }
    
    
    public func count() throws -> Int {
        let fetchRequest = self.fetchRequest
        fetchRequest.resultType = .countResultType
        return try context.fetch(fetchRequest as! NSFetchRequest<NSNumber>).first as? Int ?? 0
    }
    
    
    public var objectIDs: Request<Entity, NSManagedObjectID, NSManagedObjectID> {
        var request = Request<Entity, NSManagedObjectID, NSManagedObjectID>(self)
        request.resultType = .managedObjectIDResultType
        return request
    }
    
    public func fetch() throws -> [Result] {
        return try context.fetch(fetchRequest).map(transform!)
    }
    
    public func first() throws -> Result? {
        let fetchRequest = self.fetchRequest
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first.map{transform!($0)}
    }

    @discardableResult
    public func delete() throws -> [NSManagedObjectID] {
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        request.resultType = .resultTypeObjectIDs
        
        guard let result = try context.execute(request) as? NSBatchDeleteResult,
            let objectIDs = result.result as? [NSManagedObjectID] else {return []}
        
        let changes = [NSDeletedObjectsKey: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable: Any], into: [context])
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSUpdatedObjectsKey: context.updatedObjects.map{$0.objectID}] as [AnyHashable: Any], into: [context])
        return objectIDs
    }

    public func subrange(_ bounds: Range<Int>) -> Request {
        var request = self
        request.range = bounds
        return request
    }
    
    public func subrange(_ bounds: ClosedRange<Int>) -> Request {
        var request = self
        request.range = bounds.lowerBound..<(bounds.upperBound + 1)
        return request
    }

    public func limit(_ limit: Int) -> Request {
        var request = self
        request.range = 0..<limit
        return request
    }

    public func update<T: PropertyDescriptionConvertible>(_ property: T, to value: T.Value) -> UpdateRequest {
        return UpdateRequest(context: context, entity: entity, predicate: predicate, updates: [:]).update(property, to: value)
    }
}

public struct UpdateRequest {
    fileprivate var context: NSManagedObjectContext
    fileprivate var entity: NSEntityDescription
    fileprivate var predicate: PredicateProtocol?
    fileprivate var updates: [AnyHashable: Any]
    
    public func update<T: PropertyDescriptionConvertible>(_ property: T, to value: T.Value) -> UpdateRequest {
        var updates = self.updates
        updates[property.propertyDescription(for: .self, context: context).name] = value
        return UpdateRequest(context: context, entity: entity, predicate: predicate, updates: updates)
    }
    
    @discardableResult
    public func perform() throws -> [NSManagedObjectID] {
        let request = NSBatchUpdateRequest(entity: entity)
        request.predicate = predicate?.predicate(for: .self)
        request.propertiesToUpdate = updates
        request.resultType = .updatedObjectIDsResultType
        guard let result = try context.execute(request) as? NSBatchUpdateResult,
            let objectIDs = result.result as? [NSManagedObjectID] else {return []}
        
        let changes = [NSUpdatedObjectsKey: objectIDs]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes as [AnyHashable: Any], into: [context])
        return objectIDs
    }
}

extension Request where Result == FetchRequestResult {
    public func fetch() throws -> [Result] {
        return try context.fetch(fetchRequest)
    }
    
    public func first() throws -> Result? {
        fetchRequest.fetchLimit = 1
        return try context.fetch(fetchRequest).first
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
