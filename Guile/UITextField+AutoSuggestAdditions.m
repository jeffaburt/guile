//
//  UITextField+AutoSuggestAdditions.m
//  Guile
//
//  Created by Adam Kaplan on 1/14/14.
//  Copyright (c) 2014 Gilt Groupe. All rights reserved.
//

#import <Guile/UITextField+AutoSuggestAdditions.h>

static UIColor *DefaultSuggestedTextColor;

static NSString *SuggestedTextMarkerAttributeName = @"SuggestedTextMarkerAttribute";

static NSString *SuggestedTextMarkerAttributeValue = @"SuggestedTextMarker";

#define RANGE_NOT_FOUND NSMakeRange(NSNotFound, 0)

@implementation UITextField (AutoSuggestAdditions)

- (id<AutoSuggestTextFieldDelegate>) suggestionDelegate {
    return nil;
}

- (void)updateSuggestion {
    [self updateSuggestion:[self suggestionDelegate]];
}

- (void)updateSuggestion:(id<AutoSuggestTextFieldDelegate>)aSuggestionDelegate {
    // Set the default color, only once
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ DefaultSuggestedTextColor = [UIColor grayColor]; });

    // Locate any existing suggested text and delete it
    __block NSString *userInput = self.text;
    [self.attributedText enumerateAttribute:SuggestedTextMarkerAttributeName
                                    inRange:NSMakeRange(0, self.text.length)
                                    options:0
                                 usingBlock:^(NSString *marker, NSRange range, BOOL *stop) {

                                     if (marker && marker == SuggestedTextMarkerAttributeValue) {
                                         userInput = [userInput stringByReplacingCharactersInRange:range
                                                                                        withString:@""];
                                     }
                                 }];

    // Get the suggested text for the clean input
    NSString *suggestedText = [aSuggestionDelegate suggestedStringForInputString:userInput];

    if (suggestedText) {
        NSString *combined = [userInput stringByAppendingString:suggestedText];

        NSMutableAttributedString *attributed = [[NSMutableAttributedString alloc] initWithString:combined];

        NSRange attributeRange = NSMakeRange(userInput.length, suggestedText.length);

        // Color the suggested text
        if ([aSuggestionDelegate respondsToSelector:@selector(suggestedTextAttributes)]) {
            [attributed addAttributes:[aSuggestionDelegate suggestedTextAttributes]
                                range:attributeRange];
        }
        else if ([aSuggestionDelegate respondsToSelector:@selector(suggestedTextColor)]) {
            [attributed addAttribute:NSForegroundColorAttributeName
                               value:[aSuggestionDelegate suggestedTextColor]
                               range:attributeRange];
        }

        // Add a special proprietary marker to recognize this text later.
        // Note: The color is not a safe value becasue it can change or be changed.
        [attributed addAttribute:SuggestedTextMarkerAttributeName
                           value:SuggestedTextMarkerAttributeValue
                           range:attributeRange];

        [self setAttributedText:attributed];

        // Move the caret back to the original location
        UITextPosition *caretPosition = [self positionFromPosition:self.beginningOfDocument
                                                            offset:userInput.length];

        self.selectedTextRange = [self textRangeFromPosition:caretPosition
                                                  toPosition:caretPosition];
    } else {
        self.text = userInput; // ensure no highlighted text remains
    }
}

@end
