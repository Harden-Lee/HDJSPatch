//
//  XMLReader.m
//
//  Created by Troy Brant on 9/18/10.
//  Updated by Antoine Marcadet on 9/23/11.
//  Updated by Divan Visagie on 2012-08-26
//

#import "XMLReader.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "XMLReader requires ARC support."
#endif

NSString *const kXMLReaderTextNodeKey		= @"text";
NSString *const kXMLReaderAttributePrefix	= @"@";

@interface XMLReader ()

@property (nonatomic, strong) NSMutableArray *dictionaryStack;
@property (nonatomic, strong) NSMutableString *textInProgress;
@property (nonatomic, strong) NSError *errorPointer;

@end


@implementation XMLReader

#pragma mark - Public methods

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data error:(NSError **)error
{
    XMLReader *reader = [[XMLReader alloc] initWithError:error];
    NSDictionary *rootDictionary = [reader objectWithData:data options:0];
    return rootDictionary;
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string error:(NSError **)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data error:error];
}

+ (NSDictionary *)dictionaryForXMLData:(NSData *)data options:(XMLReaderOptions)options error:(NSError **)error
{
    XMLReader *reader = [[XMLReader alloc] initWithError:error];
    NSDictionary *rootDictionary = [reader objectWithData:data options:options];
    return rootDictionary;
}

+ (NSDictionary *)dictionaryForXMLString:(NSString *)string options:(XMLReaderOptions)options error:(NSError **)error
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [XMLReader dictionaryForXMLData:data options:options error:error];
}


#pragma mark - Parsing

- (id)initWithError:(NSError **)error
{
	self = [super init];
    if (self)
    {
        self.errorPointer = *error;
    }
    return self;
}

- (NSDictionary *)objectWithData:(NSData *)data options:(XMLReaderOptions)options
{
    // Clear out any old data
    self.dictionaryStack = [[NSMutableArray alloc] init];
    self.textInProgress = [[NSMutableString alloc] init];
    
    // Initialize the stack with a fresh dictionary
    [self.dictionaryStack addObject:[NSMutableDictionary dictionary]];
    
    // Parse the XML
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    
    [parser setShouldProcessNamespaces:(options & XMLReaderOptionsProcessNamespaces)];
    [parser setShouldReportNamespacePrefixes:(options & XMLReaderOptionsReportNamespacePrefixes)];
    [parser setShouldResolveExternalEntities:(options & XMLReaderOptionsResolveExternalEntities)];
    
    parser.delegate = self;
    BOOL success = [parser parse];
	
    // Return the stack's root dictionary on success
    if (success)
    {
        NSDictionary *resultDict = [self.dictionaryStack objectAtIndex:0];
        return resultDict;
    }
    else
    {
        NSDictionary *resultDict = [self.dictionaryStack objectAtIndex:0];
        if(resultDict)
        {
            //have some node is wrong or have Special character
            NSLog(@"%@解析XML部分有误",NSStringFromClass([self class]));
            return resultDict;
        }
        else
        {
            //parser wrong
            NSLog(@"%@解析XML失败",NSStringFromClass([self class]));
            return nil;
        }
    }
    
    return nil;
}


#pragma mark -  NSXMLParserDelegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{   
    // Get the dictionary for the current level in the stack
    NSMutableDictionary *parentDict = [self.dictionaryStack lastObject];

    // Create the child dictionary for the new element, and initilaize it with the attributes
    NSMutableDictionary *childDict = [NSMutableDictionary dictionary];
    [childDict addEntriesFromDictionary:attributeDict];
    
    // If there's already an item for this key, it means we need to create an array
    id existingValue = [parentDict objectForKey:elementName];
    if (existingValue)
    {
        NSMutableArray *array = nil;
        if ([existingValue isKindOfClass:[NSMutableArray class]])
        {
            // The array exists, so use it
            array = (NSMutableArray *) existingValue;
        }
        else
        {
            // Create an array if it doesn't exist
            array = [NSMutableArray array];
            [array addObject:existingValue];

            // Replace the child dictionary with an array of children dictionaries
            [parentDict setObject:array forKey:elementName];
        }
        
        // Add the new child dictionary to the array
        [array addObject:childDict];
    }
    else
    {
        // No existing value, so update the dictionary
        [parentDict setObject:childDict forKey:elementName];
    }
    
    // Update the stack
    [self.dictionaryStack addObject:childDict];
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    // Update the parent dict with text info
    NSMutableDictionary *dictInProgress = [self.dictionaryStack lastObject];
    
    // Set the text property
    if ([self.textInProgress length] > 0)
    {
        // trim after concatenating
        NSString *trimmedString = [self.textInProgress stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [dictInProgress setObject:[trimmedString mutableCopy] forKey:kXMLReaderTextNodeKey];

        // Reset the text
        self.textInProgress = [[NSMutableString alloc] init];
    }
    
    // Pop the current dict
    [self.dictionaryStack removeLastObject];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    // Build the text value
    [self.textInProgress appendString:string];
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    // Set the error pointer to the parser's error object
    self.errorPointer = parseError;
}

