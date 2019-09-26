//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerSnapshotRequestMessage.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "MPApplicationStateSerializer.h"
#import "MPObjectIdentityProvider.h"
#import "MPObjectSerializerConfig.h"
#import "MPLogger.h"
#import "WebViewInfoStorage.h"
#import "zlib.h"
#import "ExceptionUtils.h"

NSString * const MPABTestDesignerSnapshotRequestMessageType = @"snapshot_request";

static NSString * const kSnapshotSerializerConfigKey = @"snapshot_class_descriptions";
static NSString * const kObjectIdentityProviderKey = @"object_identity_provider";

@implementation MPABTestDesignerSnapshotRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerSnapshotRequestMessageType];
}

- (MPObjectSerializerConfig *)configuration
{
    NSDictionary *config = [self payloadObjectForKey:@"config"];
    return config ? [[MPObjectSerializerConfig alloc] initWithDictionary:config] : nil;
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    @try {
        __block MPObjectSerializerConfig *serializerConfig = self.configuration;
        __block NSString *imageHash = [self payloadObjectForKey:@"image_hash"];
        __block NSNumber *shouldCompressed = [self payloadObjectForKey:@"should_compressed"];

        __weak MPABTestDesignerConnection *weak_connection = connection;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            __strong MPABTestDesignerConnection *conn = weak_connection;

            // Update the class descriptions in the connection session if provided as part of the message.
            if (serializerConfig) {
                [connection setSessionObject:serializerConfig forKey:kSnapshotSerializerConfigKey];
            } else if ([connection sessionObjectForKey:kSnapshotSerializerConfigKey]) {
                // Get the class descriptions from the connection session store.
                serializerConfig = [connection sessionObjectForKey:kSnapshotSerializerConfigKey];
            } else {
                // If neither place has a config, this is probably a stale message and we can't create a snapshot.
                return;
            }

            // Get the object identity provider from the connection's session store or create one if there is none already.
            MPObjectIdentityProvider *objectIdentityProvider = [connection sessionObjectForKey:kObjectIdentityProviderKey];
            if (objectIdentityProvider == nil) {
                objectIdentityProvider = [[MPObjectIdentityProvider alloc] init];
                [connection setSessionObject:objectIdentityProvider forKey:kObjectIdentityProviderKey];
            }

            MPApplicationStateSerializer *serializer = [[MPApplicationStateSerializer alloc] initWithApplication:[UIApplication sharedApplication]
                                                                                                   configuration:serializerConfig
                                                                                          objectIdentityProvider:objectIdentityProvider];

            MPABTestDesignerSnapshotResponseMessage *snapshotMessage = [MPABTestDesignerSnapshotResponseMessage message];
            __block UIImage *screenshot = nil;
            __block NSDictionary *serializedObjects = nil;

            dispatch_sync(dispatch_get_main_queue(), ^{
                screenshot = [serializer screenshotImageForKeyWindow];
            });
            snapshotMessage.screenshot = screenshot;

            if ([imageHash isEqualToString:snapshotMessage.imageHash]) {
                if ([WebViewInfoStorage.globalStorage hasNewFrame]) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        serializedObjects = [serializer objectHierarchyForKeyWindow];
                    });
                    [connection setSessionObject:serializedObjects forKey:@"snapshot_hierarchy"];
                    if ([WebViewInfoStorage.globalStorage hasNewFrame]) {
                        [WebViewInfoStorage.globalStorage setHasNewFrame:false];
                    }
                } else {
                    serializedObjects = [connection sessionObjectForKey:@"snapshot_hierarchy"];
                }
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    serializedObjects = [serializer objectHierarchyForKeyWindow];
                });
                [connection setSessionObject:serializedObjects forKey:@"snapshot_hierarchy"];
            }

            if ([shouldCompressed boolValue]) {
                snapshotMessage.compressedSerializedObjects = [[MPABTestDesignerSnapshotRequestMessage gzipDeflate:[NSJSONSerialization dataWithJSONObject:serializedObjects
                                                                                                                                                  options:NSJSONWritingPrettyPrinted
                                                                                                                                                    error:nil]] base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
            } else {
                snapshotMessage.serializedObjects = serializedObjects;
            }
            if (snapshotMessage.serializedObjects.count > 0 || snapshotMessage.compressedSerializedObjects.length > 0) {
                [conn sendMessage:snapshotMessage];
            } else {
                MPLogDebug(@"snapshotMessage.serializedObjects is Empty");
            }
        }];

        return operation;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

+ (NSData *)gzipInflate:(NSData*)data
{
    @try {
        if ([data length] == 0) return data;
        
        unsigned long full_length = [data length];
        unsigned long half_length = [data length] / 2;
        
        NSMutableData *decompressed = [NSMutableData dataWithLength: full_length + half_length];
        BOOL done = NO;
        int status;
        
        z_stream strm;
        strm.next_in = (Bytef *)[data bytes];
        strm.avail_in = [data length];
        strm.total_out = 0;
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        
        if (inflateInit2(&strm, (15+32)) != Z_OK) return nil;
        while (!done)
        {
            // Make sure we have enough room and reset the lengths.
            if (strm.total_out >= [decompressed length])
                [decompressed increaseLengthBy: half_length];
            strm.next_out = [decompressed mutableBytes] + strm.total_out;
            strm.avail_out = [decompressed length] - strm.total_out;
            
            // Inflate another chunk.
            status = inflate (&strm, Z_SYNC_FLUSH);
            if (status == Z_STREAM_END) done = YES;
            else if (status != Z_OK) break;
        }
        if (inflateEnd (&strm) != Z_OK) return nil;
        
        // Set real length.
        if (done)
        {
            [decompressed setLength: strm.total_out];
            return [NSData dataWithData: decompressed];
        }
        else return nil;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

+ (NSData *)gzipDeflate:(NSData*)data
{
    @try {
        if ([data length] == 0) return data;
        
        z_stream strm;
        
        strm.zalloc = Z_NULL;
        strm.zfree = Z_NULL;
        strm.opaque = Z_NULL;
        strm.total_out = 0;
        strm.next_in=(Bytef *)[data bytes];
        strm.avail_in = [data length];
        
        // Compresssion Levels:
        //   Z_NO_COMPRESSION
        //   Z_BEST_SPEED
        //   Z_BEST_COMPRESSION
        //   Z_DEFAULT_COMPRESSION
        
        if (deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY) != Z_OK) return nil;
        
        NSMutableData *compressed = [NSMutableData dataWithLength:16384];  // 16K chunks for expansion
        
        do {
            
            if (strm.total_out >= [compressed length])
                [compressed increaseLengthBy: 16384];
            
            strm.next_out = [compressed mutableBytes] + strm.total_out;
            strm.avail_out = [compressed length] - strm.total_out;
            
            deflate(&strm, Z_FINISH);
            
        } while (strm.avail_out == 0);
        
        deflateEnd(&strm);
        
        [compressed setLength: strm.total_out];
        return [NSData dataWithData:compressed];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
