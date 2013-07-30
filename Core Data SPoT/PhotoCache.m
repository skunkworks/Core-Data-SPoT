//
//  PhotoCache.m
//  Fast SPoT
//
//  Created by Richard Shin on 7/20/13.
//  Copyright (c) 2013 Richard Shin. All rights reserved.
//

#import "PhotoCache.h"
#import "CachedPhoto.h"

@interface PhotoCache ()
@property (strong, nonatomic) NSURL *dirURL; // URL to our cache directory
@property (strong, nonatomic) NSMutableDictionary *files; // (NSString *) keys and (CachedPhoto *) values
@property (strong, nonatomic) NSFileManager *fileManager;
@end

@implementation PhotoCache

// Singleton implementation
+ (PhotoCache *)sharedInstance
{
    static PhotoCache *sharedInstance;
    
    @synchronized(self) {
        if (!sharedInstance) {
            sharedInstance = [[PhotoCache alloc] init];
        }
        return sharedInstance;
    }
}

#define CACHE_CAPACITY_KEY @"PhotoCache_Capacity"
#define CACHE_CAPACITY_DEFAULT 5

@synthesize capacity = _capacity;

- (NSUInteger)capacity {
    if (_capacity == 0) {
        // Retrieve capacity from user defaults. If it doesn't exist, use default
        NSNumber *num = [[NSUserDefaults standardUserDefaults] valueForKey:CACHE_CAPACITY_KEY];
        if ([num intValue]) _capacity = [num intValue];
        else _capacity = CACHE_CAPACITY_DEFAULT;
    }
    return _capacity;
}

- (void)setCapacity:(NSUInteger)capacity {
    if (capacity > 0) {
        _capacity = capacity;
        // Store the capacity to user defaults so that this setting persists
        [[NSUserDefaults standardUserDefaults] setValue:@(_capacity) forKey:CACHE_CAPACITY_KEY];
    }
    while ([self.files count] > _capacity) {
        [self purgeLeastRecentlyUsed];
    }
}

// Default initializer
- (id)init
{
    self = [super init];
    
    if (self)
    {
        BOOL success = NO;
        NSError *error = nil;
        
        // Initialize file manager and build the URL to cache dir
        self.fileManager = [[NSFileManager alloc] init];
        
        NSArray *urls = [self.fileManager URLsForDirectory:NSCachesDirectory inDomains: NSUserDomainMask];
        if ([urls count]) {
            self.dirURL = [urls[0] URLByAppendingPathComponent:@"FastSPoTCache"];
            
            success = [self.fileManager createDirectoryAtURL:self.dirURL
                                 withIntermediateDirectories:YES
                                                  attributes:nil
                                                       error:&error];
        }
        
        if (success) {
            self.files = [[NSMutableDictionary alloc] init];
            
            // Build our list of cached files by querying the directory
            NSArray *urls = [self.fileManager contentsOfDirectoryAtURL:self.dirURL
                                            includingPropertiesForKeys:@[NSURLNameKey, NSURLContentAccessDateKey]
                                                               options:0
                                                                 error:nil];
            if ([urls count]) {
                for (NSURL *url in urls) {
                    NSDictionary *resourceValuesDictionary = [url resourceValuesForKeys:@[NSURLNameKey, NSURLContentAccessDateKey] error:nil];
                    CachedPhoto *cp = [[CachedPhoto alloc] init];
                    cp.fileName = resourceValuesDictionary[NSURLNameKey];
                    cp.lastAccessed = resourceValuesDictionary[NSURLContentAccessDateKey];
                    self.files[cp.fileName] = cp;
                }
            }
        } else {
            NSLog(@"Couldn't create dir for URL %@\nError: %@", _dirURL, error);
            self = nil;
        }
    }
    
    return self;
}

// Adds photo to cache
- (void)addPhoto:(UIImage *)photo fromURL:(NSURL *)url
{
    if (photo && url) {
        NSString *fileName = [[self class] getFileNameForURL:url];

        // Write file to cache dir
        NSURL *cachedPhotoURL = [self.dirURL URLByAppendingPathComponent:fileName];
        
        NSData *photoData = UIImagePNGRepresentation(photo);
        [self.fileManager createFileAtPath:cachedPhotoURL.path contents:photoData attributes:nil];
        
        // Update our cache data structure
        CachedPhoto *cp = [[CachedPhoto alloc] init];
        cp.fileName = fileName;
        cp.lastAccessed = [NSDate date];
        self.files[fileName] = cp;
        [cachedPhotoURL setResourceValue:cp.lastAccessed forKey:NSURLContentAccessDateKey error:nil];
        
        while ([self.files count] > self.capacity) {
            [self purgeLeastRecentlyUsed];
        }
    }
}

// Retrieves a photo from cache. Returns nil if not in cache
- (UIImage *)retrievePhotoForURL:(NSURL *)url
{
    UIImage *image = nil;
    
    NSString *fileName = [[self class] getFileNameForURL:url];
    NSDictionary *attributes = self.files[fileName];
    if (attributes) {
        // Read file from cache dir
        NSURL *cachedPhotoURL = [self.dirURL URLByAppendingPathComponent:fileName];
        image = [[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:cachedPhotoURL]];

        // Need to check whether we successfully retrieved image. Cache dir that we're using has no guarantee of length
        // of life of files. Even if it misses, we will keep the cache entry with no valid cached image data around until
        // it eventually gets pushed off in purgeLeastRecentlyUsed
        if (image) {
            // Update file attribute to reflect recent usage
            NSDate *lastAccessed = [NSDate date];
            [cachedPhotoURL setResourceValue:lastAccessed forKey:NSURLContentAccessDateKey error:nil];
            ((CachedPhoto *)self.files[fileName]).lastAccessed = lastAccessed;
        }
    }
    
    return image;
}

// Deletes least recently used photo
- (void)purgeLeastRecentlyUsed
{
    id LRUKey = nil;

    NSDate *earliest = [NSDate date];
    for (id key in [self.files allKeys]) {
        NSDate *accessDate = ((CachedPhoto *)self.files[key]).lastAccessed;
        if ([accessDate compare:earliest] == NSOrderedAscending) {
            earliest = accessDate;
            LRUKey = key;
        }
    }
    
    NSURL *cachedPhotoURL = [self.dirURL URLByAppendingPathComponent:LRUKey];
    [self.files removeObjectForKey:LRUKey];
    [self.fileManager removeItemAtURL:cachedPhotoURL error:nil];
}

// Clear cache
- (void)clear
{
    [self.fileManager removeItemAtURL:self.dirURL error:nil];
    [self.files removeAllObjects];
}

// Attempts to generate unique-ish file names from remote URLs
+ (NSString *)getFileNameForURL:(NSURL *)url {
    return [NSString stringWithFormat:@"%d", [url.absoluteString hash]];
}

@end