@end



//(
//{
//    RoomConfig = {
//    platform   = (
//                            {
//    id         = 0;
//    name       = LED;
//    room       = (
//                                                        {
//    flag       = 0;
//    id         = C001;
//    name       = C01;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac01/4-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac01/4-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac01/4-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb3.11hk.com/bac01/4-1";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C001;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = C002;
//    name       = C02;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac02/4-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac02/4-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac02/4-2";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C002;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = C003;
//    name       = C03;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac03/4-3";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac03/4-3";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac03/4-3";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C003;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = C005;
//    name       = C05;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac05/4-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac05/4-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac05/4-5";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C005;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = C006;
//    name       = C06;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac04/4-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac04/4-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac04/4-4";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C006;
//    maddr      = (
//                                                                                                     {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                                                     },
//                                                                                                     {
//    text       = "rtsp:/mb.1d1hk.com/mobile/2-1";
//                                                                                                     },
//                                                                                                     {
//    text       = "rtsp:/mb.1dd1hk.com/mobile/2-1";
//                                                                                                     },
//                                                                                                     {
//    text       = "rtsp:/mb.1df1hk.com/mobile/2-1";
//                                                                                                     },
//                                                                                                     {
//    text       = "rtsp:/mb.d1d1hk.com/mobile/2-1";
//                                                                                                     }
//                                                                                                     );
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = C007;
//    name       = C07;
//    type       = DT;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac07/4-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac07/4-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb3.11hk.com/bac07/4-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac07/4-7";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C007;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = C008;
//    name       = C08;
//    type       = ROU;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac08/4-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac08/4-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb3.11hk.com/bac08/4-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.102/bac08/4-8";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3001;
//    id         = C008;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = V012;
//    name       = L12;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led02/3-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/led02/3-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.101/led02/3-2";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3002;
//    id         = V012;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = O;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = V015;
//    name       = L15;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led05/3-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/led05/3-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.101/led05/3-5";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3002;
//    id         = V015;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = P;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = V016;
//    name       = L16;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led06/3-6";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/led06/3-6";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.101/led06/3-6";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3002;
//    id         = V016;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = P;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = V017;
//    name       = L17;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led07/3-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/led07/3-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.101/led07/3-7";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3002;
//    id         = V017;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = Q;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = V018;
//    name       = L18;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led08/3-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/led08/3-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.101/led08/3-8";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3002;
//    id         = V018;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = Q;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = V019;
//    name       = L19;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led09/3-9";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://pb.11hk.com/led09/3-9";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.7.101/led09/3-9";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3002;
//    id         = V019;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = Q;
//    quickmode  = 0;
//                                                            };
//                                                        }
//                                                        );
//                            },
//                            {
//    id         = 2;
//    name       = AGQJ;
//    room       = (
//                                                        {
//    flag       = 0;
//    id         = A001;
//    name       = V01;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj1/2-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj1/2-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj1/2-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/agqj1/2-1";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A001;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A002;
//    name       = V02;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj2/2-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj2/2-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj2/2-2";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A002;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A003;
//    name       = V03;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj4/2-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj4/2-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj4/2-4";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A003;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A004;
//    name       = V04;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj5/2-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj5/2-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj5/2-5";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A004;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A005;
//    name       = V05;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A005;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A006;
//    name       = V06;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj9/2-9";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj9/2-9";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj9/2-9";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A006;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A007;
//    name       = V07;
//    type       = DT;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj3/2-3";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj3/2-3";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj3/2-3";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A007;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A008;
//    name       = V08;
//    type       = SHB;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj6/2-6";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj6/2-6";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj6/2-6";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A008;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A009;
//    name       = V09;
//    type       = ROU;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj15/2-15";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj15/2-15";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj15/2-15";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A009;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A010;
//    name       = V10;
//    type       = SBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip1/1-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/pbvip1/1-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/pbvip1/1-1";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A010;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A011;
//    name       = V11;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A011;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A012;
//    name       = V12;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A012;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A013;
//    name       = V13;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/pbvip3/1-3";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A013;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A014;
//    name       = V14;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj4/2-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj4/2-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj4/2-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.3.66/agqj4/2-4";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A014;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A015;
//    name       = V15;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://192.168.3.66/train/1";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A015;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A016;
//    name       = V16;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A016;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = A017;
//    name       = V17;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj1/2-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj1/2-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj1/2-1";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/agqj1/2-1";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3003;
//    id         = A017;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T018;
//    name       = T18;
//    type       = TBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip2/1-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip2/1-2";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip2/1-2";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T018;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = K;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T023;
//    name       = T23;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip4/1-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip4/1-4";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip4/1-4";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T023;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = L;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T024;
//    name       = T24;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip3/1-3";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip3/1-3";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip3/1-3";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T024;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = L;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T025;
//    name       = T25;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip6/1-6";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip6/1-6";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip6/1-6";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T025;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = L;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T026;
//    name       = T26;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip5/1-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip5/1-5";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip5/1-5";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T026;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = L;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T027;
//    name       = T27;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip7/1-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip7/1-7";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip7/1-7";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T027;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = M;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T028;
//    name       = T28;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip8/1-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip8/1-8";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip8/1-8";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T028;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = M;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T029;
//    name       = T29;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip10/1-10";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip10/1-10";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip10/1-10";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T029;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                };
//    oddlist    = N;
//    quickmode  = 0;
//                                                            };
//                                                        },
//                                                        {
//    flag       = 0;
//    id         = T030;
//    name       = T30;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip9/1-9";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip9/1-9";
//                                                                                                    },
//                                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip9/1-9";
//                                                                                                    }
//                                                                                                    );
//    gms        = 3004;
//    id         = T030;
//    maddr      = {
//                                                                };
//    oddlist    = N;
//    quickmode  = 0;
//                                                            };
//                                                        }
//                                                        );
//                            }
//                            );
//    };
//},
//{
//    platform   = (
//                    {
//    id         = 0;
//    name       = LED;
//    room       = (
//                                            {
//    flag       = 0;
//    id         = C001;
//    name       = C01;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac01/4-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac01/4-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac01/4-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb3.11hk.com/bac01/4-1";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C001;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = C002;
//    name       = C02;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac02/4-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac02/4-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac02/4-2";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C002;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = C003;
//    name       = C03;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac03/4-3";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac03/4-3";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac03/4-3";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C003;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = C005;
//    name       = C05;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac05/4-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac05/4-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac05/4-5";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C005;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = C006;
//    name       = C06;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac04/4-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac04/4-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac04/4-4";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C006;
//    maddr      = (
//                                                                                     {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                                                     },
//                                                                                     {
//    text       = "rtsp:/mb.1d1hk.com/mobile/2-1";
//                                                                                     },
//                                                                                     {
//    text       = "rtsp:/mb.1dd1hk.com/mobile/2-1";
//                                                                                     },
//                                                                                     {
//    text       = "rtsp:/mb.1df1hk.com/mobile/2-1";
//                                                                                     },
//                                                                                     {
//    text       = "rtsp:/mb.d1d1hk.com/mobile/2-1";
//                                                                                     }
//                                                                                     );
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = C007;
//    name       = C07;
//    type       = DT;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac07/4-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac07/4-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb3.11hk.com/bac07/4-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac07/4-7";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C007;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = C008;
//    name       = C08;
//    type       = ROU;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/bac08/4-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/bac08/4-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb3.11hk.com/bac08/4-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.102/bac08/4-8";
//                                                                                    }
//                                                                                    );
//    gms        = 3001;
//    id         = C008;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = V012;
//    name       = L12;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led02/3-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/led02/3-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.101/led02/3-2";
//                                                                                    }
//                                                                                    );
//    gms        = 3002;
//    id         = V012;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = O;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = V015;
//    name       = L15;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led05/3-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/led05/3-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.101/led05/3-5";
//                                                                                    }
//                                                                                    );
//    gms        = 3002;
//    id         = V015;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = P;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = V016;
//    name       = L16;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led06/3-6";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/led06/3-6";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.101/led06/3-6";
//                                                                                    }
//                                                                                    );
//    gms        = 3002;
//    id         = V016;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = P;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = V017;
//    name       = L17;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led07/3-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/led07/3-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.101/led07/3-7";
//                                                                                    }
//                                                                                    );
//    gms        = 3002;
//    id         = V017;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = Q;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = V018;
//    name       = L18;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led08/3-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/led08/3-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.101/led08/3-8";
//                                                                                    }
//                                                                                    );
//    gms        = 3002;
//    id         = V018;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = Q;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = V019;
//    name       = L19;
//    type       = LBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://dt.yzbabyu.com/led09/3-9";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://pb.11hk.com/led09/3-9";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.7.101/led09/3-9";
//                                                                                    }
//                                                                                    );
//    gms        = 3002;
//    id         = V019;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = Q;
//    quickmode  = 0;
//                                                };
//                                            }
//                                            );
//                    },
//                    {
//    id         = 2;
//    name       = AGQJ;
//    room       = (
//                                            {
//    flag       = 0;
//    id         = A001;
//    name       = V01;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj1/2-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj1/2-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj1/2-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/agqj1/2-1";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A001;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A002;
//    name       = V02;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj2/2-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj2/2-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj2/2-2";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A002;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A003;
//    name       = V03;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj4/2-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj4/2-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj4/2-4";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A003;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A004;
//    name       = V04;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj5/2-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj5/2-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj5/2-5";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A004;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A005;
//    name       = V05;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A005;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A006;
//    name       = V06;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj9/2-9";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj9/2-9";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj9/2-9";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A006;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A007;
//    name       = V07;
//    type       = DT;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj3/2-3";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj3/2-3";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj3/2-3";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A007;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A008;
//    name       = V08;
//    type       = SHB;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj6/2-6";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj6/2-6";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj6/2-6";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A008;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A009;
//    name       = V09;
//    type       = ROU;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj15/2-15";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj15/2-15";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj15/2-15";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A009;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A010;
//    name       = V10;
//    type       = SBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip1/1-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/pbvip1/1-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/pbvip1/1-1";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A010;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A011;
//    name       = V11;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A011;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A012;
//    name       = V12;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A012;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A013;
//    name       = V13;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/pbvip3/1-3";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A013;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A014;
//    name       = V14;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj4/2-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj4/2-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj4/2-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.3.66/agqj4/2-4";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A014;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A015;
//    name       = V15;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://192.168.3.66/train/1";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A015;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A016;
//    name       = V16;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A016;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = A017;
//    name       = V17;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/agqj1/2-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://agqj.yzbabyu.com/agqj1/2-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca3.11hk.com/agqj1/2-1";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/agqj1/2-1";
//                                                                                    }
//                                                                                    );
//    gms        = 3003;
//    id         = A017;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T018;
//    name       = T18;
//    type       = TBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip2/1-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip2/1-2";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip2/1-2";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T018;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = K;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T023;
//    name       = T23;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip4/1-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip4/1-4";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip4/1-4";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T023;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = L;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T024;
//    name       = T24;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip3/1-3";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip3/1-3";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip3/1-3";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T024;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = L;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T025;
//    name       = T25;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip6/1-6";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip6/1-6";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip6/1-6";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T025;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = L;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T026;
//    name       = T26;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip5/1-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip5/1-5";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip5/1-5";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T026;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = L;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T027;
//    name       = T27;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip7/1-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip7/1-7";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip7/1-7";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T027;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = M;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T028;
//    name       = T28;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip8/1-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip8/1-8";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip8/1-8";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T028;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = M;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T029;
//    name       = T29;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip10/1-10";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip10/1-10";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip10/1-10";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T029;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                                                    };
//    oddlist    = N;
//    quickmode  = 0;
//                                                };
//                                            },
//                                            {
//    flag       = 0;
//    id         = T030;
//    name       = T30;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                                                    {
//    text       = "rtmp://agqj.lyeol.com/pbvip9/1-9";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://ca.11hk.com/pbvip9/1-9";
//                                                                                    },
//                                                                                    {
//    text       = "rtmp://211.147.238.34/pbvip9/1-9";
//                                                                                    }
//                                                                                    );
//    gms        = 3004;
//    id         = T030;
//    maddr      = {
//                                                    };
//    oddlist    = N;
//    quickmode  = 0;
//                                                };
//                                            }
//                                            );
//                    }
//                    );
//},
//{
//    id         = 2;
//    name       = AGQJ;
//    room       = (
//                {
//    flag       = 0;
//    id         = A001;
//    name       = V01;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj1/2-1";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj1/2-1";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj1/2-1";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/agqj1/2-1";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A001;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A002;
//    name       = V02;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj2/2-2";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj2/2-2";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj2/2-2";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A002;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A003;
//    name       = V03;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj4/2-4";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj4/2-4";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj4/2-4";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A003;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A004;
//    name       = V04;
//    type       = BAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj5/2-5";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj5/2-5";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj5/2-5";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A004;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A005;
//    name       = V05;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A005;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A006;
//    name       = V06;
//    type       = BBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj9/2-9";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj9/2-9";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj9/2-9";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A006;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A007;
//    name       = V07;
//    type       = DT;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj3/2-3";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj3/2-3";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj3/2-3";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A007;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A008;
//    name       = V08;
//    type       = SHB;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj6/2-6";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj6/2-6";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj6/2-6";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A008;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A009;
//    name       = V09;
//    type       = ROU;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj15/2-15";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj15/2-15";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj15/2-15";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A009;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = "A,B";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A010;
//    name       = V10;
//    type       = SBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip1/1-1";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/pbvip1/1-1";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/pbvip1/1-1";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A010;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A011;
//    name       = V11;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A011;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A012;
//    name       = V12;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A012;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A013;
//    name       = V13;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/pbvip3/1-3";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A013;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A014;
//    name       = V14;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj4/2-4";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj4/2-4";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj4/2-4";
//                                                },
//                                                {
//    text       = "rtmp://192.168.3.66/agqj4/2-4";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A014;
//    oddlist    = "A,C,D,E";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A015;
//    name       = V15;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/agqj8/1";
//                                                },
//                                                {
//    text       = "rtmp://192.168.3.66/train/1";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A015;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A016;
//    name       = V16;
//    type       = TEB;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj7/2-7";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj7/2-7";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj7/2-7";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A016;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = A017;
//    name       = V17;
//    type       = NN;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/agqj1/2-1";
//                                                },
//                                                {
//    text       = "rtmp://agqj.yzbabyu.com/agqj1/2-1";
//                                                },
//                                                {
//    text       = "rtmp://ca3.11hk.com/agqj1/2-1";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/agqj1/2-1";
//                                                }
//                                                );
//    gms        = 3003;
//    id         = A017;
//    oddlist    = "A,B";
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T018;
//    name       = T18;
//    type       = TBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip2/1-2";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip2/1-2";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip2/1-2";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T018;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = K;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T023;
//    name       = T23;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip4/1-4";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip4/1-4";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip4/1-4";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T023;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = L;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T024;
//    name       = T24;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip3/1-3";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip3/1-3";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip3/1-3";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T024;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = L;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T025;
//    name       = T25;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip6/1-6";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip6/1-6";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip6/1-6";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T025;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = L;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T026;
//    name       = T26;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip5/1-5";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip5/1-5";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip5/1-5";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T026;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = L;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T027;
//    name       = T27;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip7/1-7";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip7/1-7";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip7/1-7";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T027;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = M;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T028;
//    name       = T28;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip8/1-8";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip8/1-8";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip8/1-8";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T028;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = M;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T029;
//    name       = T29;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip10/1-10";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip10/1-10";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip10/1-10";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T029;
//    maddr      = {
//    text       = "rtsp:/mb.11hk.com/mobile/2-1";
//                        };
//    oddlist    = N;
//    quickmode  = 0;
//                    };
//                },
//                {
//    flag       = 0;
//    id         = T030;
//    name       = T30;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                                                {
//    text       = "rtmp://agqj.lyeol.com/pbvip9/1-9";
//                                                },
//                                                {
//    text       = "rtmp://ca.11hk.com/pbvip9/1-9";
//                                                },
//                                                {
//    text       = "rtmp://211.147.238.34/pbvip9/1-9";
//                                                }
//                                                );
//    gms        = 3004;
//    id         = T030;
//    maddr      = {
//                        };
//    oddlist    = N;
//    quickmode  = 0;
//                    };
//                }
//                );
//},
//{
//    flag       = 0;
//    id         = T030;
//    name       = T30;
//    type       = CBAC;
//    video      = {
//    addr       = (
//                        {
//    text       = "rtmp://agqj.lyeol.com/pbvip9/1-9";
//                        },
//                        {
//    text       = "rtmp://ca.11hk.com/pbvip9/1-9";
//                        },
//                        {
//    text       = "rtmp://211.147.238.34/pbvip9/1-9";
//                        }
//                        );
//    gms        = 3004;
//    id         = T030;
//    maddr      = {
//        };
//    oddlist    = N;
//    quickmode  = 0;
//    };
//},
//{
//    addr       = (
//                {
//    text       = "rtmp://agqj.lyeol.com/pbvip9/1-9";
//                },
//                {
//    text       = "rtmp://ca.11hk.com/pbvip9/1-9";
//                },
//                {
//    text       = "rtmp://211.147.238.34/pbvip9/1-9";
//                }
//                );
//    gms        = 3004;
//    id         = T030;
//    maddr      = {
//    };
//    oddlist    = N;
//    quickmode  = 0;
//},
//{
//}
//                            )
