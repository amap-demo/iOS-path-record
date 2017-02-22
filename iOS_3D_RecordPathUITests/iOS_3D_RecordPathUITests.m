//
//  iOS_3D_RecordPathUITests.m
//  iOS_3D_RecordPathUITests
//
//  Created by hanxiaoming on 17/1/16.
//  Copyright © 2017年 FENGSHENG. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface iOS_3D_RecordPathUITests : XCTestCase

@end

@implementation iOS_3D_RecordPathUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = NO;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // Use recording to get started writing UI tests.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    
    XCUIApplication *app = [[XCUIApplication alloc] init];
    
    sleep(1);
    [[[app.navigationBars[@"My Route"] childrenMatchingType:XCUIElementTypeButton] elementBoundByIndex:1] tap];
    [[app.tables.cells elementBoundByIndex:0] tap];
    
    XCUIElement *displayNavigationBar = app.navigationBars[@"Display"];
    [displayNavigationBar.buttons[@"icon play"] tap];
    
    XCUIElement *element = [[[[[[[app.otherElements containingType:XCUIElementTypeNavigationBar identifier:@"Display"] childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther].element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:1];
    [[[element childrenMatchingType:XCUIElementTypeOther] elementBoundByIndex:2] tap];
    
    [element twoFingerTap];
    
    sleep(13);
    [displayNavigationBar.buttons[@"Records"] tap];
    [app.navigationBars[@"Records"].buttons[@"My Route"] tap];
    
}

@end
