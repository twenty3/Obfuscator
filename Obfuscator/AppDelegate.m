//
//  AppDelegate.m
//  Obfuscator
//
//  Created by 23 on 2/24/14.
//  Copyright (c) 2014 Aperiodical. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSTextField *aField;
@property (weak) IBOutlet NSTextField *bField;
@property (weak) IBOutlet NSTextField *secretField;
@property (unsafe_unretained) IBOutlet NSTextView *resultTextView;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self.resultTextView setFont:[NSFont fontWithName:@"Menlo" size:12.0]];
    [self.resultTextView setContinuousSpellCheckingEnabled:NO];
    [self.resultTextView setGrammarCheckingEnabled:NO];
}

- (IBAction)obfuscateButtonClicked:(id)sender
{
    BOOL validInput = YES;
    NSString* errorString = nil;
    
    if ( self.aField.stringValue == nil || [self.aField.stringValue isEqualToString:@""]  )
    {
        validInput = NO;
        errorString = @"Please provide an unsigned integer value for a";
    }

    if ( validInput && (self.bField.stringValue == nil || [self.bField.stringValue isEqualToString:@""])  )
    {
        validInput = NO;
        errorString = @"Please provide an unsigned integer value for b";
    }
    
    if ( validInput && (self.secretField.stringValue == nil || [self.secretField.stringValue isEqualToString:@""]) )
    {
        validInput = NO;
        errorString = @"Please provide a secret in the form of a string to obfuscate.";
    }

    if ( !validInput )
    {
        [self.resultTextView setString:errorString];
        return;
    }
    else
    {
        NSString* secretString = self.secretField.stringValue;
        NSUInteger a = self.aField.integerValue;
        NSUInteger b = self.bField.integerValue;
        
        NSString* result = [self obfuscatedStringFromString:secretString withA:a andB:b];
        NSString* codeString = [[self codeTemplateString] stringByReplacingOccurrencesOfString:@"%DATA%" withString:result];
        codeString = [codeString stringByReplacingOccurrencesOfString:@"%SECRET%" withString:secretString];
        codeString = [codeString stringByReplacingOccurrencesOfString:@"%LENGTH%" withString:[@(secretString.length) stringValue]];
        codeString = [codeString stringByReplacingOccurrencesOfString:@"%A%" withString:[NSString stringWithFormat:@"0x%lx",(unsigned long)a]];
        codeString = [codeString stringByReplacingOccurrencesOfString:@"%B%" withString:[NSString stringWithFormat:@"0x%lx",(unsigned long)b]];
        
        [self.resultTextView setString:codeString];
    }
    
}

- (IBAction)randomizeAClicked:(id)sender
{
    NSUInteger a = arc4random_uniform(0x000000FFF);
    self.aField.integerValue = a;
}

- (IBAction)randomizeBClicked:(id)sender
{
    NSUInteger b = arc4random_uniform(0x000000FFF);
    self.bField.integerValue = b;
}


- (NSString*) obfuscatedStringFromString:(NSString*)secret withA:(NSUInteger)a andB:(NSUInteger)b
{
    NSUInteger length = secret.length;
    
    NSMutableArray* indexes = [[NSMutableArray alloc] initWithCapacity:length];
    for (int i = 0; i < length; i++)
    {
        indexes[i] = @(i);
    }
    
    for (NSUInteger currentIndex = 0; currentIndex < length; currentIndex++)
    {
        u_int32_t elementCount = (u_int32_t)(length - currentIndex);
        NSInteger swapIndex = arc4random_uniform(elementCount) + currentIndex;
        [indexes exchangeObjectAtIndex:currentIndex withObjectAtIndex:swapIndex];
    }
    
    NSMutableArray* output = [NSMutableArray new];
    NSUInteger last = 0;
    
    for (NSUInteger i = 0; i < length; i++)
    {
        // index
        NSUInteger index = [indexes[i] unsignedIntegerValue];
        NSUInteger encodedIndex = index + a;
        encodedIndex = encodedIndex + (0xFFFFF000 & arc4random_uniform(UINT32_MAX));
        
        // value
        NSUInteger value = [secret characterAtIndex:index];
        NSUInteger encodedValue = value + b;
        encodedValue -= last;
        encodedValue = encodedValue + (0xFFFFF000 & arc4random_uniform(UINT32_MAX));
        last = value;
        
        [output addObject:@(encodedIndex)];
        [output addObject:@(encodedValue)];
    }
    
    NSMutableString* obfuscatedString = [NSMutableString new];
    NSInteger count = 0;
    
    [obfuscatedString appendString:@"\t\t"];
    for (NSNumber* number in output)
    {
        [obfuscatedString appendFormat:@"0x%lx,",(unsigned long)[number unsignedIntegerValue]];
        count++;
        if ( (count % 8) == 0) [obfuscatedString appendString:@"\n\t\t"];

    }
    
    return obfuscatedString;
}

- (NSString*) codeTemplateString
{
    return @"//Returns secret key %SECRET%\n//decode with a:%A% b:%B%\nNSString *_replace_me(unsigned int a, unsigned int b)\n{\n\tint length = %LENGTH%;\n\tunsigned int k[] = {\n%DATA%\n\t};\n\tchar out[length + 1];\n\tunsigned int i, s, v, last = 0;\n\tmemset(out, 0, length + 1);\n\tfor (i = 0; i < length * 2; i += 2) {\n\t\ts = (k[i] & 0x00000FFF) - a;\n\t\tv = ((k[i + 1] & 0x00000FFF) + last) - b;\n\t\tlast = out[s] = v;\n\t}\n\treturn [NSString stringWithUTF8String:out];\n}";
}

@end
