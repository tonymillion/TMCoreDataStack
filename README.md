# TMCoreDataStack

[![CI Status](http://img.shields.io/travis/Tony Million/TMCoreDataStack.svg?style=flat)](https://travis-ci.org/Tony Million/TMCoreDataStack)
[![Version](https://img.shields.io/cocoapods/v/TMCoreDataStack.svg?style=flat)](http://cocoadocs.org/docsets/TMCoreDataStack)
[![License](https://img.shields.io/cocoapods/l/TMCoreDataStack.svg?style=flat)](http://cocoadocs.org/docsets/TMCoreDataStack)
[![Platform](https://img.shields.io/cocoapods/p/TMCoreDataStack.svg?style=flat)](http://cocoadocs.org/docsets/TMCoreDataStack)

## Usage

TMCoreDataStack is a simple class to setup a 2-context CoreData stack. What is that? Well we setup a background-thread Context that handles disk IO and a main-thread context which is a child of the background context that handles the bulk of your work.

When you make updates in the main-thread context and save, these saves are pushed in-memory to the background save context which handles getting them on to disk. By doing things this way your UI can remain responsive and stutter free!

In addition TMCoreDataStack provides a set of categories for `NSManagedObjectContext` and `NSManagedObject` which vastly simplifies using CoreData.

The whole rationale behind TMCoreDataStack is that 99% of the hard work can be done with a small set of functions and bigger libraries (like MagicalRecord) are often overkill (MagicalRecord is vast and awesome and depending on what you need from CoreData might be a better choice!).

TMCoreDataStack has been designed for iOS7 upwards taking advantage of all the recent updates CoreData has received, specifically block-based concurrency.

*So, how does it work?*

*Categories*

*Summary*

## Requirements

Link with CoreData framework and you're done!

## Installation

TMCoreDataStack is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "TMCoreDataStack"

## Author

Tony Million, tonymillion@gmail.com

## License

TMCoreDataStack is available under the MIT license. See the LICENSE file for more info.

